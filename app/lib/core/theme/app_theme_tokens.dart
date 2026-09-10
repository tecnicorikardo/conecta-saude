import 'package:flutter/material.dart';

enum AppThemeMode {
  susLight,
  dark,
  lgbtq,
  rosa,
  system;

  String get label {
    switch (this) {
      case AppThemeMode.susLight:
        return 'SUS Claro';
      case AppThemeMode.dark:
        return 'Escuro';
      case AppThemeMode.lgbtq:
        return 'LGBTQI+ Sutil';
      case AppThemeMode.rosa:
        return 'Rosa Institucional';
      case AppThemeMode.system:
        return 'Seguir Sistema';
    }
  }

  String get description {
    switch (this) {
      case AppThemeMode.susLight:
        return 'Padrão institucional do SUS, superfícies limpas e alto contraste.';
      case AppThemeMode.dark:
        return 'Azul-marinho hospitalar e grafite para conforto em pouca luz.';
      case AppThemeMode.lgbtq:
        return 'Identidade inclusiva e acolhedora com acento linear sutil.';
      case AppThemeMode.rosa:
        return 'Acentos em rosa e magenta sóbrios com azul SUS funcional.';
      case AppThemeMode.system:
        return 'Alterna automaticamente conforme o tema do seu dispositivo.';
    }
  }

  static AppThemeMode fromString(String? val) {
    switch (val) {
      case 'dark':
        return AppThemeMode.dark;
      case 'lgbtq':
        return AppThemeMode.lgbtq;
      case 'rosa':
        return AppThemeMode.rosa;
      case 'system':
        return AppThemeMode.system;
      case 'susLight':
      default:
        return AppThemeMode.susLight;
    }
  }
}

class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  final AppThemeMode mode;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color primaryDark;
  final Color primarySoft;
  final Color critical;
  final Color warning;
  final Color success;
  final List<Color> identityRainbow;
  final Color? accent;
  final Color? accentSoft;

  const AppThemeTokens({
    required this.mode,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.primaryDark,
    required this.primarySoft,
    required this.critical,
    required this.warning,
    required this.success,
    this.identityRainbow = const [],
    this.accent,
    this.accentSoft,
  });

  bool get isDark => mode == AppThemeMode.dark;
  bool get isLgbtq => mode == AppThemeMode.lgbtq;
  bool get isRosa => mode == AppThemeMode.rosa;

  /// Retorna a cor de destaque principal de acordo com o tema selecionado
  Color get themeAccentColor => accent ?? primary;

  /// Retorna o fundo suave para contêineres de ícones, badges e chips
  Color get iconContainerColor => accentSoft ?? surfaceMuted;

  /// Constrói a faixa lateral de 3.5px para identificação de tema nos cards
  Widget buildVerticalStripe({double width = 3.5, Color? overrideColor}) {
    if (overrideColor != null) {
      return Container(width: width, color: overrideColor);
    }
    if (identityRainbow.isNotEmpty) {
      return SizedBox(
        width: width,
        child: Column(
          children: identityRainbow
              .map((c) => Expanded(child: Container(color: c)))
              .toList(),
        ),
      );
    }
    return Container(width: width, color: themeAccentColor);
  }

  /// Constrói a faixa horizontal fina para cabeçalhos ou bordas superiores de cards
  Widget buildHorizontalAccent({double height = 2.5}) {
    if (identityRainbow.isNotEmpty) {
      return SizedBox(
        height: height,
        child: Row(
          children: identityRainbow
              .map((c) => Expanded(child: Container(color: c)))
              .toList(),
        ),
      );
    }
    if (accent != null) {
      return Container(height: height, color: accent);
    }
    return const SizedBox.shrink();
  }

  // ─── Preset: SUS Claro ──────────────────────────────────────────────────────
  static const susLight = AppThemeTokens(
    mode: AppThemeMode.susLight,
    background: Color(0xFFF6F8FA),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEAF3FB),
    border: Color(0xFFD8E0E8),
    textPrimary: Color(0xFF0B1C2E),
    textSecondary: Color(0xFF5C6B7A),
    primary: Color(0xFF1565C0),
    primaryDark: Color(0xFF0B3D6E),
    primarySoft: Color(0xFFEAF3FB),
    critical: Color(0xFFC62828),
    warning: Color(0xFFD9822B),
    success: Color(0xFF218739),
  );

  // ─── Preset: Escuro ─────────────────────────────────────────────────────────
  static const dark = AppThemeTokens(
    mode: AppThemeMode.dark,
    background: Color(0xFF081522),
    surface: Color(0xFF0F2438),
    surfaceMuted: Color(0xFF143450),
    border: Color(0xFF2A455D),
    textPrimary: Color(0xFFF5F9FC),
    textSecondary: Color(0xFFB9C7D4),
    primary: Color(0xFF42A5F5),
    primaryDark: Color(0xFF1565C0),
    primarySoft: Color(0xFF173F62),
    critical: Color(0xFFFF6B5E),
    warning: Color(0xFFF2B45B),
    success: Color(0xFF55C878),
  );

  // ─── Preset: LGBTQI+ Sutil ──────────────────────────────────────────────────
  static const lgbtq = AppThemeTokens(
    mode: AppThemeMode.lgbtq,
    background: Color(0xFFF6F8FA),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF1F5FA),
    border: Color(0xFFD8E0E8),
    textPrimary: Color(0xFF0B1C2E),
    textSecondary: Color(0xFF5C6B7A),
    primary: Color(0xFF1565C0),
    primaryDark: Color(0xFF0B3D6E),
    primarySoft: Color(0xFFEAF3FB),
    critical: Color(0xFFC62828),
    warning: Color(0xFFD9822B),
    success: Color(0xFF218739),
    identityRainbow: [
      Color(0xFFE85D75), // Vermelho suave
      Color(0xFFE99A45), // Laranja suave
      Color(0xFFD8B52C), // Amarelo suave
      Color(0xFF4C9B6B), // Verde suave
      Color(0xFF3D7CC9), // Azul suave
      Color(0xFF7657A6), // Violeta suave
    ],
  );

  // ─── Preset: Rosa Institucional ─────────────────────────────────────────────
  static const rosa = AppThemeTokens(
    mode: AppThemeMode.rosa,
    background: Color(0xFFF8F7F9),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFFCEEF4),
    border: Color(0xFFE4D6DF),
    textPrimary: Color(0xFF241A26),
    textSecondary: Color(0xFF6D5D6B),
    primary: Color(0xFF1565C0),
    primaryDark: Color(0xFF0B3D6E),
    primarySoft: Color(0xFFEAF3FB),
    critical: Color(0xFFC62828),
    warning: Color(0xFFD9822B),
    success: Color(0xFF218739),
    accent: Color(0xFFC04B78),
    accentSoft: Color(0xFFFCEEF4),
  );

  @override
  AppThemeTokens copyWith({
    AppThemeMode? mode,
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? primary,
    Color? primaryDark,
    Color? primarySoft,
    Color? critical,
    Color? warning,
    Color? success,
    List<Color>? identityRainbow,
    Color? accent,
    Color? accentSoft,
  }) {
    return AppThemeTokens(
      mode: mode ?? this.mode,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      primarySoft: primarySoft ?? this.primarySoft,
      critical: critical ?? this.critical,
      warning: warning ?? this.warning,
      success: success ?? this.success,
      identityRainbow: identityRainbow ?? this.identityRainbow,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    return AppThemeTokens(
      mode: t < 0.5 ? mode : other.mode,
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t) ?? surfaceMuted,
      border: Color.lerp(border, other.border, t) ?? border,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t) ?? primaryDark,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t) ?? primarySoft,
      critical: Color.lerp(critical, other.critical, t) ?? critical,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      success: Color.lerp(success, other.success, t) ?? success,
      identityRainbow: other.identityRainbow.isNotEmpty ? other.identityRainbow : identityRainbow,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t) ?? accentSoft,
    );
  }
}
