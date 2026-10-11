import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conecta_saude/core/auth/permissions_provider.dart';
import 'package:conecta_saude/core/services/http_service.dart';
import 'package:conecta_saude/core/theme/app_theme.dart';
import 'package:conecta_saude/features/reports/data/repositories/reports_repository.dart';
import 'package:conecta_saude/features/reports/presentation/pages/reports_page.dart';
import 'package:conecta_saude/features/reports/presentation/providers/reports_provider.dart';

class FakeReportsRepository extends ReportsRepository {
  FakeReportsRepository() : super(HttpService.instance);
  int calls = 0;
  bool fail = false;
  String reportId = '1c5017ec-4800-4c54-8ce4-90e44c5a1525';
  Completer<String>? pending;
  @override
  Future<String> createReport(
      {required String motivo,
      required String descricao,
      String? titulo,
      String? reportedUserId,
      String? messageId,
      bool anonimo = false}) async {
    calls++;
    if (fail) {
      throw Exception('A descrição deve ter no máximo 2000 caracteres.');
    }
    return pending?.future ?? Future.value(reportId);
  }
}

void main() {
  Future<void> open(WidgetTester tester, FakeReportsRepository repo) async {
    tester.view.physicalSize = const Size(900, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(overrides: [
      permissionsProvider.overrideWithValue(const UserPermissions(null)),
      myReportsProvider.overrideWith((ref) async => []),
      allReportsProvider.overrideWith((ref, status) async => []),
      reportsRepositoryProvider.overrideWithValue(repo),
    ], child: MaterialApp(theme: AppTheme.dark, home: const ReportsPage())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nova Denúncia'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField).last, 'Relato de teste sem dados pessoais.');
    await tester.ensureVisible(find.text('Enviar Manifestação'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'sucesso fecha formulário e mostra protocolo usando contexto da página',
      (tester) async {
    final repo = FakeReportsRepository();
    await open(tester, repo);
    await tester.tap(find.text('Enviar Manifestação'));
    await tester.pumpAndSettle();
    expect(repo.calls, 1);
    expect(find.text('Manifestação Registrada'), findsOneWidget);
    expect(find.textContaining('1C5017EC'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('protocolo com ID curto não quebra o sucesso', (tester) async {
    final repo = FakeReportsRepository()..reportId = 'abc';
    await open(tester, repo);
    await tester.tap(find.text('Enviar Manifestação'));
    await tester.pumpAndSettle();
    expect(find.text('Manifestação Registrada'), findsOneWidget);
    expect(find.textContaining('-ABC'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'falha aparece no formulário, preserva relato e permite tentar novamente',
      (tester) async {
    final repo = FakeReportsRepository()..fail = true;
    await open(tester, repo);
    await tester.tap(find.text('Enviar Manifestação'));
    await tester.pumpAndSettle();
    expect(find.text('A descrição deve ter no máximo 2000 caracteres.'),
        findsOneWidget);
    expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        'Relato de teste sem dados pessoais.');
    repo.fail = false;
    await tester.ensureVisible(find.text('Enviar Manifestação'));
    await tester.tap(find.text('Enviar Manifestação'));
    await tester.pumpAndSettle();
    expect(repo.calls, 2);
    expect(find.text('Manifestação Registrada'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
