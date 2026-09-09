import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/message_entity.dart';
import 'audio_message_player.dart';

class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isOwn;
  final bool showSenderName;
  final VoidCallback? onReply;
  final VoidCallback? onRetry;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDeleteForAll;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
    this.showSenderName = false,
    this.onReply,
    this.onRetry,
    this.onEdit,
    this.onDelete,
    this.onDeleteForAll,
  });

  bool get _isAudio =>
      message.tipo == MessageType.audio || message.texto.startsWith('[audio');

  String get _audioSource {
    final text = message.texto;
    if (text.startsWith('[audio')) {
      final closingBracket = text.indexOf(']');
      if (closingBracket != -1) {
        return text.substring(closingBracket + 1);
      }
    }
    return message.audioPath ?? text;
  }

  int get _audioDuration {
    if (message.audioDuration != null && message.audioDuration! > 0) {
      return message.audioDuration!;
    }
    final text = message.texto;
    if (text.startsWith('[audio:')) {
      final closingBracket = text.indexOf(']');
      if (closingBracket != -1) {
        final secStr = text.substring(7, closingBracket);
        return int.tryParse(secStr) ?? 0;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('HH:mm').format(message.criadoEm);

    final isExcluido = message.excluido;
    final bubbleColor = isExcluido
        ? (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0))
        : (isOwn
            ? AppColors.primary
            : (isDark ? AppColors.darkSurfaceVariant : AppColors.neutral100));

    final textColor = isExcluido
        ? (isDark ? Colors.white60 : Colors.black54)
        : (isOwn
            ? Colors.white
            : (isDark ? Colors.white : AppColors.textPrimary));

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageActions(context),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            border: isExcluido
                ? Border.all(color: isDark ? Colors.white12 : Colors.black12)
                : null,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isOwn ? 16 : 4),
              bottomRight: Radius.circular(isOwn ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOwn && message.status == MessageStatus.error)
                TextButton(
                  onPressed: onRetry,
                  child: const Text("Falha no envio · Tentar novamente", style: TextStyle(color: Colors.white)),
                ),
              if (showSenderName && !isOwn) ...[
                Text(
                  message.remetente.nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(height: 2),
              ],

              if (message.excluido)
                Text(
                  '🚫 Esta mensagem foi apagada',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                )
              else if (_isAudio)
                AudioMessagePlayer(
                  audioSource: _audioSource,
                  durationSeconds: _audioDuration,
                  isOwn: isOwn,
                )
              else
                Text(
                  message.texto,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14.5,
                    height: 1.3,
                  ),
                ),

              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.editado && !message.excluido) ...[
                    Text(
                      'editada ',
                      style: TextStyle(
                        fontSize: 10,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  if (isOwn) ...[
                    const SizedBox(width: 4),
                    _buildStatusIcon(textColor),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageActions(BuildContext context) {
    if (message.excluido) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (onReply != null)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Responder'),
                onTap: () {
                  Navigator.pop(ctx);
                  onReply!();
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copiar texto'),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: message.texto));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mensagem copiada')),
                );
              },
            ),
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar mensagem'),
                onTap: () {
                  Navigator.pop(ctx);
                  onEdit!();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Excluir mensagem', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir mensagem?'),
        content: const Text('Deseja realmente apagar esta mensagem para todos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onDelete?.call();
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(Color textColor) {
    switch (message.status) {
      case MessageStatus.sending:
        return Icon(Icons.access_time, size: 13, color: textColor.withValues(alpha: 0.7));
      case MessageStatus.sent:
        return Icon(Icons.check, size: 13, color: textColor.withValues(alpha: 0.7));
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 13, color: textColor.withValues(alpha: 0.7));
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 13, color: Color(0xFF67E8F9));
      case MessageStatus.error:
        return const Icon(Icons.error_outline, size: 13, color: Color(0xFFFCA5A5));
    }
  }
}
