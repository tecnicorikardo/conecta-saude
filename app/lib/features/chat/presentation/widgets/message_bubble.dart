import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/message_entity.dart';
import 'audio_message_player.dart';

class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isOwn;
  final bool showSenderName;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDeleteForAll;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
    this.showSenderName = false,
    this.onReply,
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

    final bubbleColor = isOwn
        ? AppColors.primary
        : (isDark ? AppColors.darkSurfaceVariant : AppColors.neutral100);

    final textColor = isOwn
        ? Colors.white
        : (isDark ? Colors.white : AppColors.textPrimary);

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bubbleColor,
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
