import 'message_entity.dart';

class ConversationParticipant {
  final String id;
  final String nome;
  final String? fotoUrl;
  final String cargo;
  final String setorNome;
  final int hierarquiaNivel;
  final bool isAdmin;

  const ConversationParticipant({
    required this.id,
    required this.nome,
    this.fotoUrl,
    required this.cargo,
    required this.setorNome,
    required this.hierarquiaNivel,
    this.isAdmin = false,
  });
}

class ConversationEntity {
  final String id;
  final String tipo;
  final String? nome;
  final String? descricao;
  final String? fotoUrl;
  final String? criadoPor;
  final List<ConversationParticipant> participantes;
  final MessageEntity? lastMessage;
  final int unreadCount;
  final DateTime atualizadoEm;

  const ConversationEntity({
    required this.id,
    required this.tipo,
    this.nome,
    this.descricao,
    this.fotoUrl,
    this.criadoPor,
    required this.participantes,
    this.lastMessage,
    required this.unreadCount,
    required this.atualizadoEm,
  });

  bool get isGroup => tipo == 'grupo' || tipo == 'canal' || tipo == 'setor';

  bool isCurrentUserAdmin(String currentUserId) {
    if (criadoPor == currentUserId) return true;
    final member = participantes.where((p) => p.id == currentUserId).firstOrNull;
    return member?.isAdmin ?? false;
  }

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
    if (isGroup) return fotoUrl;
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
      return '${participantes.length} participantes';
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
      return '${other.cargo} • ${other.setorNome}';
    }
    return other.cargo.isNotEmpty ? other.cargo : other.setorNome;
  }

  ConversationEntity copyWith({
    String? id,
    String? tipo,
    String? nome,
    String? descricao,
    String? fotoUrl,
    String? criadoPor,
    List<ConversationParticipant>? participantes,
    MessageEntity? lastMessage,
    int? unreadCount,
    DateTime? atualizadoEm,
  }) {
    return ConversationEntity(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      criadoPor: criadoPor ?? this.criadoPor,
      participantes: participantes ?? this.participantes,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}
