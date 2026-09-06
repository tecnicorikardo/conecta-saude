import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../providers/chat_provider.dart';
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

class _ChatPageState extends ConsumerState<ChatPage> {
  final _scrollController = ScrollController();
  MessageEntity? _replyingTo;
  MessageEntity? _editingMessage;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
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

    // Detectar nome e foto do interlocutor
    final conv = widget.conversation;
    final displayName = conv?.displayName(currentUserId) ?? 'Conversa';
    final photoUrl = conv?.displayPhoto(currentUserId);
    final isGroup = conv?.tipo == 'grupo' || conv?.tipo == 'setor';
    final subtitle = conv?.displaySubtitle(currentUserId) ?? '';

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0D1B2A) : const Color(0xFFECEFF1),
      appBar: _buildAppBar(
          context, displayName, photoUrl, subtitle, isGroup, currentUserId),
      body: Column(
        children: [
          // ─── Lista de mensagens ──────────────────────────────────────────
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (messages) {
                _scrollToBottom(animated: false);
                return _MessageList(
                  messages: messages,
                  currentUserId: currentUserId,
                  scrollController: _scrollController,
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
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String displayName,
    String? photoUrl,
    String subtitle,
    bool isGroup,
    String currentUserId,
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
          // TODO: abrir perfil do contato
        },
        child: Row(
          children: [
            ConversationAvatar(
              name: displayName,
              photoUrl: photoUrl,
              isGroup: isGroup,
              size: 38,
              showOnline: !isGroup,
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
                  if (subtitle.isNotEmpty)
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
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_outlined),
          onPressed: () {},
          tooltip: 'Videochamada',
        ),
        IconButton(
          icon: const Icon(Icons.call_outlined),
          onPressed: () {},
          tooltip: 'Chamada',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (v) {},
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'pesquisar', child: Text('Pesquisar')),
            PopupMenuItem(value: 'silenciar', child: Text('Silenciar')),
            PopupMenuItem(value: 'limpar', child: Text('Limpar conversa')),
          ],
        ),
      ],
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primaryDark,
        statusBarIconBrightness: Brightness.light,
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
  final String conversationId;

  const _MessageList({
    required this.messages,
    required this.currentUserId,
    required this.scrollController,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    required this.conversationId,
  });

  @override
  Widget build(BuildContext context) {
    // Construir lista com separadores de data
    final items = _buildItems();

    return ListView.builder(
      controller: scrollController,
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
