import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Badge visual para status de conta/entidade (Ativo / Inativo).
class StatusBadge extends StatelessWidget {
  final bool ativo;

  const StatusBadge({
    super.key,
    required this.ativo,
  });

  @override
  Widget build(BuildContext context) {
    final color = ativo ? AppColors.success : AppColors.neutral600;
    final text = ativo ? 'Ativo' : 'Inativo';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
