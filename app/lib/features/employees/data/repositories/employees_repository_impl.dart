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
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        final resultData = data['data'] as Map<String, dynamic>;
        final rawItems = resultData['items'] as List? ?? [];
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

      return Right(_filterFallback(page, limit, search, setorId, hierarquiaNivel, ativo));
    } catch (_) {
      return Right(_filterFallback(page, limit, search, setorId, hierarquiaNivel, ativo));
    }
  }

  static PaginatedUsers _filterFallback(
    int page,
    int limit,
    String? search,
    String? setorId,
    int? hierarquiaNivel,
    bool? ativo,
  ) {
    var list = List<UserEntity>.from(_fallbackUsers);
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((u) => u.nome.toLowerCase().contains(q) || u.cargo.toLowerCase().contains(q)).toList();
    }
    if (setorId != null && setorId.isNotEmpty) {
      list = list.where((u) => u.setorId == setorId).toList();
    }
    if (hierarquiaNivel != null) {
      list = list.where((u) => u.hierarquiaNivel == hierarquiaNivel).toList();
    }
    if (ativo != null) {
      list = list.where((u) => u.ativo == ativo).toList();
    }
    return PaginatedUsers(
      items: list,
      total: list.length,
      page: page,
      limit: limit,
      hasMore: false,
    );
  }

  static final List<UserEntity> _fallbackUsers = [
    UserEntity(
      id: 'usr-dir',
      firebaseUid: 'dev-uid-direcao-001',
      nome: 'Carlos Eduardo Mendes',
      email: 'direcao@conectasaude.dev',
      cargo: 'Diretor Geral / Admin Geral',
      hierarquiaNivel: 1,
      setorId: 'sec-direcao',
      setorNome: 'Direção Geral',
      ativo: true,
      criadoEm: DateTime.now().subtract(const Duration(days: 365)),
    ),
    UserEntity(
      id: 'usr-ccd-coord',
      firebaseUid: 'dev-uid-coord-ccdti-001',
      nome: 'Dra. Juliana Moreira',
      email: 'coord.ccdti@conectasaude.dev',
      cargo: 'Coordenadora — CCDTI',
      hierarquiaNivel: 2,
      setorId: 'sec-ccdti',
      setorNome: 'Centro Carioca de Diagnóstico e Tratamento por Imagem (CCDTI)',
      ativo: true,
      criadoEm: DateTime.now().subtract(const Duration(days: 200)),
    ),
    UserEntity(
      id: 'usr-ccd-func1',
      firebaseUid: 'dev-uid-func-ccdti-001',
      nome: 'Lucas Ribeiro',
      email: 'lucas.ccdti@conectasaude.dev',
      cargo: 'Técnico em Radiologia — CCDTI',
      hierarquiaNivel: 4,
      setorId: 'sec-ccdti',
      setorNome: 'Centro Carioca de Diagnóstico e Tratamento por Imagem (CCDTI)',
      ativo: true,
      criadoEm: DateTime.now().subtract(const Duration(days: 150)),
    ),
    UserEntity(
      id: 'usr-ccd-func2',
      firebaseUid: 'dev-uid-func-ccdti-002',
      nome: 'Mariana Lima',
      email: 'mariana.ccdti@conectasaude.dev',
      cargo: 'Enfermeira de Exames — CCDTI',
      hierarquiaNivel: 4,
      setorId: 'sec-ccdti',
      setorNome: 'Centro Carioca de Diagnóstico e Tratamento por Imagem (CCDTI)',
      ativo: true,
      criadoEm: DateTime.now().subtract(const Duration(days: 140)),
    ),
    UserEntity(
      id: 'usr-cco-coord',
      firebaseUid: 'dev-uid-coord-cco-001',
      nome: 'Dr. Roberto Vasconcelos',
      email: 'coord.cco@conectasaude.dev',
      cargo: 'Coordenador Médico — CCO',
      hierarquiaNivel: 2,
      setorId: 'sec-cco',
      setorNome: 'Centro Carioca do Olho (CCO)',
      ativo: true,
      criadoEm: DateTime.now().subtract(const Duration(days: 220)),
    ),
    UserEntity(
      id: 'usr-cco-func1',
      firebaseUid: 'dev-uid-func-cco-001',
      nome: 'Paula Souza',
      email: 'paula.cco@conectasaude.dev',
      cargo: 'Técnica Oftalmológica — CCO',
      hierarquiaNivel: 4,
      setorId: 'sec-cco',
      setorNome: 'Centro Carioca do Olho (CCO)',
      ativo: true,
      criadoEm: DateTime.now().subtract(const Duration(days: 120)),
    ),
    UserEntity(
      id: 'usr-cco-func2',
      firebaseUid: 'dev-uid-func-cco-002',
      nome: 'Thiago Duarte',
      email: 'thiago.cco@conectasaude.dev',
      cargo: 'Enfermeiro Cirúrgico — CCO',
      hierarquiaNivel: 4,
      setorId: 'sec-cco',
      setorNome: 'Centro Carioca do Olho (CCO)',
      ativo: true,
      criadoEm: DateTime.now().subtract(const Duration(days: 100)),
    ),
    UserEntity(
      id: 'usr-cce-coord',
      firebaseUid: 'dev-uid-coord-cce-001',
      nome: 'Dra. Beatriz Castro',
      email: 'coord.cce@conectasaude.dev',
      cargo: 'Coordenadora Ambulatorial — CCE',
      hierarquiaNivel: 2,
      setorId: 'sec-cce',
      setorNome: 'Centro Carioca de Especialidades (CCE)',
      ativo: true,
      criadoEm: DateTime.now().subtract(const Duration(days: 180)),
    ),
    UserEntity(
      id: 'usr-cce-func1',
      firebaseUid: 'dev-uid-func-cce-001',
      nome: 'Gabriel Mendes',
      email: 'gabriel.cce@conectasaude.dev',
      cargo: 'Assistente de Regulação — CCE',
      hierarquiaNivel: 4,
      setorId: 'sec-cce',
      setorNome: 'Centro Carioca de Especialidades (CCE)',
      ativo: true,
      criadoEm: DateTime.now().subtract(const Duration(days: 90)),
    ),
    UserEntity(
      id: 'usr-cce-func2',
      firebaseUid: 'dev-uid-func-cce-002',
      nome: 'Larissa Nogueira',
      email: 'larissa.cce@conectasaude.dev',
      cargo: 'Técnica de Enfermagem — CCE',
      hierarquiaNivel: 4,
      setorId: 'sec-cce',
      setorNome: 'Centro Carioca de Especialidades (CCE)',
      ativo: true,
      criadoEm: DateTime.now().subtract(const Duration(days: 80)),
    ),
  ];

  @override
  Future<Either<Failure, UserEntity>> getUser(String id) async {
    try {
      final response = await _httpService.get('/users/$id');
      final data = response.data;

      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
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
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
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
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
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

      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
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

      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
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
