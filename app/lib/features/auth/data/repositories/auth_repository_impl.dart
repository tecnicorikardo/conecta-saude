import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/firebase_options.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/http_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';


class AuthRepositoryImpl implements AuthRepository {
  final Ref? _ref;
  AuthRepositoryImpl([this._ref]);

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Dio _buildDio([String? token]) {
    return Dio(
      BaseOptions(
        baseUrl: kApiBaseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 15),
        headers: token != null
            ? {'Authorization': 'Bearer $token'}
            : {},
      ),
    );
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Firebase Auth
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return const Left(AuthFailure('Falha na autenticação.'));
      }

      // 2. Forçar refresh do token para garantir que é válido
      final idToken = await firebaseUser.getIdToken(true);
      if (idToken == null) {
        return const Left(AuthFailure('Não foi possível obter o token.'));
      }

      // 3. Tentar obter FCM token para notificações push
      // vapidKey é OBRIGATÓRIA para Web Push — sem ela getToken() retorna null
      String? fcmToken;
      try {
        if (kIsWeb) {
          fcmToken = await FirebaseMessaging.instance
              .getToken(vapidKey: kFirebaseWebVapidKey)
              .timeout(const Duration(seconds: 8));
        } else {
          fcmToken = await FirebaseMessaging.instance
              .getToken()
              .timeout(const Duration(seconds: 8));
        }
        debugPrint('[FCM] Token no login: ${fcmToken != null ? '${fcmToken.substring(0, 20)}...' : 'null'}');
      } catch (e) {
        debugPrint('[FCM] Não foi possível obter token no login: $e');
      }

      // 4. Chamar backend para validar e obter dados reais do banco
      try {
        final response = await _buildDio().post(
          '/auth/verify',
          data: {
            'idToken': idToken,
            if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
          },
        );

        if (response.data['success'] == true) {
          final data = response.data['data'] as Map<String, dynamic>;
          final entity = _mapToEntity(data);
          if (!entity.ativo) {
            await _firebaseAuth.signOut();
            return const Left(UserInactiveFailure(
              'Cadastro em análise. Seu acesso está aguardando aprovação pelo RH ou Coordenação da unidade.',
            ));
          }
          return Right(entity);
        }
        await _firebaseAuth.signOut();
        return const Left(AuthFailure('Resposta inválida do servidor.'));
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        await _firebaseAuth.signOut();

        if (statusCode == 403) {
          final msg = e.response?.data?['message'] as String? ??
              e.response?.data?['error'] as String? ??
              'Cadastro em análise. Seu acesso está aguardando aprovação pelo RH ou Coordenação da unidade.';
          return Left(UserInactiveFailure(msg));
        }
        if (statusCode == 404) {
          return const Left(UserNotFoundFailure());
        }

        return const Left(AuthFailure('Falha na autenticação institucional.'));
      }
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseError(e.code)));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> register({
    required String nome,
    required String email,
    required String password,
    required String cargo,
    required String setorId,
    String? matricula,
  }) async {
    try {
      final response = await _buildDio().post(
        '/auth/register',
        data: {
          'nome': nome.trim(),
          'email': email.trim(),
          'password': password,
          'cargo': cargo.trim(),
          'setorId': setorId,
          if (matricula != null && matricula.trim().isNotEmpty)
            'matricula': matricula.trim(),
        },
      );

      // Deslogar de qualquer sessão temporária pós-criação
      await _firebaseAuth.signOut();

      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        return Right(data);
      }
      return Left(ServerFailure(data['message'] as String? ?? 'Falha no cadastro.'));
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ??
          'Erro ao processar o cadastro no servidor.';
      return Left(ServerFailure(msg));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseError(e.code)));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      try {
        final idToken = await _firebaseAuth.currentUser?.getIdToken();
        if (idToken != null) {
          await _buildDio(idToken).patch('/auth/fcm-token', data: {'fcmToken': null});
        }
        await FirebaseMessaging.instance.deleteToken();
      } catch (_) {}

      await _firebaseAuth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return const Right(null);

      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) return const Right(null);

      try {
        final response = await _buildDio(idToken).get('/me');
        if (response.data['success'] == true) {
          final data = response.data['data'] as Map<String, dynamic>;
          final entity = _mapToEntity(data);
          if (!entity.ativo) {
            await _firebaseAuth.signOut();
            return const Right(null);
          }
          return Right(entity);
        }
        await _firebaseAuth.signOut();
        return const Right(null);
      } catch (_) {
        await _firebaseAuth.signOut();
        return const Right(null);
      }
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        final idToken = await firebaseUser.getIdToken();
        if (idToken == null) return null;

        final response = await _buildDio(idToken).get('/me');
        if (response.data['success'] == true) {
          final data = response.data['data'] as Map<String, dynamic>;
          final entity = _mapToEntity(data);
          if (!entity.ativo) {
            await _firebaseAuth.signOut();
            return null;
          }
          return entity;
        }
        await _firebaseAuth.signOut();
        return null;
      } catch (_) {
        await _firebaseAuth.signOut();
        return null;
      }
    });
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  UserEntity _mapToEntity(Map<String, dynamic> data) {
    return UserEntity(
      id: data['id'] as String? ?? '',
      firebaseUid: data['firebaseUid'] as String? ?? '',
      nome: data['nome'] as String? ?? 'Usuário',
      email: data['email'] as String? ?? '',
      cargo: data['cargo'] as String? ?? 'Funcionário',
      hierarquiaNivel: data['hierarquiaNivel'] as int? ?? 4,
      setorId: data['setorId'] as String? ?? '',
      setorNome: data['setorNome'] as String? ?? '',
      fotoUrl: data['fotoUrl'] as String?,
      matricula: data['matricula'] as String?,
      ativo: data['ativo'] as bool? ?? true,
      aprovadoPor: data['aprovadoPor'] as String?,
      aprovadoEm: data['aprovadoEm'] != null
          ? DateTime.tryParse(data['aprovadoEm'] as String? ?? '')?.toLocal()
          : null,
      criadoEm: DateTime.tryParse(data['criadoEm'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'E-mail não encontrado no sistema.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Acesso desativado. Entre em contato com o RH.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      default:
        return 'Erro de autenticação. Tente novamente.';
    }
  }
}
