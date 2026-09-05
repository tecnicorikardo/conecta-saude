import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/message_entity.dart';

/// Ícone de status da mensagem — idêntico ao WhatsApp em comportamento,
/// mas com as cores do Conecta Saúde.
class MessageStatusIcon extends StatelessWidget {
  final MessageStatus status;
  final double size;
  final Color? color;

  const MessageStatusIcon({
    super.key,
    required this.status,
    this.size = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Colors.white.withValues(alpha: 0.7),
            ),
          ),
        );

      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: size,
          color: color ?? Colors.white.withValues(alpha: 0.7),
        );

      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: size,
          color: color ?? Colors.white.withValues(alpha: 0.7),
        );

      case MessageStatus.read:
        return Icon(
          Icons.done_all,
          size: size,
          // Azul claro quando lido — equivalente ao azul do WhatsApp
          color: AppColors.primaryContainer,
        );
    }
  }
}
