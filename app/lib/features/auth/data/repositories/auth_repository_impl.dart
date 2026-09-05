import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/http_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// Implementação do AuthRepository.
/// Firebase Auth → ID Token → validação no backend Node.js.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._ref);

  final Ref _ref;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Autenticar no Firebase Auth
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return const Left(AuthFailure('Falha na autenticação.'));
      }

      // 2. Obter ID Token
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        return const Left(
          AuthFailure('Não foi possível obter o token de autenticação.'),
        );
      }

      // 3. Validar no backend Node.js (/auth/verify) e obter dados completos
      final httpService = _ref.read(httpServiceProvider);
      final response = await httpService.post(
        '/auth/verify',
        data: {'idToken': idToken},
      );

      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData['data'] is Map<String, dynamic>) {
        final userModel = UserModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
        return Right(userModel);
      }

      return const Left(ServerFailure('Resposta inválida do servidor.'));
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseAuthError(e.code)));
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(_mapFirebaseAuthError(e.code)));
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

      // Buscar perfil completo atualizado no backend
      final httpService = _ref.read(httpServiceProvider);
      final response = await httpService.get('/auth/me');

      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData['data'] is Map<String, dynamic>) {
        final userModel = UserModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
        return Right(userModel);
      }

      return const Left(ServerFailure('Resposta inválida do servidor.'));
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        final httpService = _ref.read(httpServiceProvider);
        final response = await httpService.get('/auth/me');
        final responseData = response.data;
        if (responseData is Map<String, dynamic> &&
            responseData['data'] is Map<String, dynamic>) {
          return UserModel.fromJson(
            responseData['data'] as Map<String, dynamic>,
          );
        }
      } catch (_) {
        // Fallback básico caso o backend esteja temporariamente inacessível
      }

      return UserEntity(
        id: firebaseUser.uid,
        firebaseUid: firebaseUser.uid,
        nome: firebaseUser.displayName ?? 'Usuário',
        email: firebaseUser.email ?? '',
        cargo: 'Funcionário',
        hierarquiaNivel: 4,
        setorId: '',
        setorNome: '',
        fotoUrl: firebaseUser.photoURL,
        ativo: true,
        criadoEm: DateTime.now(),
      );
    });
  }

  // ─── Mapeamento de erros Firebase ────────────────────────────────────────
  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'E-mail não encontrado no sistema.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Este acesso foi desativado. Entre em contato com o RH.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      default:
        return 'Erro de autenticação. Tente novamente.';
    }
  }
}
