import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:conecta_saude/features/channels/data/repositories/channels_repository.dart';
import 'package:conecta_saude/features/channels/domain/entities/channel_entity.dart';
import 'package:conecta_saude/features/channels/presentation/providers/channels_provider.dart';

class PendingChannels implements ChannelsRepository {
  final pending = Completer<List<ChannelMessageEntity>>();
  final posting = Completer<ChannelMessageEntity>();
  @override
  Future<List<ChannelMessageEntity>> listChannelMessages(String id) =>
      pending.future;
  @override
  Future<ChannelMessageEntity> postChannelMessage(String id, String text) =>
      posting.future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final fail in [false, true]) {
    test('fechar canal durante carregamento, erro=$fail', () async {
      final repo = PendingChannels();
      final notifier = ChannelMessagesNotifier(repo, 'test');
      notifier.dispose();
      if (fail) {
        repo.pending.completeError(Exception('offline'));
      } else {
        repo.pending.complete([]);
      }
      await Future<void>.delayed(Duration.zero);
    });
  }
  test('falha de envio após fechamento não escreve state', () async {
    final repo = PendingChannels();
    final notifier = ChannelMessagesNotifier(repo, 'test');
    repo.pending.complete([]);
    await Future<void>.delayed(Duration.zero);
    final result = notifier.postMessage('Teste');
    notifier.dispose();
    repo.posting.completeError(Exception('offline'));
    expect(await result, isFalse);
  });
}
