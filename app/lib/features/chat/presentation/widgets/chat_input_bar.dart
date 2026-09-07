import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/message_entity.dart';
import '../providers/chat_provider.dart';

class ChatInputBar extends ConsumerStatefulWidget {
  final String conversationId;
  final MessageEntity? replyingTo;
  final MessageEntity? editingMessage;
  final VoidCallback onCancelReply;
  final VoidCallback onCancelEdit;
  final VoidCallback onSent;

  const ChatInputBar({
    super.key,
    required this.conversationId,
    this.replyingTo,
    this.editingMessage,
    required this.onCancelReply,
    required this.onCancelEdit,
    required this.onSent,
  });

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final _textCtrl = TextEditingController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    if (widget.editingMessage != null) {
      _textCtrl.text = widget.editingMessage!.texto;
      _isComposing = _textCtrl.text.trim().isNotEmpty;
    }
  }

  @override
  void didUpdateWidget(covariant ChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editingMessage != null && widget.editingMessage != oldWidget.editingMessage) {
      _textCtrl.text = widget.editingMessage!.texto;
      _isComposing = true;
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    _textCtrl.clear();
    setState(() => _isComposing = false);

    // Notifica imediatamente para rolar e limpar estado de resposta/edição sem delay
    widget.onSent();

    if (widget.editingMessage != null) {
      await ref
          .read(messagesProvider(widget.conversationId).notifier)
          .editMessage(widget.editingMessage!.id, text);
    } else {
      ref
          .read(messagesProvider(widget.conversationId).notifier)
          .sendTextMessage(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner de resposta / edição
          if (widget.replyingTo != null)
            _buildContextBanner(
              icon: Icons.reply,
              title: 'Respondendo a ',
              subtitle: widget.replyingTo!.texto,
              onCancel: widget.onCancelReply,
            ),
          if (widget.editingMessage != null)
            _buildContextBanner(
              icon: Icons.edit_outlined,
              title: 'Editando mensagem',
              subtitle: widget.editingMessage!.texto,
              onCancel: widget.onCancelEdit,
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.neutral100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _textCtrl,
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Mensagem institucional...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (text) {
                        setState(() => _isComposing = text.trim().isNotEmpty);
                      },
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: _isComposing ? _send : null,
                  icon: const Icon(Icons.send_rounded),
                  color: AppColors.primary,
                  disabledColor: AppColors.neutral400,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextBanner({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onCancel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primary.withOpacity(0.08),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onCancel,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
