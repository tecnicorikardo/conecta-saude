import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/channels_repository.dart';
import '../../domain/entities/channel_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';

enum ChannelTab {
  ccd,        // Esquerda: Centro Carioca de Diagnóstico e Tratamento por Imagem (CCDTI)
  cco,        // Meio: Centro Carioca do Olho (CCO)
  cce,        // Direita: Centro Carioca de Especialidades (CCE)
  emergencia, // Alerta e Emergência
  todos,      // Visão Geral (Admin)
}

class ChannelsState {
  final bool isLoading;
  final List<ChannelEntity> channels;
  final ChannelTab selectedTab;
  final String searchQuery;
  final String? errorMessage;
  final UserEntity? currentUser;

  const ChannelsState({
    this.isLoading = false,
    this.channels = const [],
    this.selectedTab = ChannelTab.ccd,
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

  ChannelEntity? get emergencyChannel =>
      channels.where((c) => c.isEmergencia).firstOrNull;

  List<ChannelEntity> get filteredChannels {
    final allowedCentro = userCentroTag;

    return channels.where((c) {
      // 1. Isolamento institucional estrito:
      // Se não for Direção Geral, só pode ver canais do seu centro, de emergência ou institucionais gerais
      if (!isDirecao && allowedCentro != 'TODOS') {
        final isMyCenter = c.centroTag == allowedCentro;
        final isGeneralOrEmergency = c.isEmergencia || c.centroTag == 'GERAL';
        if (!isMyCenter && !isGeneralOrEmergency) {
          return false;
        }
      }

      // 2. Busca textual
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchNome = c.nome.toLowerCase().contains(query);
        final matchDesc = (c.descricao ?? '').toLowerCase().contains(query);
        final matchSetor = (c.setorNome ?? '').toLowerCase().contains(query);
        if (!matchNome && !matchDesc && !matchSetor) return false;
      }

      // 3. Filtro por Aba Selecionada
      switch (selectedTab) {
        case ChannelTab.ccd:
          return c.centroTag == 'CCD' || (!isDirecao && c.centroTag == 'GERAL' && allowedCentro == 'CCD');
        case ChannelTab.cco:
          return c.centroTag == 'CCO' || (!isDirecao && c.centroTag == 'GERAL' && allowedCentro == 'CCO');
        case ChannelTab.cce:
          return c.centroTag == 'CCE' || (!isDirecao && c.centroTag == 'GERAL' && allowedCentro == 'CCE');
        case ChannelTab.emergencia:
          return c.isEmergencia;
        case ChannelTab.todos:
          return true;
      }
    }).toList();
  }

  ChannelsState copyWith({
    bool? isLoading,
    List<ChannelEntity>? channels,
    ChannelTab? selectedTab,
    String? searchQuery,
    String? errorMessage,
    UserEntity? currentUser,
  }) {
    return ChannelsState(
      isLoading: isLoading ?? this.isLoading,
      channels: channels ?? this.channels,
      selectedTab: selectedTab ?? this.selectedTab,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
      currentUser: currentUser ?? this.currentUser,
    );
  }
}

class ChannelsNotifier extends StateNotifier<ChannelsState> {
  final ChannelsRepository _repository;
  Timer? _pollingTimer;

  ChannelsNotifier(this._repository, UserEntity? user) : super(ChannelsState(currentUser: user)) {
    _initDefaultTab(user);
    loadChannels();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _pollChannels();
    });
  }

  Future<void> _pollChannels() async {
    try {
      final channels = await _repository.listAllChannels();
      if (!listEquals(state.channels, channels)) {
        state = state.copyWith(channels: channels);
      }
    } catch (_) {
      // Ignora falhas temporárias de polling
    }
  }

  void _initDefaultTab(UserEntity? user) {
    if (user != null && !user.isDirecao) {
      final s = ('${user.setorNome} ${user.setorId}').toUpperCase();
      if (s.contains('CCO') || s.contains('OLHO')) {
        state = state.copyWith(selectedTab: ChannelTab.cco);
      } else if (s.contains('CCE') || s.contains('ESPECIALIDADE')) {
        state = state.copyWith(selectedTab: ChannelTab.cce);
      } else {
        state = state.copyWith(selectedTab: ChannelTab.ccd);
      }
    }
  }

  void updateUser(UserEntity? user) {
    if (state.currentUser != user) {
      state = state.copyWith(currentUser: user);
      _initDefaultTab(user);
    }
  }

  Future<void> loadChannels() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final channels = await _repository.listAllChannels();
      state = state.copyWith(
        isLoading: false,
        channels: channels,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setTab(ChannelTab tab) {
    state = state.copyWith(selectedTab: tab);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.trim());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final channelsProvider =
    StateNotifierProvider<ChannelsNotifier, ChannelsState>((ref) {
  final repository = ref.watch(channelsRepositoryProvider);
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;
  final notifier = ChannelsNotifier(repository, user);
  return notifier;
});

// ─── Estado das Mensagens do Canal ───────────────────────────────────────────
class ChannelMessagesState {
  final bool isLoading;
  final bool isSending;
  final List<ChannelMessageEntity> messages;
  final String? errorMessage;

  const ChannelMessagesState({
    this.isLoading = false,
    this.isSending = false,
    this.messages = const [],
    this.errorMessage,
  });

  ChannelMessagesState copyWith({
    bool? isLoading,
    bool? isSending,
    List<ChannelMessageEntity>? messages,
    String? errorMessage,
  }) {
    return ChannelMessagesState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      messages: messages ?? this.messages,
      errorMessage: errorMessage,
    );
  }
}

class ChannelMessagesNotifier extends StateNotifier<ChannelMessagesState> {
  final ChannelsRepository _repository;
  final String _channelId;
  Timer? _pollingTimer;

  ChannelMessagesNotifier(this._repository, this._channelId)
      : super(const ChannelMessagesState(isLoading: true)) {
    loadMessages();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollMessages();
    });
  }

  Future<void> loadMessages() async {
    try {
      final messages = await _repository.listChannelMessages(_channelId);
      state = state.copyWith(
        isLoading: false,
        messages: messages,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _pollMessages() async {
    try {
      final messages = await _repository.listChannelMessages(_channelId);
      if (!listEquals(state.messages, messages)) {
        state = state.copyWith(messages: messages);
      }
    } catch (_) {
      // Ignora falhas temporárias de polling
    }
  }

  Future<bool> postMessage(String texto) async {
    final trimmed = texto.trim();
    if (trimmed.isEmpty) return false;

    state = state.copyWith(isSending: true);
    try {
      final newMsg = await _repository.postChannelMessage(_channelId, trimmed);
      final updatedList = [...state.messages, newMsg];
      state = state.copyWith(
        isSending: false,
        messages: updatedList,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<ChannelMessageStatsEntity> fetchMessageReaders(String messageId) async {
    return await _repository.getMessageReaders(_channelId, messageId);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final channelMessagesProvider = StateNotifierProvider.autoDispose.family<
    ChannelMessagesNotifier, ChannelMessagesState, String>((ref, channelId) {
  final repository = ref.watch(channelsRepositoryProvider);
  return ChannelMessagesNotifier(repository, channelId);
});
