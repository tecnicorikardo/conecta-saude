import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/firebase_options.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/http_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl([Ref? _]);

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static const String _userCacheKey = 'conecta_cached_user_session';

  Future<void> _saveCachedUser(UserEntity user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userCacheKey, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<UserEntity?> _getCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_userCacheKey);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return UserEntity.fromJson(map);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _clearCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userCacheKey);
    } catch (_) {}
  }

  Dio _buildDio([String? token, Duration timeout = const Duration(seconds: 30)]) {
    return Dio(
      BaseOptions(
        baseUrl: kApiBaseUrl,
        connectTimeout: timeout,
        receiveTimeout: timeout,
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
      // 1. Firebase Auth (validação direta e imediata)
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

      // 3. Tentar obter FCM token sem bloquear o fluxo de login
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance
            .getToken(vapidKey: kIsWeb ? kFirebaseWebVapidKey : null)
            .timeout(const Duration(milliseconds: 1000));
        debugPrint('[FCM] Token capturado no login: ${fcmToken != null ? '${fcmToken.substring(0, 15)}...' : 'null'}');
      } catch (e) {
        debugPrint('[FCM] Token FCM ignorado no login rápido (NotificationService sincronizará em background)');
      }

      // 4. Chamar backend para validar e obter dados reais do banco
      // Permite a inicialização da instância gratuita; acesso depende da validação do servidor.
      try {
        final response = await _buildDio(null, const Duration(seconds: 75)).post(
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
            await _clearCachedUser();
            await _firebaseAuth.signOut();
            return const Left(UserInactiveFailure(
              'Cadastro em análise. Seu acesso está aguardando aprovação pelo RH ou Coordenação da unidade.',
            ));
          }
          await _saveCachedUser(entity);
          return Right(entity);
        }
        return const Left(AuthFailure('Não foi possível confirmar seu acesso no servidor. Tente novamente.'));
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;

        // Uma conta inativa não pode iniciar a sessão institucional.
        if (statusCode == 403) {
          await _clearCachedUser();
          await _firebaseAuth.signOut();
          final msg = e.response?.data?['message'] as String? ??
              e.response?.data?['error'] as String? ??
              'Cadastro em análise. Seu acesso está aguardando aprovação pelo RH ou Coordenação da unidade.';
          return Left(UserInactiveFailure(msg));
        }

        // Firebase valida a identidade; o backend confirma cargo, hospital e aprovação.
        return const Left(AuthFailure('Não foi possível confirmar seu acesso no servidor. Tente novamente.'));
      } catch (e) {
        // Falha de sincronização não concede um perfil local.
        return const Left(AuthFailure('Não foi possível confirmar seu acesso no servidor. Tente novamente.'));
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
    String? unitId,
    String? matricula,
    String? jornadaInicio,
    String? jornadaFim,
    String? jornadaDias,
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
          if (unitId != null && unitId.trim().isNotEmpty) 'unitId': unitId.trim(),
          if (matricula != null && matricula.trim().isNotEmpty)
            'matricula': matricula.trim(),
          if (jornadaInicio != null && jornadaInicio.trim().isNotEmpty)
            'jornadaInicio': jornadaInicio.trim(),
          if (jornadaFim != null && jornadaFim.trim().isNotEmpty)
            'jornadaFim': jornadaFim.trim(),
          if (jornadaDias != null && jornadaDias.trim().isNotEmpty)
            'jornadaDias': jornadaDias.trim(),
        },
      );

      // Deslogar de qualquer sessão temporária pós-criação
      await _clearCachedUser();
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

      await _clearCachedUser();
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
      if (firebaseUser == null) {
        await _clearCachedUser();
        return const Right(null);
      }

      final cachedUser = await _getCachedUser();

      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        if (cachedUser != null) return Right(cachedUser);
        return const Left(AuthFailure('Não foi possível confirmar seu acesso no servidor. Tente novamente.'));
      }

      try {
        final response = await _buildDio(idToken, const Duration(seconds: 25)).get('/me');
        if (response.data['success'] == true) {
          final data = response.data['data'] as Map<String, dynamic>;
          final entity = _mapToEntity(data);
          if (!entity.ativo) {
            await _clearCachedUser();
            await _firebaseAuth.signOut();
            return const Right(null);
          }
          await _saveCachedUser(entity);
          return Right(entity);
        }
        if (cachedUser != null) return Right(cachedUser);
        return const Left(AuthFailure('Não foi possível confirmar seu acesso no servidor. Tente novamente.'));
      } catch (e) {
        if (e is DioException &&
            (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
          await _clearCachedUser();
          await _firebaseAuth.signOut();
          return const Right(null);
        }
        // Em caso de falha de conexão / timeout (offline ou cold-start do Render):
        // Retorna o perfil em cache para manter a sessão ativa sem travar o usuário!
        if (cachedUser != null) {
          return Right(cachedUser);
        }
        return const Left(AuthFailure('Não foi possível confirmar seu acesso no servidor. Tente novamente.'));
      }
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        await _clearCachedUser();
        return null;
      }

      final cachedUser = await _getCachedUser();

      try {
        final idToken = await firebaseUser.getIdToken();
        if (idToken == null) return cachedUser;

        final response = await _buildDio(idToken, const Duration(seconds: 20)).get('/me');
        if (response.data['success'] == true) {
          final data = response.data['data'] as Map<String, dynamic>;
          final entity = _mapToEntity(data);
          if (!entity.ativo) {
            await _clearCachedUser();
            await _firebaseAuth.signOut();
            return null;
          }
          await _saveCachedUser(entity);
          return entity;
        }
        return cachedUser;
      } catch (e) {
        if (e is DioException &&
            (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
          await _clearCachedUser();
          await _firebaseAuth.signOut();
          return null;
        }
        // Se a internet caiu ou Render demorou no cold start:
        // Mantém o usuário logado com os dados locais em cache!
        if (cachedUser != null) {
          debugPrint('[Auth] Rede temporariamente indisponível. Mantendo sessão com cache local.');
          return cachedUser;
        }
        // Fallback para não forçar logout por oscilação de rede
        return UserEntity(
          id: firebaseUser.uid,
          firebaseUid: firebaseUser.uid,
          nome: firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? 'Usuário',
          email: firebaseUser.email ?? '',
          cargo: 'Colaborador',
          hierarquiaNivel: 4,
          setorId: '',
          setorNome: 'Geral',
          ativo: true,
          criadoEm: DateTime.now(),
        );
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
      unitId: data['unitId'] as String?,
      unitNome: data['unitNome'] as String?,
      unitSigla: data['unitSigla'] as String?,
      fotoUrl: data['fotoUrl'] as String?,
      matricula: data['matricula'] as String?,
      jornadaInicio: data['jornadaInicio'] as String? ?? '07:00',
      jornadaFim: data['jornadaFim'] as String? ?? '16:00',
      jornadaDias: data['jornadaDias'] as String? ?? 'seg,ter,qua,qui,sex',
      emPlantaoExtra: data['emPlantaoExtra'] as bool? ?? false,
      silenciarForaJornada: data['silenciarForaJornada'] as bool? ?? true,
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
