import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conecta_saude/features/chat/domain/entities/message_entity.dart';
import 'package:conecta_saude/features/chat/presentation/widgets/message_bubble.dart';

void main() {
  testWidgets('mensagem com falha permite tentar novamente', (tester) async {
    var retries = 0;
    final message = MessageEntity(
      id: 'pending', conversationId: 'conversation', texto: 'Bom dia',
      remetente: const MessageSender(id: 'sender', nome: 'Demo', cargo: 'Equipe'),
      criadoEm: DateTime(2026, 9, 9, 10), status: MessageStatus.error,
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MessageBubble(
      message: message, isOwn: true, onRetry: () => retries++,
    ))));
    expect(find.text('Bom dia'), findsOneWidget);
    await tester.tap(find.text('Falha no envio · Tentar novamente'));
    expect(retries, 1);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MessageBubble(
      message: message.copyWith(status: MessageStatus.sent), isOwn: true,
    ))));
    expect(find.text('Falha no envio · Tentar novamente'), findsNothing);
  });
}
