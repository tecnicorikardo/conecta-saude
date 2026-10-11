import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conecta_saude/core/theme/app_theme.dart';
import 'package:conecta_saude/features/auth/presentation/pages/register_page.dart';
import 'package:conecta_saude/features/units/domain/entities/hospital_unit_entity.dart';
import 'package:conecta_saude/features/units/presentation/providers/units_provider.dart';
import 'package:conecta_saude/features/sectors/domain/entities/sector_entity.dart';
import 'package:conecta_saude/features/sectors/presentation/providers/sectors_provider.dart';

void main() {
  testWidgets(
      'cadastro em etapas valida, mantém dados e mostra nível 4 no tema escuro',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(overrides: [
      unitsProvider.overrideWith((ref) async =>
          [const HospitalUnitEntity(id: 'hospital', nome: 'Hospital Teste')]),
      sectorsProvider.overrideWith((ref) async => [
            const SectorEntity(
                id: 'sector', nome: 'Setor Teste', unitId: 'hospital')
          ]),
    ], child: MaterialApp(theme: AppTheme.dark, home: const RegisterPage())));
    await tester.pumpAndSettle();
    expect(find.text('Etapa 1 de 3 · Seus dados'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    expect(find.text('Informe seu nome completo.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Pessoa Teste');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'teste@example.invalid');
    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    expect(find.text('Etapa 2 de 3 · Vínculo profissional'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hospital Teste').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Setor Teste').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester
        .tap(find.text('Nível 4 — Equipe operacional / Assistencial').last);
    await tester.pumpAndSettle();
    final level =
        tester.widget<DropdownButton<int>>(find.byType(DropdownButton<int>));
    expect(level.style!.color, const Color(0xFF263238));
    expect(level.dropdownColor, Colors.white);
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../build/ui-preview/cadastro-nivel4.png'));
    }
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maqueiro(a)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    expect(find.text('Etapa 3 de 3 · Acesso e jornada'), findsOneWidget);
    expect(find.textContaining('Maqueiro(a) · Nível 4'), findsOneWidget);
    await tester.tap(find.text('Voltar à etapa anterior'));
    await tester.pumpAndSettle();
    expect(
        tester
            .state<FormFieldState<String>>(
                find.byType(DropdownButtonFormField<String>).last)
            .value,
        'Maqueiro(a)');
    // Trocar o nível invalida o cargo anterior.
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nível 3 — Supervisão / Enfermeiro').last);
    await tester.pumpAndSettle();
    expect(
        tester
            .state<FormFieldState<String>>(
                find.byType(DropdownButtonFormField<String>).last)
            .value,
        isNull);
    await tester.tap(find.text('Voltar à etapa anterior'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'Pessoa Teste');
    expect(tester.takeException(), isNull);
  });
}
