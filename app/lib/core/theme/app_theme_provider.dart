import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import 'app_theme_tokens.dart';

class AppThemeModeNotifier extends StateNotifier<AppThemeMode> {
  final SharedPreferences _prefs;
  static const _key = 'app_theme_mode';

  AppThemeModeNotifier(this._prefs) : super(_loadInitialTheme(_prefs));

  static AppThemeMode _loadInitialTheme(SharedPreferences prefs) {
    final saved = prefs.getString(_key);
    return AppThemeMode.fromString(saved);
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    await _prefs.setString(_key, mode.name);
  }
}

final appThemeModeProvider = StateNotifierProvider<AppThemeModeNotifier, AppThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppThemeModeNotifier(prefs);
});

/// Retorna os tokens de tema ativos com base no contexto ou no tema atual.
extension AppThemeContextExtension on BuildContext {
  AppThemeTokens get appTokens {
    return Theme.of(this).extension<AppThemeTokens>() ?? AppThemeTokens.susLight;
  }
}
