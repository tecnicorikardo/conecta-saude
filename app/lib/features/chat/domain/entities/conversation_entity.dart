import 'message_entity.dart';

class ConversationParticipant {
  final String id;
  final String nome;
  final String? fotoUrl;
  final String cargo;
  final String setorNome;
  final int hierarquiaNivel;

  const ConversationParticipant({
    required this.id,
    required this.nome,
    this.fotoUrl,
    required this.cargo,
    required this.setorNome,
    required this.hierarquiaNivel,
  });
}

class ConversationEntity {
  final String id;
  final String tipo;
  final String? nome;
  final List<ConversationParticipant> participantes;
  final MessageEntity? lastMessage;
  final int unreadCount;
  final DateTime atualizadoEm;

  const ConversationEntity({
    required this.id,
    required this.tipo,
    this.nome,
    required this.participantes,
    this.lastMessage,
    required this.unreadCount,
    required this.atualizadoEm,
  });

  bool get isGroup => tipo == 'grupo' || tipo == 'canal';

  String displayName(String currentUserId) {
    if (isGroup) {
      return nome ?? 'Grupo';
    }
    final other = participantes.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participantes.isNotEmpty
          ? participantes.first
          : const ConversationParticipant(
              id: '',
              nome: 'Conversa',
              cargo: '',
              setorNome: '',
              hierarquiaNivel: 4,
            ),
    );
    return other.nome;
  }

  String? displayPhoto(String currentUserId) {
    if (isGroup) return null;
    final other = participantes.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participantes.isNotEmpty
          ? participantes.first
          : const ConversationParticipant(
              id: '',
              nome: '',
              cargo: '',
              setorNome: '',
              hierarquiaNivel: 4,
            ),
    );
    return other.fotoUrl;
  }

  String displaySubtitle(String currentUserId) {
    if (isGroup) {
      return ' participantes';
    }
    final other = participantes.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participantes.isNotEmpty
          ? participantes.first
          : const ConversationParticipant(
              id: '',
              nome: '',
              cargo: '',
              setorNome: '',
              hierarquiaNivel: 4,
            ),
    );
    if (other.cargo.isNotEmpty && other.setorNome.isNotEmpty) {
      return ' • ';
    }
    return other.cargo.isNotEmpty ? other.cargo : other.setorNome;
  }

  ConversationEntity copyWith({
    String? id,
    String? tipo,
    String? nome,
    List<ConversationParticipant>? participantes,
    MessageEntity? lastMessage,
    int? unreadCount,
    DateTime? atualizadoEm,
  }) {
    return ConversationEntity(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      nome: nome ?? this.nome,
      participantes: participantes ?? this.participantes,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}
