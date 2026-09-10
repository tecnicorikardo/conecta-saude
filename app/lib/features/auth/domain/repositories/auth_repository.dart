import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Autentica com email e senha via Firebase Auth.
  /// Após o login, valida o token no backend e retorna o UserEntity.
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Realiza o auto-cadastro de um novo colaborador público do SUS.
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
  });

  /// Envia e-mail de recuperação de senha via Firebase Auth.
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  });

  /// Faz logout e limpa o estado local.
  Future<Either<Failure, void>> signOut();

  /// Retorna o usuário autenticado atual, se houver.
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Stream do estado de autenticação.
  Stream<UserEntity?> get authStateChanges;
}
