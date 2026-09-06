import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HierarchyBadge extends StatelessWidget {
  final int hierarquiaNivel;
  final bool isSmall;

  const HierarchyBadge({
    super.key,
    int? hierarquiaNivel,
    int? nivel,
    this.isSmall = false,
  }) : hierarquiaNivel = hierarquiaNivel ?? nivel ?? 4;

  String get _label {
    switch (hierarquiaNivel) {
      case 1:
        return 'DIREÇÃO';
      case 2:
        return 'COORDENAÇÃO';
      case 3:
        return 'SUPERVISÃO';
      default:
        return 'FUNCIONÁRIO';
    }
  }

  Color get _color {
    switch (hierarquiaNivel) {
      case 1:
        return AppColors.levelDirecao;
      case 2:
        return AppColors.levelCoordenacao;
      case 3:
        return AppColors.levelSupervisao;
      default:
        return AppColors.levelFuncionario;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: isSmall ? 9.5 : 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
