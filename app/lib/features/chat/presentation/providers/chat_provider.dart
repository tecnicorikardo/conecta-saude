import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../data/models/conversation_model.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';

// ─── Usuário atual ────────────────────────────────────────────────────────────
final currentUserIdProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider).value;
  return user?.id ?? '';
});

final currentUserNomeProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider).value;
  return user?.nome ?? 'Você';
});

// ─── Lista de conversas — dados reais da API ──────────────────────────────────
final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier,
        AsyncValue<List<ConversationEntity>>>((ref) {
  return ConversationsNotifier(ref);
});

class ConversationsNotifier
    extends StateNotifier<AsyncValue<List<ConversationEntity>>> {
  ConversationsNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(conversationRepositoryProvider);
      final conversations = await repo.listConversations();
      state = AsyncValue.data(conversations);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Adiciona uma conversa recém-criada à lista sem recarregar tudo
  void addConversation(ConversationEntity conv) {
    final current = state.value ?? [];
    // Evitar duplicata
    if (current.any((c) => c.id == conv.id)) return;
    state = AsyncValue.data([conv, ...current]);
  }

  /// Atualiza a última mensagem de uma conversa
  void updateLastMessage(String conversationId, MessageEntity msg) {
    final current = state.value ?? [];
    state = AsyncValue.data(current.map((c) {
      if (c.id != conversationId) return c;
      return ConversationEntity(
        id: c.id,
        tipo: c.tipo,
        nome: c.nome,
        participantes: c.participantes,
        lastMessage: msg,
        unreadCount: c.unreadCount,
        atualizadoEm: DateTime.now(),
      );
    }).toList()
      ..sort((a, b) => b.atualizadoEm.compareTo(a.atualizadoEm)));
  }
}

// ─── Mensagens de uma conversa — dados reais + polling ───────────────────────
final messagesProvider =
    StateNotifierProvider.family<MessagesNotifier,
        AsyncValue<List<MessageEntity>>, String>((ref, conversationId) {
  return MessagesNotifier(conversationId, ref);
});

class MessagesNotifier
    extends StateNotifier<AsyncValue<List<MessageEntity>>> {
  MessagesNotifier(this.conversationId, this._ref)
      : super(const AsyncValue.loading()) {
    _load();
    _startPolling();
  }

  final String conversationId;
  final Ref _ref;
  final _uuid = const Uuid();
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Inicia polling a cada 3 segundos para mensagens novas
  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _pollNewMessages();
    });
  }

  /// Carregamento inicial completo
  Future<void> _load() async {
    try {
      final repo = _ref.read(conversationRepositoryProvider);
      final messages = await repo.listMessages(conversationId);
      if (mounted) state = AsyncValue.data(messages);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  /// Polling — busca mensagens novas sem apagar as locais
  Future<void> _pollNewMessages() async {
    final current = state.value;
    if (current == null) return;

    try {
      final repo = _ref.read(conversationRepositoryProvider);
      final fresh = await repo.listMessages(conversationId);

      if (!mounted) return;

      // Mesclar: manter mensagens "sending" locais que ainda não chegaram
      final freshIds = fresh.map((m) => m.id).toSet();
      final stillSending = current
          .where((m) =>
              m.status == MessageStatus.sending &&
              !freshIds.contains(m.id))
          .toList();

      state = AsyncValue.data([...fresh, ...stillSending]);

      // Atualizar última mensagem da conversa
      if (fresh.isNotEmpty) {
        _ref
            .read(conversationsProvider.notifier)
            .updateLastMessage(conversationId, fresh.last);
      }
    } catch (_) {
      // Polling silencioso — não exibe erro
    }
  }

  // ─── Enviar mensagem de texto ───────────────────────────────────────────
  Future<void> sendTextMessage(String texto) async {
    if (texto.trim().isEmpty) return;

    final currentUserId = _ref.read(currentUserIdProvider);
    final currentUserNome = _ref.read(currentUserNomeProvider);
    final currentUser = _ref.read(currentUserProvider).value;

    // Adicionar localmente como "sending" imediatamente (UX responsiva)
    final tempId = 'temp_${_uuid.v4()}';
    final tempMsg = MessageEntity(
      id: tempId,
      conversationId: conversationId,
      texto: texto.trim(),
      remetente: MessageSender(
        id: currentUserId,
        nome: currentUserNome,
        cargo: currentUser?.cargo ?? '',
        fotoUrl: currentUser?.fotoUrl,
      ),
      criadoEm: DateTime.now(),
      status: MessageStatus.sending,
    );

    final current = state.value ?? [];
    state = AsyncValue.data([...current, tempMsg]);

    try {
      final repo = _ref.read(conversationRepositoryProvider);
      final realMsg = await repo.sendMessage(conversationId, texto.trim());

      // Substituir a mensagem temporária pela real
      if (mounted) {
        final updated = state.value ?? [];
        state = AsyncValue.data(
          updated.map((m) => m.id == tempId ? realMsg : m).toList(),
        );

        // Atualizar lista de conversas
        _ref
            .read(conversationsProvider.notifier)
            .updateLastMessage(conversationId, realMsg);
      }
    } catch (e) {
      // Marcar como erro
      if (mounted) {
        final updated = state.value ?? [];
        state = AsyncValue.data(
          updated
              .map((m) => m.id == tempId
                  ? m.copyWith(status: MessageStatus.sent)
                  : m)
              .toList(),
        );
      }
      rethrow;
    }
  }

  // ─── Enviar áudio ──────────────────────────────────────────────────────
  void sendAudioMessage(String path, int durationSeconds) {
    final currentUserId = _ref.read(currentUserIdProvider);
    final currentUserNome = _ref.read(currentUserNomeProvider);
    final currentUser = _ref.read(currentUserProvider).value;

    final msg = MessageEntity(
      id: 'temp_${_uuid.v4()}',
      conversationId: conversationId,
      texto: '🎤 Áudio',
      tipo: MessageType.audio,
      remetente: MessageSender(
        id: currentUserId,
        nome: currentUserNome,
        cargo: currentUser?.cargo ?? '',
      ),
      criadoEm: DateTime.now(),
      status: MessageStatus.sending,
      audioDuration: durationSeconds,
      audioPath: path,
    );

    final current = state.value ?? [];
    state = AsyncValue.data([...current, msg]);
    // TODO: upload de áudio para storage
  }

  // ─── Editar mensagem ───────────────────────────────────────────────────
  Future<void> editMessage(String messageId, String novoTexto) async {
    // Otimista: atualizar local primeiro
    final current = state.value ?? [];
    state = AsyncValue.data(current.map((m) {
      if (m.id != messageId) return m;
      return m.copyWith(
        texto: novoTexto,
        editado: true,
        editadoEm: DateTime.now(),
      );
    }).toList());

    try {
      final repo = _ref.read(conversationRepositoryProvider);
      await repo.editMessage(conversationId, messageId, novoTexto);
    } catch (e) {
      // Reverter em caso de erro — recarregar do servidor
      _load();
      rethrow;
    }
  }

  // ─── Excluir mensagem ──────────────────────────────────────────────────
  Future<void> deleteMessage(String messageId) async {
    // Otimista
    final current = state.value ?? [];
    state = AsyncValue.data(current.map((m) {
      if (m.id != messageId) return m;
      return m.copyWith(excluido: true);
    }).toList());

    try {
      final repo = _ref.read(conversationRepositoryProvider);
      await repo.deleteMessage(messageId);
    } catch (e) {
      _load();
      rethrow;
    }
  }

  /// Forçar recarregamento
  Future<void> refresh() => _load();
}

// ─── Usuários disponíveis para nova conversa / grupo ─────────────────────────
final availableUsersProvider =
    FutureProvider.autoDispose<List<UserSummary>>((ref) async {
  final repo = ref.watch(conversationRepositoryProvider);
  return repo.listAvailableUsers();
});

final usersSearchProvider = StateNotifierProvider.autoDispose<
    UsersSearchNotifier, AsyncValue<List<UserSummary>>>((ref) {
  return UsersSearchNotifier(ref);
});

class UsersSearchNotifier
    extends StateNotifier<AsyncValue<List<UserSummary>>> {
  UsersSearchNotifier(this._ref) : super(const AsyncValue.loading()) {
    search('');
  }

  final Ref _ref;

  Future<void> search(String query) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(conversationRepositoryProvider);
      final users = await repo.listAvailableUsers(search: query);
      state = AsyncValue.data(users);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
