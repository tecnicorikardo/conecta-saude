import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl([Ref? _]);

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  static const _baseUrl = 'http://localhost:3000/api';

  Dio _buildDio([String? token]) {
    return Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
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

      // 3. Chamar backend para validar e obter dados reais do banco
      try {
        final response = await _buildDio().post(
          '/auth/verify',
          data: {'idToken': idToken},
        );

        if (response.data['success'] == true) {
          final data = response.data['data'] as Map<String, dynamic>;
          return Right(_mapToEntity(data));
        }
        return const Left(AuthFailure('Resposta inválida do servidor.'));
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;

        if (statusCode == 403) {
          return Left(UserInactiveFailure());
        }
        if (statusCode == 404) {
          return const Left(UserNotFoundFailure());
        }

        // Backend inacessível — logar o erro e usar fallback do Firebase
        // ignore: avoid_print
        print('[Auth] Backend inacessível: ${e.message}. Usando dados do Firebase.');
        return Right(_mapFromFirebase(firebaseUser));
      }
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseError(e.code)));
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
      if (idToken == null) return Right(_mapFromFirebase(firebaseUser));

      try {
        final response = await _buildDio(idToken).get('/me');
        if (response.data['success'] == true) {
          final data = response.data['data'] as Map<String, dynamic>;
          return Right(_mapToEntity(data));
        }
        return Right(_mapFromFirebase(firebaseUser));
      } catch (_) {
        return Right(_mapFromFirebase(firebaseUser));
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
        if (idToken == null) return _mapFromFirebase(firebaseUser);

        final response = await _buildDio(idToken).get('/me');
        if (response.data['success'] == true) {
          final data = response.data['data'] as Map<String, dynamic>;
          return _mapToEntity(data);
        }
        return _mapFromFirebase(firebaseUser);
      } catch (_) {
        return _mapFromFirebase(firebaseUser);
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
      ativo: data['ativo'] as bool? ?? true,
      criadoEm: DateTime.tryParse(data['criadoEm'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  UserEntity _mapFromFirebase(User firebaseUser) {
    return UserEntity(
      id: firebaseUser.uid,
      firebaseUid: firebaseUser.uid,
      nome: firebaseUser.displayName ?? firebaseUser.email ?? 'Usuário',
      email: firebaseUser.email ?? '',
      cargo: 'Funcionário',
      hierarquiaNivel: 4,
      setorId: '',
      setorNome: '',
      fotoUrl: firebaseUser.photoURL,
      ativo: true,
      criadoEm: DateTime.now(),
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
