import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  const AnnouncementsState({
    this.isLoading = false,
    this.announcements = const [],
    this.filter = AnnouncementFilter.todos,
    this.searchQuery = '',
    this.errorMessage,
  });

  int get unreadCount => announcements.where((a) => !a.lido).length;

  List<AnnouncementEntity> get filteredAnnouncements {
    return announcements.where((item) {
      // Filtro de busca
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchTitulo = item.titulo.toLowerCase().contains(query);
        final matchMensagem = item.mensagem.toLowerCase().contains(query);
        final matchAutor = item.criadorNome.toLowerCase().contains(query);
        if (!matchTitulo && !matchMensagem && !matchAutor) return false;
      }

      // Filtro de categoria
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
  }) {
    return AnnouncementsState(
      isLoading: isLoading ?? this.isLoading,
      announcements: announcements ?? this.announcements,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}

final announcementsRepositoryProvider =
    Provider<AnnouncementsRepository>((ref) => AnnouncementsRepositoryImpl());

class AnnouncementsNotifier extends StateNotifier<AnnouncementsState> {
  final AnnouncementsRepository _repository;

  AnnouncementsNotifier(this._repository) : super(const AnnouncementsState()) {
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
        errorMessage: 'Não foi possível carregar os comunicados.',
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
    final success = await _repository.confirmRead(id);
    if (success) {
      final updated = state.announcements.map((a) {
        if (a.id == id) {
          return a.copyWith(
            lido: true,
            lidoEm: DateTime.now(),
            totalLeituras: a.totalLeituras + (a.lido ? 0 : 1),
          );
        }
        return a;
      }).toList();
      state = state.copyWith(announcements: updated);
    }
    return success;
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
  return AnnouncementsNotifier(repo);
});
