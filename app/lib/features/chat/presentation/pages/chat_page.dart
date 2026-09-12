import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../providers/chat_provider.dart';
import '../../data/repositories/conversation_repository.dart';
import '../widgets/conversation_avatar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input_bar.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String conversationId;
  final ConversationEntity? conversation;

  const ChatPage({
    super.key,
    required this.conversationId,
    this.conversation,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  MessageEntity? _replyingTo;
  MessageEntity? _editingMessage;
  double _lastBottomInset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final view = View.maybeOf(context);
    if (view != null) {
      final currentInset = view.viewInsets.bottom;
      // Se o teclado estava visível e agora desceu a 0 (ex: botão Voltar do Android ou fechar teclado)
      if (_lastBottomInset > 0 && currentInset == 0) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
      _lastBottomInset = currentInset;
    }
    // Ao abrir ou fechar o teclado virtual no mobile, reajusta o scroll imediatamente
    _scrollToBottom(animated: false);
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final messagesAsync =
        ref.watch(messagesProvider(widget.conversationId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Detectar nome e foto do interlocutor (suporta navegação direta por push)
    final allConvs = ref.watch(conversationsProvider).valueOrNull ?? [];
    final conv = widget.conversation ??
        allConvs.where((c) => c.id == widget.conversationId).firstOrNull;
    final displayName = conv?.displayName(currentUserId) ?? 'Conversa';
    final photoUrl = conv?.displayPhoto(currentUserId);
    final isGroup = conv?.tipo == 'grupo' || conv?.tipo == 'setor';
    final subtitle = conv?.displaySubtitle(currentUserId) ?? '';
    final otherParticipant = isGroup ? null : conv?.otherParticipant(currentUserId);

    // Rolar automaticamente quando novas mensagens chegarem ou forem enviadas
    ref.listen<AsyncValue<List<MessageEntity>>>(
      messagesProvider(widget.conversationId),
      (prev, next) {
        final prevLen = prev?.value?.length ?? 0;
        final nextLen = next.value?.length ?? 0;
        if (nextLen > prevLen) {
          _scrollToBottom(animated: true);
        }
      },
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor:
          isDark ? const Color(0xFF0D1B2A) : const Color(0xFFECEFF1),
      appBar: _buildAppBar(
          context, displayName, photoUrl, subtitle, isGroup, currentUserId, conv, otherParticipant),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
        children: [
          // ─── Banner Informativo quando o Colega está Fora de Serviço ──────
          if (!isGroup && otherParticipant != null && !otherParticipant.isCurrentlyWorking)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFFDE68A),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.nightlight_round,
                    size: 15,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${otherParticipant.nome} está fora de serviço (${otherParticipant.jornadaInicio} às ${otherParticipant.jornadaFim}). Mensagens normais serão notificadas no próximo plantão.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // ─── Lista de mensagens ──────────────────────────────────────────
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (messages) {
                return _MessageList(
                  messages: messages,
                  currentUserId: currentUserId,
                  scrollController: _scrollController,
                  onRetry: (msg) async {
                    try {
                      await ref.read(messagesProvider(widget.conversationId).notifier)
                          .sendTextMessage(msg.texto, retryId: msg.id);
                    } catch (_) { /* O balão mantém a opção de tentar novamente. */ }
                  },
                  onReply: (msg) => setState(() {
                    _replyingTo = msg;
                    _editingMessage = null;
                  }),
                  onEdit: (msg) => setState(() {
                    _editingMessage = msg;
                    _replyingTo = null;
                  }),
                  onDelete: (msg) {
                    ref
                        .read(messagesProvider(widget.conversationId)
                            .notifier)
                        .deleteMessage(msg.id);
                  },
                  conversationId: widget.conversationId,
                );
              },
            ),
          ),

          // ─── Input bar ───────────────────────────────────────────────────
          ChatInputBar(
            conversationId: widget.conversationId,
            replyingTo: _replyingTo,
            editingMessage: _editingMessage,
            onCancelReply: () => setState(() => _replyingTo = null),
            onCancelEdit: () => setState(() => _editingMessage = null),
            onSent: () {
              setState(() {
                _replyingTo = null;
                _editingMessage = null;
              });
              _scrollToBottom();
            },
          ),
        ],
      ),
    ),
  );
}

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String displayName,
    String? photoUrl,
    String subtitle,
    bool isGroup,
    String currentUserId,
    ConversationEntity? conv,
    ConversationParticipant? otherParticipant,
  ) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: InkWell(
        onTap: () {
          if (isGroup) {
            context.push('/chat/${widget.conversationId}/info');
          } else {
            final otherMember = otherParticipant ?? conv?.participantes.firstOrNull;
            if (otherMember != null && otherMember.id.isNotEmpty) {
              context.push('/employees/${otherMember.id}');
            }
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              ConversationAvatar(
                name: displayName,
                photoUrl: photoUrl,
                isGroup: isGroup,
                size: 38,
                isWorking: otherParticipant?.isCurrentlyWorking,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isGroup && otherParticipant != null)
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: otherParticipant.isCurrentlyWorking
                                  ? const Color(0xFF4ADE80)
                                  : const Color(0xFFFBBF24),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            otherParticipant.isCurrentlyWorking ? 'Em Plantão' : 'Fora de Serviço',
                            style: TextStyle(
                              color: otherParticipant.isCurrentlyWorking
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFFDE68A),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            Flexible(
                              child: Text(
                                ' • $subtitle',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      )
                    else if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (isGroup) ...[
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: 'Adicionar participante',
            onPressed: () => _openAddParticipantsModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Dados do grupo',
            onPressed: () => context.push('/chat/${widget.conversationId}/info'),
          ),
        ],
        IconButton(
          icon: const Icon(Icons.call_outlined),
          onPressed: () {},
          tooltip: 'Chamada',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (v) async {
            if (v == 'info') {
              context.push('/chat/${widget.conversationId}/info');
            } else if (v == 'auto_excluir') {
              final messenger = ScaffoldMessenger.of(context);
              final isCurrentlyActive = conv?.autoExcluir24h == true;
              try {
                await ref
                    .read(conversationsProvider.notifier)
                    .toggleAutoExcluir24h(widget.conversationId, !isCurrentlyActive);
                ref.read(messagesProvider(widget.conversationId).notifier).refresh();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(!isCurrentlyActive
                        ? '⏱️ Mensagens temporárias ativas: mensagens expiram após 24 horas.'
                        : 'Mensagens temporárias desativadas.'),
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Erro ao atualizar: $e')),
                );
              }
            } else if (v == 'limpar') {
              final messenger = ScaffoldMessenger.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Limpar conversa?'),
                  content: const Text(
                    'Todas as mensagens desta conversa serão apagadas permanentemente. A conversa continuará na sua lista.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Limpar Histórico'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await ref
                      .read(messagesProvider(widget.conversationId).notifier)
                      .clearConversation();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Histórico da conversa limpo com sucesso.')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Erro ao limpar conversa: $e')),
                  );
                }
              }
            } else if (v == 'excluir') {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(isGroup ? 'Sair e excluir grupo?' : 'Excluir conversa?'),
                  content: Text(
                    isGroup
                      ? 'Você sairá deste grupo e ele será removido da sua lista de conversas.'
                      : 'Esta conversa e todo o seu histórico serão removidos permanentemente da sua lista.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Excluir'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await ref
                      .read(conversationsProvider.notifier)
                      .deleteConversation(widget.conversationId);
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Conversa excluída com sucesso.')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Erro ao excluir conversa: $e')),
                  );
                }
              }
            }
          },
          itemBuilder: (_) => [
            if (isGroup)
              const PopupMenuItem(value: 'info', child: Text('Dados do grupo')),
            PopupMenuItem(
              value: 'auto_excluir',
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 20,
                    color: (conv?.autoExcluir24h == true) ? Colors.amber.shade800 : null,
                  ),
                  const SizedBox(width: 8),
                  Text((conv?.autoExcluir24h == true) ? 'Desativar 24h' : 'Auto-exclusão 24h'),
                ],
              ),
            ),
            const PopupMenuItem(value: 'pesquisar', child: Text('Pesquisar')),
            const PopupMenuItem(value: 'silenciar', child: Text('Silenciar')),
            const PopupMenuItem(value: 'limpar', child: Text('Limpar conversa')),
            const PopupMenuItem(
              value: 'excluir',
              child: Text(
                'Excluir conversa',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ],
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primaryDark,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _openAddParticipantsModal(BuildContext context) {
    final availableAsync = ref.read(availableUsersProvider);
    final allUsers = availableAsync.valueOrNull ?? [];
    final conv = ref.read(conversationsProvider).valueOrNull?.where((c) => c.id == widget.conversationId).firstOrNull;
    final existingMemberIds = conv?.participantes.map((p) => p.id).toSet() ?? {};
    final candidates = allUsers.where((u) => !existingMemberIds.contains(u.id)).toList();

    final selectedIds = <String>{};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Adicionar Participantes'),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: candidates.isEmpty
                ? const Center(child: Text('Nenhum colega adicional para adicionar.'))
                : ListView.builder(
                    itemCount: candidates.length,
                    itemBuilder: (context, i) {
                      final u = candidates[i];
                      final isSelected = selectedIds.contains(u.id);
                      return CheckboxListTile(
                        value: isSelected,
                        activeColor: AppColors.primary,
                        title: Text(u.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('${u.cargo} • ${u.setorNome}', style: const TextStyle(fontSize: 12)),
                        secondary: ConversationAvatar(name: u.nome, photoUrl: u.fotoUrl, size: 36),
                        onChanged: (val) {
                          setModalState(() {
                            if (val == true) {
                              selectedIds.add(u.id);
                            } else {
                              selectedIds.remove(u.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedIds.isEmpty
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final repo = ref.read(conversationRepositoryProvider);
                        await repo.addGroupMembers(widget.conversationId, selectedIds.toList());
                        ref.invalidate(conversationsProvider);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('${selectedIds.length} participante(s) adicionado(s) com sucesso.'),
                          ),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Erro ao adicionar: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
              child: Text('Adicionar (${selectedIds.length})'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Lista de mensagens com separadores de data ───────────────────────────────
class _MessageList extends StatelessWidget {
  final List<MessageEntity> messages;
  final String currentUserId;
  final ScrollController scrollController;
  final void Function(MessageEntity) onReply;
  final void Function(MessageEntity) onEdit;
  final void Function(MessageEntity) onDelete;
  final void Function(MessageEntity) onRetry;
  final String conversationId;

  const _MessageList({
    required this.messages,
    required this.currentUserId,
    required this.scrollController,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    required this.onRetry,
    required this.conversationId,
  });

  @override
  Widget build(BuildContext context) {
    // Construir lista com separadores de data
    final items = _buildItems();

    return ListView.builder(
      controller: scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        if (item is DateTime) {
          return _DateSeparator(date: item);
        }

        final msg = item as MessageEntity;
        final isOwn = msg.remetente.id == currentUserId;

        return MessageBubble(
          message: msg,
          isOwn: isOwn,
          showSenderName: !isOwn,
          onReply: () => onReply(msg),
          onRetry: () => onRetry(msg),
          onEdit: isOwn && !msg.excluido ? () => onEdit(msg) : null,
          onDelete: isOwn && !msg.excluido ? () => onDelete(msg) : null,
          onDeleteForAll: isOwn && !msg.excluido ? () => onDelete(msg) : null,
        );
      },
    );
  }

  List<Object> _buildItems() {
    final items = <Object>[];
    final seenIds = <String>{};
    DateTime? lastDate;

    for (final msg in messages) {
      if (!seenIds.add(msg.id)) continue;
      final msgDate = DateTime(
          msg.criadoEm.year, msg.criadoEm.month, msg.criadoEm.day);
      if (lastDate == null || msgDate != lastDate) {
        items.add(msgDate);
        lastDate = msgDate;
      }
      items.add(msg);
    }
    return items;
  }
}

// ─── Separador de data ────────────────────────────────────────────────────────
class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(date.year, date.month, date.day);

    String label;
    if (msgDay == today) {
      label = 'Hoje';
    } else if (msgDay == yesterday) {
      label = 'Ontem';
    } else {
      try {
        label = DateFormat('d \'de\' MMMM \'de\' y', 'pt_BR').format(date);
      } catch (_) {
        label = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurfaceVariant.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.onDarkSurfaceVariant
                  : AppColors.neutral600,
            ),
          ),
        ),
      ),
    );
  }
}
