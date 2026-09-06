import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final bool ativo;

  const StatusBadge({super.key, required this.ativo});

  @override
  Widget build(BuildContext context) {
    final bgColor = ativo ? AppColors.successContainer : AppColors.errorContainer;
    final textColor = ativo ? AppColors.onSuccessContainer : AppColors.onErrorContainer;
    final label = ativo ? 'ATIVO' : 'INATIVO';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
