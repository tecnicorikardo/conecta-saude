import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conecta_saude/core/theme/app_theme.dart';
import 'package:conecta_saude/features/auth/domain/entities/user_entity.dart';
import 'package:conecta_saude/features/auth/domain/repositories/auth_repository.dart';
import 'package:conecta_saude/features/auth/presentation/providers/auth_provider.dart';
import 'package:conecta_saude/features/emergency/domain/entities/emergency_entity.dart';
import 'package:conecta_saude/features/emergency/domain/repositories/emergency_repository.dart';
import 'package:conecta_saude/features/emergency/data/repositories/emergency_repository_impl.dart';
import 'package:conecta_saude/features/emergency/presentation/pages/emergency_page.dart';

class NoAuth implements AuthRepository {
  @override
  Stream<UserEntity?> get authStateChanges => Stream.value(null);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class EmergencyResponse implements EmergencyRepository {
  bool fail = false;
  EmergencyAlertEntity? active;
  Completer<EmergencyAlertEntity?>? pending;
  @override
  Future<EmergencyAlertEntity?> getActiveEmergency() async {
    if (fail) throw Exception('offline');
    return pending?.future ?? Future.value(active);
  }

  @override
  Future<List<EmergencyAlertEntity>> getEmergencyHistory() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<void> open(WidgetTester tester, EmergencyResponse repo) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(overrides: [
      authRepositoryProvider.overrideWithValue(NoAuth()),
      emergencyRepositoryProvider.overrideWithValue(repo),
    ], child: MaterialApp(theme: AppTheme.dark, home: const EmergencyPage())));
    await tester.pump();
  }

  testWidgets(
      'Offline mostra status desconhecido e atualização recupera consulta',
      (tester) async {
    final repo = EmergencyResponse()..fail = true;
    await open(tester, repo);
    expect(find.text('Unidade em Estado Normal'), findsNothing);
    expect(find.text('Status de emergência não confirmado.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Unidade em Estado Normal'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'Falha de atualização preserva o último alerta e informa falta de confirmação',
      (tester) async {
    final repo = EmergencyResponse()
      ..active = EmergencyAlertEntity(
          id: 'alert',
          tipo: EmergencyType.geral,
          titulo: 'Alerta de teste',
          localizacao: 'Setor de teste',
          status: 'ativo',
          criadoEm: DateTime(2026),
          criadorNome: 'Teste',
          criadorCargo: 'Enfermeiro',
          criadorSetor: 'Setor');
    await open(tester, repo);
    expect(find.text('Setor de teste'), findsOneWidget);
    repo.fail = true;
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(find.text('Setor de teste'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.text('Unidade em Estado Normal'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
      'Consulta pendente não afirma estado normal e fechamento não gera erro',
      (tester) async {
    final pending = Completer<EmergencyAlertEntity?>();
    await open(tester, EmergencyResponse()..pending = pending);
    expect(find.text('Consultando status de emergência…'), findsOneWidget);
    expect(find.text('Unidade em Estado Normal'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(null);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
