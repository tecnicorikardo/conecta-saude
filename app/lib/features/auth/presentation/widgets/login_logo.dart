import 'package:flutter/material.dart';

class LoginLogo extends StatelessWidget {
  const LoginLogo({super.key});

  static const Color _primaryBlue = Color(0xFF1565C0);
  static const Color _secondaryText = Color(0xFF607D8B);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ─── Logo SUS Transparente ─────────────────────────────────────────
        Image.asset(
          'assets/images/logo_sus.png',
          width: 120,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 10),

        // ─── Identificação do Sistema ──────────────────────────────────────
        const Text(
          'Conecta Saúde',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _primaryBlue,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Comunicação Institucional',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _secondaryText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Sistema Único de Saúde',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _secondaryText.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
