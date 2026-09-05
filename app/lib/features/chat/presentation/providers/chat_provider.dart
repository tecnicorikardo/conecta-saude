import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/conversation_entity.dart';

// ─── Provider do usuário atual (mock até integração real) ─────────────────────
final currentUserIdProvider = Provider<String>((_) => 'user-me');
final currentUserNomeProvider = Provider<String>((_) => 'Você');

// ─── Dados mock para desenvolvimento ─────────────────────────────────────────
final _mockParticipants = [
  const ConversationParticipant(
    id: 'user-ana',
    nome: 'Ana Paula Ferreira',
    cargo: 'Coordenadora de Enfermagem',
    setorNome: 'Enfermagem',
    hierarquiaNivel: 2,
  ),
  const ConversationParticipant(
    id: 'user-marcos',
    nome: 'Marcos Antônio Silva',
    cargo: 'Supervisor de Enfermagem',
    setorNome: 'Enfermagem',
    hierarquiaNivel: 3,
  ),
  const ConversationParticipant(
    id: 'user-bruna',
    nome: 'Bruna Oliveira Souza',
    cargo: 'Técnica de Enfermagem',
    setorNome: 'Enfermagem',
    hierarquiaNivel: 4,
  ),
  const ConversationParticipant(
    id: 'user-roberto',
    nome: 'Roberto Alves Costa',
    cargo: 'Coordenador de Manutenção',
    setorNome: 'Manutenção',
    hierarquiaNivel: 2,
  ),
];

const _mockMe = ConversationParticipant(
  id: 'user-me',
  nome: 'Você',
  cargo: 'Supervisor',
  setorNome: 'Enfermagem',
  hierarquiaNivel: 3,
);

// ─── Lista de conversas ───────────────────────────────────────────────────────
final conversationsProvider = StateNotifierProvider<ConversationsNotifier,
    AsyncValue<List<ConversationEntity>>>((ref) {
  return ConversationsNotifier();
});

class ConversationsNotifier
    extends StateNotifier<AsyncValue<List<ConversationEntity>>> {
  ConversationsNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  void _load() {
    final now = DateTime.now();
    state = AsyncValue.data([
      ConversationEntity(
        id: 'conv-1',
        tipo: 'individual',
        participantes: [_mockMe, _mockParticipants[0]],
        lastMessage: MessageEntity(
          id: 'msg-0',
          conversationId: 'conv-1',
          texto: 'Precisamos revisar a escala da próxima semana.',
          remetente: MessageSender(
            id: _mockParticipants[0].id,
            nome: _mockParticipants[0].nome,
            cargo: _mockParticipants[0].cargo,
          ),
          criadoEm: now.subtract(const Duration(minutes: 5)),
          status: MessageStatus.read,
        ),
        unreadCount: 2,
        atualizadoEm: now.subtract(const Duration(minutes: 5)),
      ),
      ConversationEntity(
        id: 'conv-2',
        tipo: 'individual',
        participantes: [_mockMe, _mockParticipants[1]],
        lastMessage: MessageEntity(
          id: 'msg-1',
          conversationId: 'conv-2',
          texto: 'Certo, vou verificar agora.',
          remetente: const MessageSender(
            id: 'user-me',
            nome: 'Você',
            cargo: 'Supervisor',
          ),
          criadoEm: now.subtract(const Duration(hours: 1)),
          status: MessageStatus.read,
        ),
        unreadCount: 0,
        atualizadoEm: now.subtract(const Duration(hours: 1)),
      ),
      ConversationEntity(
        id: 'conv-3',
        tipo: 'grupo',
        nome: 'Equipe Enfermagem',
        participantes: [_mockMe, ..._mockParticipants.take(3)],
        lastMessage: MessageEntity(
          id: 'msg-2',
          conversationId: 'conv-3',
          texto: 'Reunião amanhã às 14h no auditório.',
          remetente: MessageSender(
            id: _mockParticipants[0].id,
            nome: _mockParticipants[0].nome,
            cargo: _mockParticipants[0].cargo,
          ),
          criadoEm: now.subtract(const Duration(hours: 3)),
          status: MessageStatus.delivered,
        ),
        unreadCount: 5,
        atualizadoEm: now.subtract(const Duration(hours: 3)),
      ),
      ConversationEntity(
        id: 'conv-4',
        tipo: 'individual',
        participantes: [_mockMe, _mockParticipants[3]],
        lastMessage: MessageEntity(
          id: 'msg-3',
          conversationId: 'conv-4',
          texto: 'O equipamento da sala 3 foi consertado.',
          remetente: MessageSender(
            id: _mockParticipants[3].id,
            nome: _mockParticipants[3].nome,
            cargo: _mockParticipants[3].cargo,
          ),
          criadoEm: now.subtract(const Duration(days: 1)),
          status: MessageStatus.read,
        ),
        unreadCount: 0,
        atualizadoEm: now.subtract(const Duration(days: 1)),
      ),
    ]);
  }
}

// ─── Mensagens de uma conversa ────────────────────────────────────────────────
final messagesProvider = StateNotifierProvider.family<MessagesNotifier,
    AsyncValue<List<MessageEntity>>, String>((ref, conversationId) {
  return MessagesNotifier(conversationId);
});

class MessagesNotifier
    extends StateNotifier<AsyncValue<List<MessageEntity>>> {
  final String conversationId;
  final _uuid = const Uuid();

  MessagesNotifier(this.conversationId) : super(const AsyncValue.loading()) {
    _load();
  }

  void _load() {
    final now = DateTime.now();
    final ana = MessageSender(
      id: _mockParticipants[0].id,
      nome: _mockParticipants[0].nome,
      cargo: _mockParticipants[0].cargo,
    );
    const me = MessageSender(
      id: 'user-me',
      nome: 'Você',
      cargo: 'Supervisor',
    );

    state = AsyncValue.data([
      MessageEntity(
        id: 'msg-1',
        conversationId: conversationId,
        texto: 'Bom dia! Tudo bem?',
        remetente: ana,
        criadoEm: now.subtract(const Duration(hours: 2, minutes: 10)),
        status: MessageStatus.read,
      ),
      MessageEntity(
        id: 'msg-2',
        conversationId: conversationId,
        texto: 'Bom dia! Tudo ótimo, obrigado.',
        remetente: me,
        criadoEm: now.subtract(const Duration(hours: 2, minutes: 8)),
        status: MessageStatus.read,
      ),
      MessageEntity(
        id: 'msg-3',
        conversationId: conversationId,
        texto: 'Precisamos revisar a escala da próxima semana. Você tem disponibilidade amanhã às 14h?',
        remetente: ana,
        criadoEm: now.subtract(const Duration(hours: 2)),
        status: MessageStatus.read,
      ),
      MessageEntity(
        id: 'msg-4',
        conversationId: conversationId,
        texto: 'Sim, estarei disponível. Pode confirmar a sala?',
        remetente: me,
        criadoEm: now.subtract(const Duration(hours: 1, minutes: 55)),
        status: MessageStatus.read,
      ),
      MessageEntity(
        id: 'msg-5',
        conversationId: conversationId,
        texto: 'Sala de reuniões do 2º andar. Vou enviar o convite agora.',
        remetente: ana,
        criadoEm: now.subtract(const Duration(hours: 1, minutes: 50)),
        status: MessageStatus.read,
      ),
      MessageEntity(
        id: 'msg-6',
        conversationId: conversationId,
        texto: 'Perfeito! Até amanhã.',
        remetente: me,
        criadoEm: now.subtract(const Duration(minutes: 45)),
        status: MessageStatus.read,
      ),
      MessageEntity(
        id: 'msg-7',
        conversationId: conversationId,
        texto: 'Precisamos revisar a escala da próxima semana.',
        remetente: ana,
        criadoEm: now.subtract(const Duration(minutes: 5)),
        status: MessageStatus.delivered,
      ),
    ]);
  }

  /// Envia uma mensagem de texto
  void sendTextMessage(String texto) {
    if (texto.trim().isEmpty) return;
    final current = state.value ?? [];
    final msg = MessageEntity(
      id: _uuid.v4(),
      conversationId: conversationId,
      texto: texto.trim(),
      remetente: const MessageSender(
        id: 'user-me',
        nome: 'Você',
        cargo: 'Supervisor',
      ),
      criadoEm: DateTime.now(),
      status: MessageStatus.sending,
    );
    state = AsyncValue.data([...current, msg]);

    // Simular confirmação de envio após 500ms
    Future.delayed(const Duration(milliseconds: 500), () {
      _updateMessageStatus(msg.id, MessageStatus.sent);
    });
    // Simular entregue após 1s
    Future.delayed(const Duration(seconds: 1), () {
      _updateMessageStatus(msg.id, MessageStatus.delivered);
    });
  }

  /// Envia mensagem de áudio
  void sendAudioMessage(String path, int durationSeconds) {
    final current = state.value ?? [];
    final msg = MessageEntity(
      id: _uuid.v4(),
      conversationId: conversationId,
      texto: '🎤 Áudio',
      tipo: MessageType.audio,
      remetente: const MessageSender(
        id: 'user-me',
        nome: 'Você',
        cargo: 'Supervisor',
      ),
      criadoEm: DateTime.now(),
      status: MessageStatus.sending,
      audioDuration: durationSeconds,
      audioPath: path,
    );
    state = AsyncValue.data([...current, msg]);
    Future.delayed(const Duration(milliseconds: 500), () {
      _updateMessageStatus(msg.id, MessageStatus.sent);
    });
  }

  /// Edita uma mensagem (apenas dentro da janela de 5 min)
  void editMessage(String messageId, String novoTexto) {
    final current = state.value ?? [];
    state = AsyncValue.data(current.map((m) {
      if (m.id == messageId) {
        return m.copyWith(
          texto: novoTexto,
          editado: true,
          editadoEm: DateTime.now(),
        );
      }
      return m;
    }).toList());
  }

  /// Exclusão lógica
  void deleteMessage(String messageId) {
    final current = state.value ?? [];
    state = AsyncValue.data(current.map((m) {
      if (m.id == messageId) return m.copyWith(excluido: true);
      return m;
    }).toList());
  }

  void _updateMessageStatus(String messageId, MessageStatus status) {
    if (!mounted) return;
    final current = state.value ?? [];
    state = AsyncValue.data(current.map((m) {
      if (m.id == messageId) return m.copyWith(status: status);
      return m;
    }).toList());
  }
}
