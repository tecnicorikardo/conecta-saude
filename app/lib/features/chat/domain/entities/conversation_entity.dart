import 'message_entity.dart';

class ConversationParticipant {
  final String id;
  final String nome;
  final String? fotoUrl;
  final String cargo;
  final String setorNome;
  final int hierarquiaNivel;
  final bool isAdmin;
  final String jornadaInicio;
  final String jornadaFim;
  final String jornadaDias;
  final bool emPlantaoExtra;
  final bool? emServico; // Status manual do backend

  const ConversationParticipant({
    required this.id,
    required this.nome,
    this.fotoUrl,
    required this.cargo,
    required this.setorNome,
    required this.hierarquiaNivel,
    this.isAdmin = false,
    this.jornadaInicio = '07:00',
    this.jornadaFim = '16:00',
    this.jornadaDias = 'seg,ter,qua,qui,sex',
    this.emPlantaoExtra = false,
    this.emServico,
  });

  bool get isCurrentlyWorking {
    // Usa o status manual do backend se disponível
    if (emServico != null) return emServico!;
    
    // Fallback para false se não houver informação
    return false;
  }

  ConversationParticipant copyWith({
    String? id,
    String? nome,
    String? fotoUrl,
    String? cargo,
    String? setorNome,
    int? hierarquiaNivel,
    bool? isAdmin,
    String? jornadaInicio,
    String? jornadaFim,
    String? jornadaDias,
    bool? emPlantaoExtra,
    bool? emServico,
  }) {
    return ConversationParticipant(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      cargo: cargo ?? this.cargo,
      setorNome: setorNome ?? this.setorNome,
      hierarquiaNivel: hierarquiaNivel ?? this.hierarquiaNivel,
      isAdmin: isAdmin ?? this.isAdmin,
      jornadaInicio: jornadaInicio ?? this.jornadaInicio,
      jornadaFim: jornadaFim ?? this.jornadaFim,
      jornadaDias: jornadaDias ?? this.jornadaDias,
      emPlantaoExtra: emPlantaoExtra ?? this.emPlantaoExtra,
      emServico: emServico ?? this.emServico,
    );
  }
}

class ConversationEntity {
  final String id;
  final String tipo;
  final String? nome;
  final String? descricao;
  final String? fotoUrl;
  final String? criadoPor;
  final bool autoExcluir24h;
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
    this.autoExcluir24h = true,
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

  ConversationParticipant? otherParticipant(String currentUserId) {
    if (isGroup) return null;
    return participantes.where((p) => p.id != currentUserId).firstOrNull ??
        (participantes.isNotEmpty ? participantes.first : null);
  }

  String displayName(String currentUserId) {
    if (isGroup) {
      return nome ?? 'Grupo';
    }
    final other = otherParticipant(currentUserId);
    return other?.nome.isNotEmpty == true ? other!.nome : 'Conversa';
  }

  String? displayPhoto(String currentUserId) {
    if (isGroup) return fotoUrl;
    final other = otherParticipant(currentUserId);
    return other?.fotoUrl;
  }

  String displaySubtitle(String currentUserId) {
    if (isGroup) {
      return '${participantes.length} participantes';
    }
    final other = otherParticipant(currentUserId);
    if (other == null) return '';
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
    bool? autoExcluir24h,
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
      autoExcluir24h: autoExcluir24h ?? this.autoExcluir24h,
      participantes: participantes ?? this.participantes,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}
