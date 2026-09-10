import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/firebase_options.dart';
import 'core/routes/app_router.dart';
import 'core/routes/url_strategy.dart';
import 'core/services/http_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_provider.dart';
import 'core/theme/app_theme_tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Garante árvore semântica/acessibilidade no DOM Web (bot de testes, leitores de tela e formulários)
  if (kIsWeb) {
    WidgetsBinding.instance.ensureSemantics();
  }

  // URL limpa sem '#' para deep linking direto de notificações push
  configureAppUrlStrategy();

  // Inicializar suporte a formatação de data e hora pt_BR
  await initializeDateFormatting('pt_BR', null);

  // Orientação forçada: portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar transparente
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  // Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Pré-aquece o backend no Render preventivamente em background
  HttpService.instance.warmUp();

  // SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ConectaSaudeApp(),
    ),
  );
}

// Provider global para SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError(),
);

class ConectaSaudeApp extends ConsumerWidget {
  const ConectaSaudeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    final (theme, darkTheme, mode) = switch (themeMode) {
      AppThemeMode.susLight => (AppTheme.susLight, AppTheme.dark, ThemeMode.light),
      AppThemeMode.dark => (AppTheme.dark, AppTheme.dark, ThemeMode.dark),
      AppThemeMode.lgbtq => (AppTheme.lgbtq, AppTheme.dark, ThemeMode.light),
      AppThemeMode.rosa => (AppTheme.rosa, AppTheme.dark, ThemeMode.light),
      AppThemeMode.system => (AppTheme.susLight, AppTheme.dark, ThemeMode.system),
    };

    return MaterialApp.router(
      title: 'Conecta Saúde',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: mode,
      routerConfig: router,
    );
  }
}

