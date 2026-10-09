import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conecta_saude/core/widgets/delete_content_dialog.dart';

void main() {
  Future<void> open(WidgetTester tester, Future<void> Function() remove) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
      builder: (context) => TextButton(
        onPressed: () => showDeleteContentDialog(
          context: context, kind: 'canal', title: 'Equipe', onDelete: remove,
        ),
        child: const Text('Abrir'),
      ),
    ))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('cancelar não envia exclusão', (tester) async {
    var calls = 0;
    await open(tester, () async { calls++; });
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('aguarda API e bloqueia cliques duplicados', (tester) async {
    final pending = Completer<void>();
    var calls = 0;
    await open(tester, () { calls++; return pending.future; });
    await tester.tap(find.text('Excluir'));
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    expect(calls, 1);
    expect(find.byType(AlertDialog), findsOneWidget);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('falha mantém diálogo aberto e permite nova tentativa', (tester) async {
    var calls = 0;
    await open(tester, () async {
      calls++;
      if (calls == 1) throw Exception('Sem permissão.');
    });
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Sem permissão.'), findsOneWidget);
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
