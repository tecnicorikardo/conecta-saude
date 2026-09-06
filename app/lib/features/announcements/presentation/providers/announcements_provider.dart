import 'dart:async';
import 'package:flutter/foundation.dart';
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

  int get unreadCount => announcements.where((a) => !a.lido).length;

  List<AnnouncementEntity> get filteredAnnouncements {
    return announcements.where((item) {
      // 1. Filtro de busca (título, mensagem ou nome do autor)
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchTitulo = item.titulo.toLowerCase().contains(q);
        final matchMsg = item.mensagem.toLowerCase().contains(q);
        final matchCriador = item.criadorNome.toLowerCase().contains(q);
        if (!matchTitulo && !matchMsg && !matchCriador) return false;
      }

      // 2. Filtro por categoria (Todos / Não Lidos / Urgentes)
      switch (filter) {
        case AnnouncementFilter.todos:
          return true;
        case AnnouncementFilter.naoLidos:
          return !item.lido;
        case AnnouncementFilter.urgentes:
          return item.prioridade == AnnouncementPriority.urgente;
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

class AnnouncementsNotifier extends StateNotifier<AnnouncementsState> {
  final AnnouncementsRepository _repository;
  Timer? _pollingTimer;

  AnnouncementsNotifier(this._repository, UserEntity? currentUser)
      : super(AnnouncementsState(currentUser: currentUser)) {
    loadAnnouncements();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _pollAnnouncements();
    });
  }

  Future<void> _pollAnnouncements() async {
    try {
      final list = await _repository.getAnnouncements();
      if (!listEquals(state.announcements, list)) {
        state = state.copyWith(announcements: list);
      }
    } catch (_) {
      // Ignora falhas temporárias
    }
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

  Future<AnnouncementStatsEntity> fetchAnnouncementReaders(String id) async {
    return await _repository.getAnnouncementReaders(id);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final announcementsProvider =
    StateNotifierProvider<AnnouncementsNotifier, AnnouncementsState>((ref) {
  final repo = ref.watch(announcementsRepositoryProvider);
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;
  return AnnouncementsNotifier(repo, user);
});
