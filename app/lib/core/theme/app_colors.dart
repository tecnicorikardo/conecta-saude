import 'package:flutter/material.dart';

/// Paleta de cores institucional — identidade SUS
/// Cor base extraída da logo: #1565C0 (azul governo)
abstract class AppColors {
  // ─── Cores principais — Azul SUS ─────────────────────────────────────────
  static const Color primary        = Color(0xFF1565C0); // azul SUS exato
  static const Color primaryLight   = Color(0xFF1976D2); // azul médio
  static const Color primaryDark    = Color(0xFF0D47A1); // azul escuro
  static const Color primaryDeep    = Color(0xFF0A3880); // azul profundo
  static const Color primaryContainer    = Color(0xFFD6E4FF);
  static const Color onPrimary           = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer  = Color(0xFF0D47A1);

  // ─── Cores secundárias ───────────────────────────────────────────────────
  static const Color secondary           = Color(0xFF1E88E5);
  static const Color secondaryLight      = Color(0xFF42A5F5);
  static const Color secondaryContainer  = Color(0xFFE3F2FD);
  static const Color onSecondary         = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF0D47A1);

  // ─── Surface / Background (Light) ────────────────────────────────────────
  static const Color background      = Color(0xFFF5F7FA);
  static const Color surface         = Color(0xFFFFFFFF);
  static const Color surfaceVariant  = Color(0xFFEEF2F7);
  static const Color surfaceContainer = Color(0xFFF0F4F8);
  static const Color onBackground    = Color(0xFF0D1B2A);
  static const Color onSurface       = Color(0xFF0D1B2A);
  static const Color onSurfaceVariant = Color(0xFF3A4A5C);

  // ─── Surface / Background (Dark) ─────────────────────────────────────────
  static const Color darkBackground      = Color(0xFF0A1628);
  static const Color darkSurface         = Color(0xFF102040);
  static const Color darkSurfaceVariant  = Color(0xFF162B4A);
  static const Color darkSurfaceContainer = Color(0xFF132035);
  static const Color onDarkBackground    = Color(0xFFDDE8F5);
  static const Color onDarkSurface       = Color(0xFFDDE8F5);
  static const Color onDarkSurfaceVariant = Color(0xFF90AFCE);

  // ─── Status ──────────────────────────────────────────────────────────────
  static const Color success      = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color onSuccess    = Color(0xFFFFFFFF);

  static const Color warning      = Color(0xFFE65100);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color onWarning    = Color(0xFFFFFFFF);

  static const Color error        = Color(0xFFC62828);
  static const Color errorLight   = Color(0xFFFFEBEE);
  static const Color onError      = Color(0xFFFFFFFF);

  static const Color info         = Color(0xFF0277BD);
  static const Color infoLight    = Color(0xFFE1F5FE);

  // ─── Emergência ──────────────────────────────────────────────────────────
  static const Color emergency     = Color(0xFFB71C1C);
  static const Color emergencyLight = Color(0xFFFFCDD2);
  static const Color emergencyDark  = Color(0xFF7F0000);
  static const Color onEmergency   = Color(0xFFFFFFFF);

  // ─── Hierarquia ──────────────────────────────────────────────────────────
  static const Color levelDirecao      = Color(0xFF1565C0); // azul SUS
  static const Color levelCoordenacao  = Color(0xFF1976D2);
  static const Color levelSupervisao   = Color(0xFF42A5F5);
  static const Color levelFuncionario  = Color(0xFF90CAF9);

  // ─── Mensagens (Chat) ────────────────────────────────────────────────────
  static const Color messageSent          = Color(0xFF1565C0); // azul SUS
  static const Color messageReceived      = Color(0xFFFFFFFF);
  static const Color messageSentDark      = Color(0xFF1976D2);
  static const Color messageReceivedDark  = Color(0xFF102040);
  static const Color onMessageSent        = Color(0xFFFFFFFF);
  static const Color onMessageReceived    = Color(0xFF0D1B2A);
  static const Color onMessageReceivedDark = Color(0xFFDDE8F5);

  // ─── Neutros ─────────────────────────────────────────────────────────────
  static const Color neutral100  = Color(0xFFFFFFFF);
  static const Color neutral200  = Color(0xFFF5F7FA);
  static const Color neutral300  = Color(0xFFEEF2F7);
  static const Color neutral400  = Color(0xFFCDD5E0);
  static const Color neutral500  = Color(0xFF8FA3BC);
  static const Color neutral600  = Color(0xFF5B7594);
  static const Color neutral700  = Color(0xFF3A4A5C);
  static const Color neutral800  = Color(0xFF1E2D3D);
  static const Color neutral900  = Color(0xFF0D1B2A);
  static const Color neutral1000 = Color(0xFF050E18);

  // ─── Outline ─────────────────────────────────────────────────────────────
  static const Color outline        = Color(0xFFB0C4D8);
  static const Color outlineVariant = Color(0xFFD6E4F0);
  static const Color outlineDark    = Color(0xFF1E3A5F);

  // ─── AppBar (telas principais) ────────────────────────────────────────────
  static const Color appBarBg    = Color(0xFF1565C0);
  static const Color appBarDark  = Color(0xFF0D47A1);
}
