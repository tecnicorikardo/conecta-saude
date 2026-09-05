import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/message_entity.dart';
import 'audio_player_widget.dart';
import 'message_status_icon.dart';

/// Bolha de mensagem estilo WhatsApp com identidade Conecta Saúde.
/// Suporta: texto, áudio, edição, exclusão, reply, context menu.
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Dismissible(
        key: ValueKey('swipe-${message.id}'),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (_) async {
          onReply?.call();
          return false; // não remove — só dispara o reply
        },
        background: _SwipeReplyBackground(),
        child: Padding(
          padding: EdgeInsets.only(
            left: isOwn ? 48 : 0,
            right: isOwn ? 0 : 48,
            bottom: 3,
            top: 1,
          ),
          child: Row(
            mainAxisAlignment:
                isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar do remetente (apenas mensagens recebidas, não consecutivas)
              if (!isOwn)
                Padding(
                  padding: const EdgeInsets.only(right: 4, bottom: 4),
                  child: _SenderAvatar(name: message.remetente.nome),
                ),

              // Bolha
              Flexible(child: _buildBubble(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Cores das bolhas
    final bubbleColor = isOwn
        ? (isDark ? AppColors.messageSentDark : AppColors.messageSent)
        : (isDark ? AppColors.messageReceivedDark : AppColors.messageReceived);

    final textColor = isOwn
        ? AppColors.onMessageSent
        : (isDark
            ? AppColors.onMessageReceivedDark
            : AppColors.onMessageReceived);

    // Raio dos cantos — estilo WhatsApp
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: isOwn
          ? const Radius.circular(18)
          : const Radius.circular(4),
      bottomRight: isOwn
          ? const Radius.circular(4)
          : const Radius.circular(18),
    );

    return Container(
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nome do remetente em grupos
            if (showSenderName && !isOwn)
              Padding(
                padding:
                    const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 2),
                child: Text(
                  message.remetente.nome,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _senderColor(message.remetente.id),
                  ),
                ),
              ),

            // Conteúdo da mensagem
            if (message.excluido)
              _buildDeleted(textColor)
            else if (message.tipo == MessageType.audio)
              _buildAudio(context, textColor)
            else
              _buildText(context, textColor),
          ],
        ),
      ),
    );
  }

  // ─── Mensagem de texto ────────────────────────────────────────────────────
  Widget _buildText(BuildContext context, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(
          left: 12, right: 12, top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Texto
          Text(
            message.texto,
            style: TextStyle(
              fontSize: 15,
              color: textColor,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 2),
          // Horário + status + editado
          _buildMeta(textColor),
        ],
      ),
    );
  }

  // ─── Mensagem de áudio ────────────────────────────────────────────────────
  Widget _buildAudio(BuildContext context, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AudioPlayerWidget(
            audioPath: message.audioPath,
            durationSeconds: message.audioDuration ?? 0,
            isOwn: isOwn,
          ),
          const SizedBox(height: 2),
          _buildMeta(textColor),
        ],
      ),
    );
  }

  // ─── Mensagem excluída ────────────────────────────────────────────────────
  Widget _buildDeleted(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.block,
            size: 14,
            color: textColor.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 6),
          Text(
            'Mensagem apagada',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatTime(message.criadoEm),
            style: TextStyle(
              fontSize: 11,
              color: textColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Metadados (hora + status + editado) ──────────────────────────────────
  Widget _buildMeta(Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.editado)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              'editado',
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
          ),
        Text(
          _formatTime(message.criadoEm),
          style: TextStyle(
            fontSize: 11,
            color: textColor.withValues(alpha: 0.7),
          ),
        ),
        if (isOwn) ...[
          const SizedBox(width: 4),
          MessageStatusIcon(
            status: message.status,
            size: 14,
            color: textColor.withValues(alpha: 0.8),
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _senderColor(String senderId) {
    final colors = [
      AppColors.primaryLight,
      const Color(0xFF9C27B0),
      const Color(0xFFFF5722),
      const Color(0xFF009688),
      const Color(0xFF3F51B5),
      const Color(0xFF795548),
    ];
    final index = senderId.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }

  // ─── Menu de contexto (long press) ───────────────────────────────────────
  void _showContextMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.neutral400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Preview da mensagem
              if (!message.excluido)
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message.tipo == MessageType.audio
                        ? '🎤 Mensagem de áudio'
                        : message.texto,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.onDarkSurface
                          : AppColors.onSurface,
                    ),
                  ),
                ),

              const Divider(height: 1),

              // Ações
              _ContextMenuItem(
                icon: Icons.reply,
                label: 'Responder',
                onTap: () {
                  Navigator.pop(context);
                  onReply?.call();
                },
              ),
              _ContextMenuItem(
                icon: Icons.copy,
                label: 'Copiar',
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: message.texto));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mensagem copiada'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              if (onEdit != null && !message.excluido)
                _ContextMenuItem(
                  icon: Icons.edit_outlined,
                  label: 'Editar',
                  onTap: () {
                    Navigator.pop(context);
                    onEdit?.call();
                  },
                ),
              if (onDelete != null)
                _ContextMenuItem(
                  icon: Icons.delete_outline,
                  label: 'Apagar para mim',
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context, forAll: false);
                  },
                ),
              if (onDeleteForAll != null)
                _ContextMenuItem(
                  icon: Icons.delete_sweep_outlined,
                  label: 'Apagar para todos',
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context, forAll: true);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, {required bool forAll}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apagar mensagem?'),
        content: Text(
          forAll
              ? 'A mensagem será apagada para todos os participantes.'
              : 'A mensagem será apagada apenas para você.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (forAll) {
                onDeleteForAll?.call();
              } else {
                onDelete?.call();
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
  }
}

// ─── Avatar pequeno do remetente ──────────────────────────────────────────────
class _SenderAvatar extends StatelessWidget {
  final String name;
  const _SenderAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').take(2).map((w) => w[0]).join().toUpperCase();
    final colors = [AppColors.primary, AppColors.secondary, const Color(0xFF6A5ACD)];
    final color = colors[name.codeUnits.fold(0, (a, b) => a + b) % colors.length];

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Center(
        child: Text(initials,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─── Background de swipe (responder) ─────────────────────────────────────────
class _SwipeReplyBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.reply, color: AppColors.primary, size: 20),
      ),
    );
  }
}

// ─── Item do menu de contexto ─────────────────────────────────────────────────
class _ContextMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ContextMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).textTheme.bodyLarge?.color;
    return ListTile(
      leading: Icon(icon, color: effectiveColor),
      title: Text(label, style: TextStyle(color: effectiveColor)),
      onTap: onTap,
      dense: true,
    );
  }
}
