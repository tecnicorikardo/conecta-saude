import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/paginated_users.dart';

abstract class EmployeesRepository {
  Future<Either<Failure, PaginatedUsers>> listUsers({
    int page = 1,
    int limit = 30,
    String? search,
    String? setorId,
    int? hierarquiaNivel,
    bool? ativo,
  });

  Future<Either<Failure, UserEntity>> getUser(String id);

  Future<Either<Failure, UserEntity>> createUser({
    required String nome,
    required String email,
    required String password,
    required String cargo,
    required int hierarquiaNivel,
    required String setorId,
    String? fotoUrl,
  });

  Future<Either<Failure, UserEntity>> updateUser({
    required String id,
    String? nome,
    String? cargo,
    int? hierarquiaNivel,
    String? setorId,
    String? fotoUrl,
  });

  Future<Either<Failure, void>> updateUserStatus({
    required String id,
    required bool ativo,
  });
}
