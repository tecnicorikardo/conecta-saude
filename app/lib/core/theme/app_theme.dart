import 'package:flutter/material.dart';
import 'app_theme_tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => susLight;

  static ThemeData get susLight {
    const tokens = AppThemeTokens.susLight;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: tokens.primary,
        brightness: Brightness.light,
        primary: tokens.primary,
        onPrimary: Colors.white,
        secondary: tokens.primaryDark,
        surface: tokens.surface,
        onSurface: tokens.textPrimary,
        error: tokens.critical,
      ),
      scaffoldBackgroundColor: tokens.background,
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: tokens.border, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.border,
        thickness: 1,
        space: 1,
      ),
      extensions: const [tokens],
    );
  }

  static ThemeData get dark {
    const tokens = AppThemeTokens.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: tokens.primaryDark,
        brightness: Brightness.dark,
        primary: tokens.primary,
        onPrimary: tokens.background,
        secondary: tokens.primaryDark,
        surface: tokens.surface,
        onSurface: tokens.textPrimary,
        error: tokens.critical,
      ),
      scaffoldBackgroundColor: tokens.background,
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.surface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: tokens.border, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.border,
        thickness: 1,
        space: 1,
      ),
      extensions: const [tokens],
    );
  }

  static ThemeData get lgbtq {
    const tokens = AppThemeTokens.lgbtq;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: tokens.primary,
        brightness: Brightness.light,
        primary: tokens.primary,
        onPrimary: Colors.white,
        secondary: tokens.primaryDark,
        surface: tokens.surface,
        onSurface: tokens.textPrimary,
        error: tokens.critical,
      ),
      scaffoldBackgroundColor: tokens.background,
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: tokens.border, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.border,
        thickness: 1,
        space: 1,
      ),
      extensions: const [tokens],
    );
  }

  static ThemeData get rosa {
    const tokens = AppThemeTokens.rosa;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: tokens.primary,
        brightness: Brightness.light,
        primary: tokens.primary,
        onPrimary: Colors.white,
        secondary: tokens.accent ?? const Color(0xFFC04B78),
        surface: tokens.surface,
        onSurface: tokens.textPrimary,
        error: tokens.critical,
      ),
      scaffoldBackgroundColor: tokens.background,
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: tokens.border, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.border,
        thickness: 1,
        space: 1,
      ),
      extensions: const [tokens],
    );
  }

  static ThemeData fromMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return dark;
      case AppThemeMode.lgbtq:
        return lgbtq;
      case AppThemeMode.rosa:
        return rosa;
      case AppThemeMode.susLight:
      case AppThemeMode.system:
        return susLight;
    }
  }
}
