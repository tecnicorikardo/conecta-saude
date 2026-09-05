import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Badge visual institucional para exibir o nível hierárquico do funcionário.
class HierarchyBadge extends StatelessWidget {
  final int nivel;
  final bool isSmall;

  const HierarchyBadge({
    super.key,
    required this.nivel,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getHierarchyConfig(nivel);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: config.color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: isSmall ? 12 : 14,
            color: config.color,
          ),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontSize: isSmall ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  static _HierarchyConfig _getHierarchyConfig(int nivel) {
    switch (nivel) {
      case 1:
        return const _HierarchyConfig(
          label: 'DIREÇÃO',
          color: AppColors.levelDirecao,
          icon: Icons.workspace_premium_rounded,
        );
      case 2:
        return const _HierarchyConfig(
          label: 'COORDENAÇÃO',
          color: AppColors.levelCoordenacao,
          icon: Icons.shield_rounded,
        );
      case 3:
        return const _HierarchyConfig(
          label: 'SUPERVISÃO',
          color: AppColors.levelSupervisao,
          icon: Icons.supervisor_account_rounded,
        );
      case 4:
      default:
        return const _HierarchyConfig(
          label: 'FUNCIONÁRIO',
          color: AppColors.levelFuncionario,
          icon: Icons.person_rounded,
        );
    }
  }
}

class _HierarchyConfig {
  final String label;
  final Color color;
  final IconData icon;

  const _HierarchyConfig({
    required this.label,
    required this.color,
    required this.icon,
  });
}
