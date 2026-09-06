import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class LoginLogo extends StatelessWidget {
  final double size;

  const LoginLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.local_hospital_rounded,
            size: size * 0.55,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'CONECTA SAÚDE',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sistema Integrado de Comunicação Institucional SUS',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
