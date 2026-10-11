import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conecta_saude/core/auth/permissions_provider.dart';
import 'package:conecta_saude/core/theme/app_theme.dart';
import 'package:conecta_saude/core/theme/app_theme_tokens.dart';
import 'package:conecta_saude/features/reports/presentation/pages/reports_page.dart';
import 'package:conecta_saude/features/reports/presentation/providers/reports_provider.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
        'Ouvidoria e formulário respeitam tema ${dark ? "escuro" : "claro"}',
        (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final tokens = dark ? AppThemeTokens.dark : AppThemeTokens.susLight;
      await tester.pumpWidget(ProviderScope(
          overrides: [
            permissionsProvider.overrideWithValue(const UserPermissions(null)),
            myReportsProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: const ReportsPage())));
      await tester.pumpAndSettle();
      expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          tokens.background);
      expect(
          tester.widget<Card>(find.byType(Card).first).color, tokens.surface);
      await tester.tap(find.text('Nova Denúncia'));
      await tester.pumpAndSettle();
      final title = tester.widget<Text>(find.text('Denúncia 100% Anônima'));
      final privacyColor = title.style!.color!;
      expect(privacyColor.computeLuminance(),
          dark ? greaterThan(0.4) : lessThan(0.2));
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == tokens.surface),
          findsWidgets);
      if (const bool.fromEnvironment('CAPTURE_UI')) {
        await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
                '../build/ui-preview/denuncia-${dark ? "dark" : "light"}.png'));
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
