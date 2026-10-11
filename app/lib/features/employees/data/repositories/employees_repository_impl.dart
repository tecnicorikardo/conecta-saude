import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/http_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/paginated_users.dart';
import '../../domain/repositories/employees_repository.dart';

class EmployeesRepositoryImpl implements EmployeesRepository {
  final HttpService _httpService;

  EmployeesRepositoryImpl(this._httpService);

  @override
  Future<Either<Failure, PaginatedUsers>> listUsers({
    int page = 1,
    int limit = 30,
    String? search,
    String? setorId,
    int? hierarquiaNivel,
    bool? ativo,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (setorId != null && setorId.isNotEmpty) 'setorId': setorId,
        if (hierarquiaNivel != null) 'hierarquiaNivel': hierarquiaNivel,
        if (ativo != null) 'ativo': ativo.toString(),
      };

      final response = await _httpService.get(
        '/users',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['data'] is Map<String, dynamic>) {
        final resultData = data['data'] as Map<String, dynamic>;
        if (resultData['items'] is! List) {
          return const Left(ServerFailure('Formato de resposta inválido.'));
        }
        final rawItems = resultData['items'] as List;
        final items = rawItems
            .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
            .toList();

        return Right(
          PaginatedUsers(
            items: items,
            total: (resultData['total'] as num?)?.toInt() ?? items.length,
            page: (resultData['page'] as num?)?.toInt() ?? page,
            limit: (resultData['limit'] as num?)?.toInt() ?? limit,
            hasMore: resultData['hasMore'] as bool? ?? false,
          ),
        );
      }

      return const Left(ServerFailure('Formato de resposta inválido.'));
    } on Failure catch (failure) {
      return Left(failure);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401) {
        return const Left(
            AuthFailure('Sessão expirada. Faça login novamente.'));
      }
      if (status == 403) return const Left(UnauthorizedFailure());
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return const Left(NetworkFailure(
            'Não foi possível consultar os colaboradores. Verifique sua conexão e tente novamente.'));
      }
      return Left(ServerFailure(
          'Não foi possível consultar os colaboradores. Tente novamente.',
          statusCode: status));
    } catch (_) {
      return const Left(ServerFailure(
          'Não foi possível consultar os colaboradores. Tente novamente.'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getUser(String id) async {
    try {
      final response = await _httpService.get('/users/$id');
      final data = response.data;

      if (data is Map<String, dynamic> &&
          data['data'] is Map<String, dynamic>) {
        final user = UserModel.fromJson(data['data'] as Map<String, dynamic>);
        return Right(user);
      }

      return const Left(ServerFailure('Formato de resposta inválido.'));
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> createUser({
    required String nome,
    required String email,
    required String password,
    required String cargo,
    required int hierarquiaNivel,
    required String setorId,
    String? fotoUrl,
  }) async {
    try {
      final response = await _httpService.post(
        '/users',
        data: {
          'nome': nome,
          'email': email,
          'password': password,
          'cargo': cargo,
          'hierarquiaNivel': hierarquiaNivel,
          'setorId': setorId,
          if (fotoUrl != null && fotoUrl.isNotEmpty) 'fotoUrl': fotoUrl,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['data'] is Map<String, dynamic>) {
        final user = UserModel.fromJson(data['data'] as Map<String, dynamic>);
        return Right(user);
      }

      return const Left(ServerFailure('Formato de resposta inválido.'));
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateUser({
    required String id,
    String? nome,
    String? cargo,
    int? hierarquiaNivel,
    String? setorId,
    String? fotoUrl,
  }) async {
    try {
      final response = await _httpService.put(
        '/users/$id',
        data: {
          if (nome != null) 'nome': nome,
          if (cargo != null) 'cargo': cargo,
          if (hierarquiaNivel != null) 'hierarquiaNivel': hierarquiaNivel,
          if (setorId != null) 'setorId': setorId,
          if (fotoUrl != null) 'fotoUrl': fotoUrl,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['data'] is Map<String, dynamic>) {
        final user = UserModel.fromJson(data['data'] as Map<String, dynamic>);
        return Right(user);
      }

      return const Left(ServerFailure('Formato de resposta inválido.'));
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserStatus({
    required String id,
    required bool ativo,
  }) async {
    try {
      await _httpService.patch(
        '/users/$id/status',
        data: {'ativo': ativo},
      );
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getPendingUsers() async {
    try {
      final response = await _httpService.get('/users/pending');
      final data = response.data;

      if (data is Map<String, dynamic> &&
          data['data'] is Map<String, dynamic>) {
        final resultData = data['data'] as Map<String, dynamic>;
        final rawItems = resultData['items'] as List? ?? [];
        final items = rawItems
            .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
            .toList();
        return Right(items);
      }

      return const Right([]);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> approveUser(String id) async {
    try {
      final response = await _httpService.patch('/users/$id/approve');
      final data = response.data;

      if (data is Map<String, dynamic> &&
          data['data'] is Map<String, dynamic>) {
        final user = UserModel.fromJson(data['data'] as Map<String, dynamic>);
        return Right(user);
      }

      return const Left(ServerFailure('Formato de resposta inválido.'));
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rejectUser(String id) async {
    try {
      await _httpService.delete('/users/$id/reject');
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
