import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/http_service.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/repositories/employees_repository_impl.dart';
import '../../domain/repositories/employees_repository.dart';

final employeesRepositoryProvider = Provider<EmployeesRepository>((ref) {
  final httpService = ref.watch(httpServiceProvider);
  return EmployeesRepositoryImpl(httpService);
});

class EmployeesState extends Equatable {
  final List<UserEntity> users;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int page;
  final bool hasMore;
  final String searchQuery;
  final String? selectedSetorId;
  final int? selectedHierarquia;
  final bool? selectedAtivo;
  final UserEntity? currentUser;

  const EmployeesState({
    this.users = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.page = 1,
    this.hasMore = true,
    this.searchQuery = '',
    this.selectedSetorId,
    this.selectedHierarquia,
    this.selectedAtivo,
    this.currentUser,
  });

  bool get isDirecao => currentUser?.isDirecao ?? false;

  /// Retorna os usuários filtrados respeitando a regra institucional:
  /// Não-direção só vê colegas do mesmo centro e Direção Geral.
  List<UserEntity> get visibleUsers {
    if (isDirecao || currentUser == null) return users;

    final mySetorId = currentUser!.setorId;
    final mySetorNome = currentUser!.setorNome.toUpperCase();

    return users.where((u) {
      // Direção Geral é visível para todos
      if (u.isDirecao || u.hierarquiaNivel == 1) return true;

      // Mesmo setor / centro
      if (mySetorId.isNotEmpty && u.setorId == mySetorId) return true;

      if (mySetorNome.contains('CCD') && u.setorNome.toUpperCase().contains('CCD')) return true;
      if (mySetorNome.contains('CCO') && u.setorNome.toUpperCase().contains('CCO')) return true;
      if (mySetorNome.contains('CCE') && u.setorNome.toUpperCase().contains('CCE')) return true;

      return false;
    }).toList();
  }

  EmployeesState copyWith({
    List<UserEntity>? users,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    int? page,
    bool? hasMore,
    String? searchQuery,
    String? selectedSetorId,
    bool clearSetor = false,
    int? selectedHierarquia,
    bool clearHierarquia = false,
    bool? selectedAtivo,
    bool clearAtivo = false,
    UserEntity? currentUser,
  }) {
    return EmployeesState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSetorId: clearSetor ? null : (selectedSetorId ?? this.selectedSetorId),
      selectedHierarquia:
          clearHierarquia ? null : (selectedHierarquia ?? this.selectedHierarquia),
      selectedAtivo: clearAtivo ? null : (selectedAtivo ?? this.selectedAtivo),
      currentUser: currentUser ?? this.currentUser,
    );
  }

  @override
  List<Object?> get props => [
        users,
        isLoading,
        isLoadingMore,
        errorMessage,
        page,
        hasMore,
        searchQuery,
        selectedSetorId,
        selectedHierarquia,
        selectedAtivo,
        currentUser,
      ];
}

final employeesProvider =
    StateNotifierProvider<EmployeesNotifier, EmployeesState>((ref) {
  final repository = ref.watch(employeesRepositoryProvider);
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;
  return EmployeesNotifier(repository, user);
});

class EmployeesNotifier extends StateNotifier<EmployeesState> {
  final EmployeesRepository _repository;

  EmployeesNotifier(this._repository, UserEntity? currentUser)
      : super(EmployeesState(
          currentUser: currentUser,
          selectedSetorId: (currentUser != null && !currentUser.isDirecao)
              ? currentUser.setorId
              : null,
        )) {
    fetchEmployees();
  }

  Future<void> fetchEmployees({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(page: 1, hasMore: true);
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.listUsers(
      page: 1,
      limit: 30,
      search: state.searchQuery,
      setorId: state.selectedSetorId,
      hierarquiaNivel: state.selectedHierarquia,
      ativo: state.selectedAtivo,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (paginated) => state = state.copyWith(
        isLoading: false,
        users: paginated.items,
        page: 1,
        hasMore: paginated.hasMore,
      ),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.page + 1;

    final result = await _repository.listUsers(
      page: nextPage,
      limit: 30,
      search: state.searchQuery,
      setorId: state.selectedSetorId,
      hierarquiaNivel: state.selectedHierarquia,
      ativo: state.selectedAtivo,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoadingMore: false,
        errorMessage: failure.message,
      ),
      (paginated) => state = state.copyWith(
        isLoadingMore: false,
        users: [...state.users, ...paginated.items],
        page: nextPage,
        hasMore: paginated.hasMore,
      ),
    );
  }

  void setSearchQuery(String query) {
    if (query == state.searchQuery) return;
    state = state.copyWith(searchQuery: query);
    fetchEmployees(isRefresh: true);
  }

  void setSetorFilter(String? setorId) {
    if (!state.isDirecao) return; // Não-direção não pode trocar de setor
    state = state.copyWith(
      selectedSetorId: setorId,
      clearSetor: setorId == null,
    );
    fetchEmployees(isRefresh: true);
  }

  void setHierarquiaFilter(int? nivel) {
    state = state.copyWith(
      selectedHierarquia: nivel,
      clearHierarquia: nivel == null,
    );
    fetchEmployees(isRefresh: true);
  }

  void setAtivoFilter(bool? ativo) {
    state = state.copyWith(
      selectedAtivo: ativo,
      clearAtivo: ativo == null,
    );
    fetchEmployees(isRefresh: true);
  }

  Future<bool> updateStatus(String id, bool ativo) async {
    final result = await _repository.updateUserStatus(id: id, ativo: ativo);
    return result.fold(
      (failure) => false,
      (_) {
        final updatedUsers = state.users.map((u) {
          if (u.id == id) {
            return UserEntity(
              id: u.id,
              firebaseUid: u.firebaseUid,
              nome: u.nome,
              email: u.email,
              cargo: u.cargo,
              hierarquiaNivel: u.hierarquiaNivel,
              setorId: u.setorId,
              setorNome: u.setorNome,
              fotoUrl: u.fotoUrl,
              matricula: u.matricula,
              ativo: ativo,
              aprovadoPor: u.aprovadoPor,
              aprovadoEm: u.aprovadoEm,
              criadoEm: u.criadoEm,
            );
          }
          return u;
        }).toList();
        state = state.copyWith(users: updatedUsers);
        return true;
      },
    );
  }

  Future<UserEntity?> createUser({
    required String nome,
    required String email,
    required String password,
    required String cargo,
    required int hierarquiaNivel,
    required String setorId,
    String? fotoUrl,
  }) async {
    final result = await _repository.createUser(
      nome: nome,
      email: email,
      password: password,
      cargo: cargo,
      hierarquiaNivel: hierarquiaNivel,
      setorId: setorId,
      fotoUrl: fotoUrl,
    );
    return result.fold(
      (failure) => throw Exception(failure.message),
      (user) {
        updateOrAddUserLocally(user);
        return user;
      },
    );
  }

  Future<UserEntity?> updateUser({
    required String id,
    String? nome,
    String? cargo,
    int? hierarquiaNivel,
    String? setorId,
    String? fotoUrl,
  }) async {
    final result = await _repository.updateUser(
      id: id,
      nome: nome,
      cargo: cargo,
      hierarquiaNivel: hierarquiaNivel,
      setorId: setorId,
      fotoUrl: fotoUrl,
    );
    return result.fold(
      (failure) => throw Exception(failure.message),
      (user) {
        updateOrAddUserLocally(user);
        return user;
      },
    );
  }

  void updateOrAddUserLocally(UserEntity user) {
    final index = state.users.indexWhere((u) => u.id == user.id);
    if (index >= 0) {
      final updated = List<UserEntity>.from(state.users);
      updated[index] = user;
      state = state.copyWith(users: updated);
    } else {
      state = state.copyWith(users: [user, ...state.users]);
    }
  }
}

// ─── Provider de Aprovações Pendentes ─────────────────────────────────────────
final pendingApprovalsProvider =
    StateNotifierProvider<PendingApprovalsNotifier, AsyncValue<List<UserEntity>>>((ref) {
  final repository = ref.watch(employeesRepositoryProvider);
  return PendingApprovalsNotifier(repository, ref);
});

class PendingApprovalsNotifier extends StateNotifier<AsyncValue<List<UserEntity>>> {
  final EmployeesRepository _repository;
  final Ref _ref;

  PendingApprovalsNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    fetchPending();
  }

  Future<void> fetchPending() async {
    state = const AsyncValue.loading();
    final result = await _repository.getPendingUsers();
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (users) => state = AsyncValue.data(users),
    );
  }

  Future<bool> approve(String id) async {
    final result = await _repository.approveUser(id);
    return result.fold(
      (failure) => false,
      (approvedUser) {
        final currentList = state.valueOrNull ?? [];
        state = AsyncValue.data(currentList.where((u) => u.id != id).toList());
        // Atualiza a lista de colaboradores ativos
        _ref.read(employeesProvider.notifier).fetchEmployees(isRefresh: true);
        return true;
      },
    );
  }

  Future<bool> reject(String id) async {
    final result = await _repository.rejectUser(id);
    return result.fold(
      (failure) => false,
      (_) {
        final currentList = state.valueOrNull ?? [];
        state = AsyncValue.data(currentList.where((u) => u.id != id).toList());
        return true;
      },
    );
  }
}
