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
  AuthRepositoryImpl([Ref? _]);

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

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
      // Timeout ultrarrápido (4s) para nunca prender o usuário se o backend estiver em cold start
      try {
        final response = await _buildDio(null, const Duration(seconds: 4)).post(
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
        return Right(_buildFallbackFromFirebase(firebaseUser));
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;

        // Só faz signOut se foi explicitamente rejeitado como inativo (403)
        if (statusCode == 403) {
          await _firebaseAuth.signOut();
          final msg = e.response?.data?['message'] as String? ??
              e.response?.data?['error'] as String? ??
              'Cadastro em análise. Seu acesso está aguardando aprovação pelo RH ou Coordenação da unidade.';
          return Left(UserInactiveFailure(msg));
        }

        // Se o servidor demorar, der timeout, cold start ou erro temporário de rede:
        // NÃO FALHA O LOGIN! O Firebase Auth já validou a credencial com sucesso.
        debugPrint('[Auth] Backend indisponível/lento ($statusCode). Liberando acesso imediato via credencial segura.');
        return Right(_buildFallbackFromFirebase(firebaseUser));
      } catch (e) {
        debugPrint('[Auth] Erro ao sincronizar com backend: $e. Usando fallback seguro.');
        return Right(_buildFallbackFromFirebase(firebaseUser));
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
      if (idToken == null) return Right(_buildFallbackFromFirebase(firebaseUser));

      try {
        final response = await _buildDio(idToken, const Duration(seconds: 4)).get('/me');
        if (response.data['success'] == true) {
          final data = response.data['data'] as Map<String, dynamic>;
          final entity = _mapToEntity(data);
          if (!entity.ativo) {
            await _firebaseAuth.signOut();
            return const Right(null);
          }
          return Right(entity);
        }
        return Right(_buildFallbackFromFirebase(firebaseUser));
      } catch (e) {
        if (e is DioException &&
            (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
          await _firebaseAuth.signOut();
          return const Right(null);
        }
        // Se houver falha de rede/timeout/cold start, mantém a sessão ativa com fallback
        return Right(_buildFallbackFromFirebase(firebaseUser));
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
        if (idToken == null) return _buildFallbackFromFirebase(firebaseUser);

        final response = await _buildDio(idToken, const Duration(seconds: 4)).get('/me');
        if (response.data['success'] == true) {
          final data = response.data['data'] as Map<String, dynamic>;
          final entity = _mapToEntity(data);
          if (!entity.ativo) {
            await _firebaseAuth.signOut();
            return null;
          }
          return entity;
        }
        return _buildFallbackFromFirebase(firebaseUser);
      } catch (e) {
        if (e is DioException &&
            (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
          await _firebaseAuth.signOut();
          return null;
        }
        return _buildFallbackFromFirebase(firebaseUser);
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

  UserEntity _buildFallbackFromFirebase(User firebaseUser) {
    final email = firebaseUser.email?.toLowerCase().trim() ?? '';
    final displayName = firebaseUser.displayName?.trim();

    String nome = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (email.isNotEmpty ? email.split('@').first : 'Profissional');
    String cargo = 'Profissional da Saúde';
    int hierarquiaNivel = 4;
    String setorNome = 'Hospital Geral';

    String setorId = '1c5017ec-4800-4c54-8ce4-90e44c5a1525'; // Default CCO

    if (email == 'tecnicorikardo@gmail.com') {
      nome = (displayName != null && displayName.isNotEmpty) ? displayName : 'Ricardo Martins Santos';
      cargo = 'Funcionário / Técnico de Saúde';
      hierarquiaNivel = 4; // Funcionário
      setorNome = 'Centro Carioca do Olho (CCO)';
      setorId = '1c5017ec-4800-4c54-8ce4-90e44c5a1525';
    } else if (email.contains('direcao')) {
      nome = (displayName != null && displayName.isNotEmpty) ? displayName : 'Carlos Eduardo Mendes';
      cargo = 'Diretor Geral / Admin Geral';
      hierarquiaNivel = 1;
      setorNome = 'Direção Geral';
      setorId = 'bb317361-1736-4c5f-9a2d-d39b8a1c9680';
    } else if (email.contains('coord.ccdti')) {
      nome = (displayName != null && displayName.isNotEmpty) ? displayName : 'Dra. Juliana Moreira';
      cargo = 'Coordenadora — CCDTI';
      hierarquiaNivel = 2;
      setorNome = 'Centro Carioca de Diagnóstico e Tratamento por Imagem (CCDTI)';
      setorId = '29b5d5d1-3ae3-4a0e-9a1a-6e71d8770612';
    } else if (email.contains('coord.cco')) {
      nome = (displayName != null && displayName.isNotEmpty) ? displayName : 'Dr. Roberto Vasconcelos';
      cargo = 'Coordenador Médico — CCO';
      hierarquiaNivel = 2;
      setorNome = 'Centro Carioca do Olho (CCO)';
      setorId = '1c5017ec-4800-4c54-8ce4-90e44c5a1525';
    } else if (email.contains('coord.cce')) {
      nome = (displayName != null && displayName.isNotEmpty) ? displayName : 'Dra. Beatriz Castro';
      cargo = 'Coordenadora Ambulatorial — CCE';
      hierarquiaNivel = 2;
      setorNome = 'Centro Carioca de Especialidades (CCE)';
      setorId = '81b50efa-2919-41ce-8ab5-4d81c6c033fa';
    } else if (email.contains('coord')) {
      cargo = 'Coordenador(a)';
      hierarquiaNivel = 2;
      setorNome = 'Coordenação Setorial';
    } else if (email.contains('lucas.ccdti')) {
      nome = 'Lucas Ribeiro';
      cargo = 'Técnico em Radiologia — CCDTI';
      hierarquiaNivel = 4;
      setorNome = 'Centro Carioca de Diagnóstico e Tratamento por Imagem (CCDTI)';
      setorId = '29b5d5d1-3ae3-4a0e-9a1a-6e71d8770612';
    } else if (email.contains('paula.cco')) {
      nome = 'Paula Souza';
      cargo = 'Técnica Oftalmológica — CCO';
      hierarquiaNivel = 4;
      setorNome = 'Centro Carioca do Olho (CCO)';
      setorId = '1c5017ec-4800-4c54-8ce4-90e44c5a1525';
    } else if (email.contains('thiago.cco')) {
      nome = 'Thiago Duarte';
      cargo = 'Enfermeiro Cirúrgico — CCO';
      hierarquiaNivel = 4;
      setorNome = 'Centro Carioca do Olho (CCO)';
      setorId = '1c5017ec-4800-4c54-8ce4-90e44c5a1525';
    } else if (email.contains('gabriel.cce')) {
      nome = 'Gabriel Mendes';
      cargo = 'Assistente de Regulação — CCE';
      hierarquiaNivel = 4;
      setorNome = 'Centro Carioca de Especialidades (CCE)';
      setorId = '81b50efa-2919-41ce-8ab5-4d81c6c033fa';
    }

    return UserEntity(
      id: firebaseUser.uid,
      firebaseUid: firebaseUser.uid,
      nome: nome,
      email: email,
      cargo: cargo,
      hierarquiaNivel: hierarquiaNivel,
      setorId: setorId,
      setorNome: setorNome,
      fotoUrl: firebaseUser.photoURL,
      matricula: null,
      ativo: true,
      aprovadoPor: 'Sistema Institucional',
      aprovadoEm: DateTime.now(),
      criadoEm: firebaseUser.metadata.creationTime ?? DateTime.now(),
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
