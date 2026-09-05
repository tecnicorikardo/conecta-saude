import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/repositories/announcements_repository_impl.dart';
import '../../domain/entities/announcement_entity.dart';
import '../../domain/repositories/announcements_repository.dart';

enum AnnouncementFilter { todos, naoLidos, urgentes }

class AnnouncementsState {
  final bool isLoading;
  final List<AnnouncementEntity> announcements;
  final AnnouncementFilter filter;
  final String searchQuery;
  final String? errorMessage;
  final UserEntity? currentUser;

  const AnnouncementsState({
    this.isLoading = false,
    this.announcements = const [],
    this.filter = AnnouncementFilter.todos,
    this.searchQuery = '',
    this.errorMessage,
    this.currentUser,
  });

  bool get isDirecao => currentUser?.isDirecao ?? false;

  String get userCentroTag {
    if (currentUser == null || isDirecao) return 'TODOS';
    final s = ('${currentUser!.setorNome} ${currentUser!.setorId}').toUpperCase();
    if (s.contains('CCD') || s.contains('IMAGEM')) return 'CCD';
    if (s.contains('CCO') || s.contains('OLHO')) return 'CCO';
    if (s.contains('CCE') || s.contains('ESPECIALIDADE')) return 'CCE';
    return 'TODOS';
  }

  int get unreadCount => filteredAnnouncements.where((a) => !a.lido).length;

  List<AnnouncementEntity> get filteredAnnouncements {
    final allowedCentro = userCentroTag;

    return announcements.where((item) {
      // 1. Isolamento por centro para funcionários:
      // Direção vê tudo. Funcionário vê comunicados do seu centro e da Direção Geral.
      if (!isDirecao && allowedCentro != 'TODOS') {
        final t = item.titulo.toUpperCase();
        final c = item.criadorCargo.toUpperCase();

        final isDirecaoPost = t.contains('DIREÇÃO') || c.contains('DIRETOR') || c.contains('GERAL');
        final isMyCenter = (allowedCentro == 'CCD' && (t.contains('CCD') || c.contains('CCDTI'))) ||
            (allowedCentro == 'CCO' && (t.contains('CCO') || c.contains('CCO'))) ||
            (allowedCentro == 'CCE' && (t.contains('CCE') || c.contains('CCE')));

        if (!isDirecaoPost && !isMyCenter) {
          return false;
        }
      }

      // 2. Filtro de busca
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchTitulo = item.titulo.toLowerCase().contains(query);
        final matchMensagem = item.mensagem.toLowerCase().contains(query);
        final matchAutor = item.criadorNome.toLowerCase().contains(query);
        if (!matchTitulo && !matchMensagem && !matchAutor) return false;
      }

      // 3. Filtro de categoria
      switch (filter) {
        case AnnouncementFilter.naoLidos:
          return !item.lido;
        case AnnouncementFilter.urgentes:
          return item.prioridade == AnnouncementPriority.urgente;
        case AnnouncementFilter.todos:
          return true;
      }
    }).toList();
  }

  AnnouncementsState copyWith({
    bool? isLoading,
    List<AnnouncementEntity>? announcements,
    AnnouncementFilter? filter,
    String? searchQuery,
    String? errorMessage,
    UserEntity? currentUser,
  }) {
    return AnnouncementsState(
      isLoading: isLoading ?? this.isLoading,
      announcements: announcements ?? this.announcements,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
      currentUser: currentUser ?? this.currentUser,
    );
  }
}

final announcementsRepositoryProvider =
    Provider<AnnouncementsRepository>((ref) => AnnouncementsRepositoryImpl());

class AnnouncementsNotifier extends StateNotifier<AnnouncementsState> {
  final AnnouncementsRepository _repository;

  AnnouncementsNotifier(this._repository, UserEntity? currentUser)
      : super(AnnouncementsState(currentUser: currentUser)) {
    loadAnnouncements();
  }

  Future<void> loadAnnouncements() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.getAnnouncements();
      state = state.copyWith(isLoading: false, announcements: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar comunicados.',
      );
    }
  }

  void setFilter(AnnouncementFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.trim());
  }

  Future<bool> confirmRead(String id) async {
    try {
      final success = await _repository.confirmRead(id);
      if (success) {
        final updatedList = state.announcements.map((item) {
          if (item.id == id) {
            return item.copyWith(
              lido: true,
              lidoEm: DateTime.now(),
              totalLeituras: item.totalLeituras + 1,
            );
          }
          return item;
        }).toList();
        state = state.copyWith(announcements: updatedList);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createAnnouncement({
    required String titulo,
    required String mensagem,
    required AnnouncementPriority prioridade,
  }) async {
    try {
      final created = await _repository.createAnnouncement(
        titulo: titulo,
        mensagem: mensagem,
        prioridade: prioridade,
      );
      state = state.copyWith(
        announcements: [created, ...state.announcements],
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final announcementsProvider =
    StateNotifierProvider<AnnouncementsNotifier, AnnouncementsState>((ref) {
  final repo = ref.watch(announcementsRepositoryProvider);
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;
  return AnnouncementsNotifier(repo, user);
});
