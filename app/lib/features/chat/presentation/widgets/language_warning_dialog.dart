import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../../../../core/services/language_filter_service.dart';

enum WarningDialogAction {
  review,
  sendAnyway,
  cancel,
  reportIncident,
}

class LanguageWarningDialog extends StatelessWidget {
  final FilterEvaluationResult result;
  final String originalText;

  const LanguageWarningDialog({
    super.key,
    required this.result,
    required this.originalText,
  });

  static Future<WarningDialogAction> show(
    BuildContext context, {
    required FilterEvaluationResult result,
    required String originalText,
  }) async {
    final res = await showDialog<WarningDialogAction>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => LanguageWarningDialog(
        result: result,
        originalText: originalText,
      ),
    );
    return res ?? WarningDialogAction.cancel;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final isDark = context.isDarkMode;

    final isLevel1 = result.level == LanguageRiskLevel.level1PotentiallyInappropriate;
    final isLevel2 = result.level == LanguageRiskLevel.level2OffensiveOrHostile;
    final isLevel3 = result.level == LanguageRiskLevel.level3SevereOrDiscriminatory;

    IconData headerIcon;
    Color statusColor;

    if (isLevel3) {
      headerIcon = Icons.gavel_rounded;
      statusColor = AppColors.error;
    } else if (isLevel2) {
      headerIcon = Icons.block_flipped;
      statusColor = const Color(0xFFD9822B);
    } else {
      headerIcon = Icons.info_outline_rounded;
      statusColor = tokens.themeAccentColor;
    }

    return AlertDialog(
      backgroundColor: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.border),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(headerIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              result.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.message,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Texto digitado:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  originalText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: tokens.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (isLevel1) ...[
          TextButton(
            onPressed: () => Navigator.pop(context, WarningDialogAction.cancel),
            child: Text('Cancelar', style: TextStyle(color: tokens.textSecondary)),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, WarningDialogAction.sendAnyway),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: tokens.border),
            ),
            child: Text('Enviar mesmo assim', style: TextStyle(color: tokens.textPrimary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, WarningDialogAction.review),
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.themeAccentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Revisar Mensagem'),
          ),
        ] else if (isLevel2) ...[
          TextButton(
            onPressed: () => Navigator.pop(context, WarningDialogAction.cancel),
            child: Text('Cancelar', style: TextStyle(color: tokens.textSecondary)),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, WarningDialogAction.reportIncident),
            icon: const Icon(Icons.flag_outlined, size: 16),
            label: const Text('Relatar Ocorrência'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, WarningDialogAction.review),
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.themeAccentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Editar Mensagem'),
          ),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.pop(context, WarningDialogAction.cancel),
            child: Text('Entendi', style: TextStyle(color: tokens.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, WarningDialogAction.reportIncident),
            icon: const Icon(Icons.shield_outlined, size: 16),
            label: const Text('Ir para Ouvidoria'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }
}
