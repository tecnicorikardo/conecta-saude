import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conecta_saude/core/services/http_service.dart';
import 'package:conecta_saude/core/auth/permissions_provider.dart';
import 'package:conecta_saude/core/theme/app_theme.dart';
import 'package:conecta_saude/features/chat/data/models/conversation_model.dart';
import 'package:conecta_saude/features/chat/data/repositories/conversation_repository.dart';
import 'package:conecta_saude/features/chat/presentation/pages/new_conversation_page.dart';
import 'package:conecta_saude/features/chat/presentation/providers/chat_provider.dart';

class GroupRepository extends ConversationRepository {
  GroupRepository() : super(HttpService.instance);
  @override
  Future<List<UserSummary>> listAvailableUsers(
          {String? search, String? setorId, String? cargo}) async =>
      List.generate(
          12,
          (i) => UserSummary(
              id: '$i',
              nome: 'Funcionário $i',
              cargo: 'Enfermeiro',
              setorId: 'cco',
              setorNome: 'CCO',
              hierarquiaNivel: 3,
              ativo: true,
              emServico: i.isEven));
}

void main() {
  for (final size in [const Size(640, 535), const Size(1280, 720)]) {
    testWidgets('Mouse rola e seleciona participantes no desktop $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ProviderScope(
          overrides: [
            conversationRepositoryProvider.overrideWithValue(GroupRepository()),
            currentUserIdProvider.overrideWithValue('self'),
            permissionsProvider.overrideWithValue(UserPermissions(null)),
          ],
          child: MaterialApp(
              theme: AppTheme.dark, home: const NewConversationPage())));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grupo'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final scroll = find.byKey(const ValueKey('group-form-scroll'));
      final state = tester.state<ScrollableState>(
          find.descendant(of: scroll, matching: find.byType(Scrollable)).first);
      await tester.sendEventToBinding(PointerScrollEvent(
          position: tester.getCenter(scroll),
          scrollDelta: const Offset(0, 2000)));
      await tester.pumpAndSettle();
      expect(state.position.pixels, greaterThan(0));
      expect(find.text('Funcionário 11').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Funcionário 11'));
      await tester.pumpAndSettle();
      expect(find.text('Criar Grupo (1)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
