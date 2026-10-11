import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:conecta_saude/features/chat/data/conversation_history_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
      'Limpar a conta A não oculta o histórico da conta B no mesmo dispositivo',
      () async {
    final store = ConversationHistoryStore();
    final at = DateTime(2026, 10, 11);
    await store.clear('account-a', 'conversation', at);
    expect(store.cached('account-a', 'conversation'), at);
    expect(store.cached('account-b', 'conversation'), isNull);
    expect(await store.read('account-b', 'conversation'), isNull);
    expect(
        await ConversationHistoryStore().read('account-a', 'conversation'), at);
  });
  test('Limpar uma conversa preserva as demais', () async {
    final store = ConversationHistoryStore();
    await store.clear('account', 'one', DateTime(2026));
    expect(await store.read('account', 'two'), isNull);
  });
  test('Marcador antigo sem identidade não é aplicado a outras contas',
      () async {
    SharedPreferences.setMockInitialValues(
        {'chat_cleared_at_conversation': 1234});
    expect(await ConversationHistoryStore().read('account', 'conversation'),
        isNull);
  });
}
