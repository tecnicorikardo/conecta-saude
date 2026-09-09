import 'dart:async';
import 'package:flutter/foundation.dart';
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
    _startPolling();
  }

  final Ref _ref;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _pollConversations();
    });
  }

  List<ConversationEntity> _sortConversations(List<ConversationEntity> list) {
    return List<ConversationEntity>.from(list)
      ..sort((a, b) {
        final cmp = b.atualizadoEm.compareTo(a.atualizadoEm);
        if (cmp != 0) return cmp;
        return b.id.compareTo(a.id);
      });
  }

  Future<void> _pollConversations() async {
    try {
      final repo = _ref.read(conversationRepositoryProvider);
      final raw = await repo.listConversations();
      if (!mounted) return;

      final sorted = _sortConversations(raw);
      final current = state.value;

      // Se a lista não mudou, não dispara re-render para evitar trocas de posição visuais
      if (current != null && listEquals(current, sorted)) {
        return;
      }

      state = AsyncValue.data(sorted);
    } catch (_) {
      // Ignora erro silenciosamente durante polling
    }
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(conversationRepositoryProvider);
      final raw = await repo.listConversations();
      final sorted = _sortConversations(raw);
      if (mounted) state = AsyncValue.data(sorted);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  /// Adiciona uma conversa recém-criada à lista sem recarregar tudo
  void addConversation(ConversationEntity conv) {
    final current = state.value ?? [];
    if (current.any((c) => c.id == conv.id)) return;
    final updated = _sortConversations([conv, ...current]);
    state = AsyncValue.data(updated);
  }

  /// Atualiza a última mensagem de uma conversa
  void updateLastMessage(String conversationId, MessageEntity msg) {
    final current = state.value ?? [];
    final updated = current.map((c) {
      if (c.id != conversationId) return c;
      return c.copyWith(
        lastMessage: msg,
        atualizadoEm: msg.criadoEm,
      );
    }).toList();

    state = AsyncValue.data(_sortConversations(updated));
  }

  /// Excluir conversa (individual ou grupo)
  Future<void> deleteConversation(String conversationId) async {
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((c) => c.id != conversationId).toList());

    try {
      final repo = _ref.read(conversationRepositoryProvider);
      await repo.deleteConversation(conversationId);
    } catch (e) {
      load();
      rethrow;
    }
  }

  /// Alternar auto-exclusão 24h
  Future<void> toggleAutoExcluir24h(String conversationId, bool value) async {
    final current = state.value ?? [];
    final updated = current.map((c) {
      if (c.id != conversationId) return c;
      return c.copyWith(autoExcluir24h: value);
    }).toList();
    state = AsyncValue.data(updated);

    try {
      final repo = _ref.read(conversationRepositoryProvider);
      await repo.updateGroup(conversationId, autoExcluir24h: value);
    } catch (_) {
      load();
    }
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
  final Map<String, MessageEntity> _pendingOutgoing = {};

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pendingOutgoing.clear();
    super.dispose();
  }

  /// Inicia polling a cada 3 segundos para mensagens novas
  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _pollNewMessages();
    });
  }

  List<MessageEntity> _filterAutoExcluir(List<MessageEntity> msgs) {
    final convs = _ref.read(conversationsProvider).valueOrNull ?? [];
    final thisConv = convs.where((c) => c.id == conversationId).firstOrNull;
    if (thisConv?.autoExcluir24h != true) return msgs;

    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return msgs.where((m) => m.criadoEm.isAfter(cutoff)).toList();
  }

  /// Carregamento inicial completo
  Future<void> _load() async {
    try {
      final repo = _ref.read(conversationRepositoryProvider);
      final messages = await repo.listMessages(conversationId);
      final filtered = _filterAutoExcluir(messages);
      if (mounted) state = AsyncValue.data(filtered);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  /// Polling — busca mensagens novas sem apagar mensagens enviadas localmente
  Future<void> _pollNewMessages() async {
    final current = state.value;
    if (current == null) return;

    try {
      final repo = _ref.read(conversationRepositoryProvider);
      final raw = await repo.listMessages(conversationId);
      final fresh = _filterAutoExcluir(raw);

      if (!mounted) return;

      // Limpa de _pendingOutgoing as mensagens que já chegaram do backend no polling
      _pendingOutgoing.removeWhere((tempId, pending) {
        return fresh.any((f) =>
            f.id == tempId ||
            (f.remetente.id == pending.remetente.id && f.texto == pending.texto));
      });

      final freshIds = fresh.map((m) => m.id).toSet();
      final merged = <MessageEntity>[...fresh];
      for (final pending in _pendingOutgoing.values) {
        if (!freshIds.contains(pending.id)) {
          merged.add(pending);
        }
      }

      merged.sort((a, b) => a.criadoEm.compareTo(b.criadoEm));
      state = AsyncValue.data(merged);

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
    final cleanText = texto.trim();
    if (cleanText.isEmpty) return;

    final currentUserId = _ref.read(currentUserIdProvider);
    final currentUserNome = _ref.read(currentUserNomeProvider);
    final currentUser = _ref.read(currentUserProvider).value;

    // Adicionar localmente com status "sending" IMEDIATAMENTE (zero delay na UI)
    final tempId = 'temp_${_uuid.v4()}';
    final tempMsg = MessageEntity(
      id: tempId,
      conversationId: conversationId,
      texto: cleanText,
      remetente: MessageSender(
        id: currentUserId.isNotEmpty ? currentUserId : (currentUser?.id ?? ''),
        nome: currentUserNome.isNotEmpty ? currentUserNome : (currentUser?.nome ?? 'Você'),
        cargo: currentUser?.cargo ?? '',
        fotoUrl: currentUser?.fotoUrl,
      ),
      criadoEm: DateTime.now(),
      status: MessageStatus.sending,
    );

    // Registra no mapa de pendentes para blindar contra o polling
    _pendingOutgoing[tempId] = tempMsg;

    final current = state.value ?? [];
    state = AsyncValue.data([...current, tempMsg]);

    try {
      final repo = _ref.read(conversationRepositoryProvider);
      final realMsg = await repo.sendMessage(conversationId, cleanText);

      _pendingOutgoing.remove(tempId);

      // Substitui a mensagem temporária pela real confirmada pelo servidor
      if (mounted) {
        final currentList = state.value ?? [];
        if (currentList.any((m) => m.id == realMsg.id)) {
          // Se já foi incluída por um polling simultâneo, remove a temporária
          state = AsyncValue.data(
            currentList.where((m) => m.id != tempId).toList(),
          );
        } else {
          // Substituição in-place limpa (sem sumir da tela)
          state = AsyncValue.data(
            currentList.map((m) => m.id == tempId ? realMsg : m).toList(),
          );
        }

        // Atualizar lista de conversas com a nova mensagem
        _ref
            .read(conversationsProvider.notifier)
            .updateLastMessage(conversationId, realMsg);
      }
    } catch (e) {
      _pendingOutgoing.remove(tempId);
      if (mounted) {
        final currentList = state.value ?? [];
        state = AsyncValue.data(
          currentList
              .map((m) => m.id == tempId
                  ? m.copyWith(status: MessageStatus.error)
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

  // ─── Limpar mensagens da conversa ──────────────────────────────────────
  Future<void> clearConversation() async {
    state = const AsyncValue.data([]);

    try {
      final repo = _ref.read(conversationRepositoryProvider);
      await repo.clearConversation(conversationId);
      _ref.read(conversationsProvider.notifier).load();
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
