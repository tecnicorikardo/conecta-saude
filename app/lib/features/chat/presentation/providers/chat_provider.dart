import '../../../../core/services/realtime_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../data/models/conversation_model.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';

// Armazena timestamp em memória e cache local de quando cada conversa foi limpa
final Map<String, DateTime> _conversationClearedAt = {};

Future<List<MessageEntity>?> _getCachedMessages(String conversationId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('chat_cache_msgs_$conversationId');
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List;
      return list.map((j) => MessageEntity.fromJson(j as Map<String, dynamic>)).toList();
    }
  } catch (_) {}
  return null;
}

Future<void> _saveCachedMessages(String conversationId, List<MessageEntity> messages) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final toSave = messages.length > 50 ? messages.sublist(messages.length - 50) : messages;
    final jsonList = toSave.map((m) => m.toJson()).toList();
    await prefs.setString('chat_cache_msgs_$conversationId', jsonEncode(jsonList));
  } catch (_) {}
}

Future<DateTime?> _getConversationClearedAt(String conversationId) async {
  if (_conversationClearedAt.containsKey(conversationId)) {
    return _conversationClearedAt[conversationId];
  }
  try {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt('chat_cleared_at_$conversationId');
    if (ms != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      _conversationClearedAt[conversationId] = dt;
      return dt;
    }
  } catch (_) {}
  return null;
}

Future<void> _setConversationClearedAt(String conversationId, DateTime dt) async {
  _conversationClearedAt[conversationId] = dt;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('chat_cleared_at_$conversationId', dt.millisecondsSinceEpoch);
  } catch (_) {}
}

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
  ref.watch(realtimeServiceProvider);
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
  StreamSubscription<String?>? _realtimeSub;
  bool _syncing = false;
  bool _syncAgain = false;
  int _pollTicks = 0;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _realtimeSub?.cancel();
    super.dispose();
  }

  void _startPolling() {
    final realtime = _ref.read(realtimeServiceProvider);
    _realtimeSub = realtime.changes.listen((_) {
      if (mounted) unawaited(_pollConversations());
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && (!realtime.connected || ++_pollTicks % 10 == 0)) {
        unawaited(_pollConversations());
      }
    });
  }

  List<ConversationEntity> _sortConversations(List<ConversationEntity> list) {
    return List<ConversationEntity>.from(list.map((c) {
      final clearedAt = _conversationClearedAt[c.id];
      if (clearedAt != null && c.lastMessage != null && !c.lastMessage!.criadoEm.isAfter(clearedAt)) {
        return c.copyWith(lastMessage: null);
      }
      return c;
    }))
      ..sort((a, b) {
        final cmp = b.atualizadoEm.compareTo(a.atualizadoEm);
        if (cmp != 0) return cmp;
        return b.id.compareTo(a.id);
      });
  }

  Future<void> _pollConversations() async {
    if (_syncing) { _syncAgain = true; return; }
    _syncing = true;
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
    } finally {
      _syncing = false;
      if (_syncAgain && mounted) {
        _syncAgain = false;
        unawaited(_pollConversations());
      }
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

  /// Limpa o preview da última mensagem após limpar a conversa
  void clearConversationLastMessage(String conversationId) {
    final current = state.value ?? [];
    final updated = current.map((c) {
      if (c.id != conversationId) return c;
      return c.copyWith(
        lastMessage: null,
      );
    }).toList();

    state = AsyncValue.data(updated);
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
    StateNotifierProvider.autoDispose.family<MessagesNotifier,
        AsyncValue<List<MessageEntity>>, String>((ref, conversationId) {
  ref.watch(realtimeServiceProvider);
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
  StreamSubscription<String?>? _realtimeSub;
  bool _syncing = false;
  bool _syncAgain = false;
  bool _flushingOutbox = false;
  int _pollTicks = 0;
  final Map<String, MessageEntity> _pendingOutgoing = {};

  @override
  void dispose() {
    _pollTimer?.cancel();
    _realtimeSub?.cancel();
    _pendingOutgoing.clear();
    super.dispose();
  }

  /// Inicia polling a cada 3 segundos para mensagens novas e reenvio de fila offline
  void _startPolling() {
    final realtime = _ref.read(realtimeServiceProvider);
    _realtimeSub = realtime.changes.listen((id) {
      if (mounted && (id == null || id == conversationId)) {
        unawaited(_pollNewMessages());
      }
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      if (_pendingOutgoing.isNotEmpty) {
        unawaited(_flushOutbox());
      }
      if (!realtime.connected || ++_pollTicks % 10 == 0) {
        unawaited(_pollNewMessages());
      }
    });
  }

  List<MessageEntity> _filterMessages(List<MessageEntity> msgs) {
    var result = msgs;

    // 1. Oculta mensagens enviadas antes do momento em que a conversa foi limpa
    final clearedAt = _conversationClearedAt[conversationId];
    if (clearedAt != null) {
      result = result.where((m) => m.criadoEm.isAfter(clearedAt)).toList();
    }

    // 2. Oculta mensagens excluídas para não poluir o histórico com balões residuais
    result = result.where((m) => !m.excluido).toList();

    // 3. Regra de auto-exclusão 24h
    final convs = _ref.read(conversationsProvider).valueOrNull ?? [];
    final thisConv = convs.where((c) => c.id == conversationId).firstOrNull;
    if (thisConv?.autoExcluir24h == true) {
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      result = result.where((m) => m.criadoEm.isAfter(cutoff)).toList();
    }

    return result;
  }

  /// Carregamento inicial completo com suporte offline imediato
  Future<void> _load() async {
    try {
      await _getConversationClearedAt(conversationId);

      // 1. Carrega imediatamente do cache local para abertura instantânea (0 delay / offline)
      final cached = await _getCachedMessages(conversationId);
      if (cached != null && cached.isNotEmpty && mounted) {
        state = AsyncValue.data(_filterMessages(cached));
      }

      // 2. Busca dados atualizados do servidor
      final repo = _ref.read(conversationRepositoryProvider);
      final messages = await repo.listMessages(conversationId);
      final filtered = _filterMessages(messages);

      // Salva em cache local para futuras aberturas offline
      await _saveCachedMessages(conversationId, filtered);

      if (mounted) state = AsyncValue.data(filtered);
    } catch (e, st) {
      // Se estiver offline ou o servidor oscilar, mantém o cache local sem tela de erro
      final cached = await _getCachedMessages(conversationId);
      if (cached != null && cached.isNotEmpty && mounted) {
        state = AsyncValue.data(_filterMessages(cached));
      } else if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Polling — busca mensagens novas sem apagar mensagens pendentes locais
  Future<void> _pollNewMessages() async {
    if (_syncing) { _syncAgain = true; return; }
    _syncing = true;
    final current = state.value;
    if (current == null) { _syncing = false; return; }

    try {
      final repo = _ref.read(conversationRepositoryProvider);
      final raw = await repo.listMessages(conversationId);
      final fresh = _filterMessages(raw);

      if (!mounted) return;

      // Limpa de _pendingOutgoing as mensagens que já chegaram do backend por ID ou conteúdo idêntico recente
      _pendingOutgoing.removeWhere((tempId, pending) {
        return fresh.any((f) =>
            f.id == tempId ||
            (f.remetente.id == pending.remetente.id &&
                f.texto == pending.texto &&
                f.criadoEm.difference(pending.criadoEm).inSeconds.abs() < 90));
      });

      final merged = <MessageEntity>[...fresh];
      for (final pending in _pendingOutgoing.values) {
        final alreadyInFresh = fresh.any((f) =>
            f.id == pending.id ||
            (f.remetente.id == pending.remetente.id &&
                f.texto == pending.texto &&
                f.criadoEm.difference(pending.criadoEm).inSeconds.abs() < 90));
        if (!alreadyInFresh) {
          merged.add(pending);
        }
      }

      merged.sort((a, b) => a.criadoEm.compareTo(b.criadoEm));
      state = AsyncValue.data(merged);

      // Atualiza o cache local e a lista de conversas
      await _saveCachedMessages(conversationId, fresh);

      if (fresh.isNotEmpty) {
        _ref
            .read(conversationsProvider.notifier)
            .updateLastMessage(conversationId, fresh.last);
      }
    } catch (_) {
      // Polling silencioso — não exibe erro
    } finally {
      _syncing = false;
      if (_syncAgain && mounted) {
        _syncAgain = false;
        unawaited(_pollNewMessages());
      }
    }
  }

  /// Despacha mensagens pendentes na fila (Outbox) assim que a internet reconectar
  Future<void> _flushOutbox() async {
    if (_flushingOutbox || _pendingOutgoing.isEmpty) return;
    _flushingOutbox = true;
    try {
      final pendingList = _pendingOutgoing.values
          .where((m) => m.status == MessageStatus.sending)
          .toList();

      for (final tempMsg in pendingList) {
        try {
          final repo = _ref.read(conversationRepositoryProvider);
          final realMsg = await repo.sendMessage(conversationId, tempMsg.texto, clientMessageId: tempMsg.id);
          _pendingOutgoing.remove(tempMsg.id);

          if (mounted) {
            final currentList = state.value ?? [];
            final updatedList = currentList.map((m) => m.id == tempMsg.id ? realMsg : m).toList();
            state = AsyncValue.data(updatedList);
            await _saveCachedMessages(conversationId, updatedList);
            _ref.read(conversationsProvider.notifier).updateLastMessage(conversationId, realMsg);
          }
        } catch (_) {
          // Mantém na fila com reloginho para tentar no próximo ciclo
          break;
        }
      }
    } finally {
      _flushingOutbox = false;
    }
  }

  // ─── Enviar mensagem de texto (WhatsApp Style com reloginho 🕒) ──────────
  Future<void> sendTextMessage(String texto, {String? retryId}) async {
    final cleanText = texto.trim();
    if (cleanText.isEmpty) return;

    final currentUserId = _ref.read(currentUserIdProvider);
    final currentUserNome = _ref.read(currentUserNomeProvider);
    final currentUser = _ref.read(currentUserProvider).value;

    // Adicionar localmente com status "sending" (reloginho 🕒) IMEDIATAMENTE (zero delay na UI)
    final tempId = retryId ?? _uuid.v4();
    if (_pendingOutgoing[tempId]?.status == MessageStatus.sending) return;
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
      status: MessageStatus.sending, // Reloginho WhatsApp
    );

    // Registra no mapa de pendentes para blindar contra o polling
    _pendingOutgoing[tempId] = tempMsg;

    final current = state.value ?? [];
    state = AsyncValue.data([...current.where((m) => m.id != tempId), tempMsg]);

    try {
      final repo = _ref.read(conversationRepositoryProvider);
      final realMsg = await repo.sendMessage(conversationId, cleanText, clientMessageId: tempId);

      _pendingOutgoing.remove(tempId);

      // Substitui a mensagem temporária pela real confirmada pelo servidor (✓✓ entregue)
      if (mounted) {
        final currentList = state.value ?? [];
        final updatedList = currentList.map((m) {
          if (m.id == tempId) return realMsg;
          return m;
        }).toList();

        // Se por ventura o polling já tiver colocado realMsg, evita duplicata
        final deduped = <String, MessageEntity>{};
        for (final m in updatedList) {
          deduped[m.id] = m;
        }

        state = AsyncValue.data(deduped.values.toList());
        await _saveCachedMessages(conversationId, deduped.values.toList());

        // Atualizar lista de conversas com a nova mensagem
        _ref
            .read(conversationsProvider.notifier)
            .updateLastMessage(conversationId, realMsg);
      }
    } catch (e) {
      // Se falhou por falta de internet ou timeout, MANTÉM com reloginho 🕒 e deixa a fila tentar reenviar!
      debugPrint('[Chat Outbox] Falha ao enviar mensagem imediatamente. Mantendo na fila com reloginho: $e');
      if (mounted) {
        // Mantém a mensagem no estado com status sending (reloginho 🕒)
        final currentList = state.value ?? [];
        if (!currentList.any((m) => m.id == tempId)) {
          state = AsyncValue.data([...currentList, tempMsg]);
        }
      }
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
    final now = DateTime.now();
    await _setConversationClearedAt(conversationId, now);

    state = const AsyncValue.data([]);

    try {
      final repo = _ref.read(conversationRepositoryProvider);
      try {
        await repo.clearConversation(conversationId);
      } catch (_) {}
      _ref.read(conversationsProvider.notifier).clearConversationLastMessage(conversationId);
    } catch (_) {
      state = const AsyncValue.data([]);
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
  String _currentQuery = '';
  String? _currentCargo;

  Future<void> search([String? query, String? cargo]) async {
    if (query != null) _currentQuery = query;
    if (cargo != null) _currentCargo = cargo.isEmpty ? null : cargo;

    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(conversationRepositoryProvider);
      final users = await repo.listAvailableUsers(
        search: _currentQuery,
        cargo: _currentCargo,
      );
      state = AsyncValue.data(users);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
