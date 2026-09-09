import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';

/// Converte JSON da API → ConversationEntity
class ConversationModel {
  static ConversationEntity fromJson(Map<String, dynamic> json) {
    final members = (json['members'] as List? ?? [])
        .map((m) => _participantFromJson(m as Map<String, dynamic>))
        .toList();

    final lastMsgJson = json['lastMessage'] as Map<String, dynamic>?;

    return ConversationEntity(
      id: json['id'] as String,
      tipo: json['tipo'] as String? ?? 'individual',
      nome: json['nome'] as String?,
      descricao: json['descricao'] as String?,
      fotoUrl: json['fotoUrl'] as String?,
      criadoPor: json['criadoPor'] as String?,
      autoExcluir24h: json['autoExcluir24h'] as bool? ?? false,
      participantes: members,
      lastMessage: lastMsgJson != null ? _lastMessageFromJson(lastMsgJson) : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      atualizadoEm: DateTime.tryParse(json['atualizadoEm'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  static ConversationParticipant _participantFromJson(Map<String, dynamic> j) {
    final user = j['user'] is Map<String, dynamic> ? j['user'] as Map<String, dynamic> : j;
    final setor = user['setor'] is Map<String, dynamic> ? user['setor'] as Map<String, dynamic> : null;

    return ConversationParticipant(
      id: user['id'] as String? ?? j['userId'] as String? ?? j['id'] as String? ?? '',
      nome: user['nome'] as String? ?? j['nome'] as String? ?? '',
      fotoUrl: user['fotoUrl'] as String? ?? j['fotoUrl'] as String?,
      cargo: user['cargo'] as String? ?? j['cargo'] as String? ?? '',
      setorNome: setor?['nome'] as String? ?? user['setorNome'] as String? ?? j['setorNome'] as String? ?? '',
      hierarquiaNivel: user['hierarquiaNivel'] as int? ?? j['hierarquiaNivel'] as int? ?? 4,
      isAdmin: j['isAdmin'] as bool? ?? user['isAdmin'] as bool? ?? false,
    );
  }

  static MessageEntity _lastMessageFromJson(Map<String, dynamic> j) {
    final remetente = j['remetente'] as Map<String, dynamic>? ?? {};
    return MessageEntity(
      id: j['id'] as String? ?? '',
      conversationId: '',
      texto: (j['excluido'] == true) ? '' : (j['texto'] as String? ?? ''),
      remetente: MessageSender(
        id: remetente['id'] as String? ?? '',
        nome: remetente['nome'] as String? ?? '',
        cargo: remetente['cargo'] as String? ?? '',
      ),
      criadoEm: DateTime.tryParse(j['criadoEm'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      excluido: j['excluido'] as bool? ?? false,
      status: MessageStatus.delivered,
    );
  }
}

/// Converte JSON da API → MessageEntity
class MessageModel {
  static MessageEntity fromJson(Map<String, dynamic> json, String conversationId) {
    final remetente = json['remetente'] as Map<String, dynamic>? ?? {};
    return MessageEntity(
      id: json['id'] as String? ?? '',
      conversationId: conversationId,
      texto: (json['excluido'] == true)
          ? ''
          : (json['texto'] as String? ?? ''),
      tipo: json['tipo'] == 'audio' ? MessageType.audio : MessageType.text,
      remetente: MessageSender(
        id: remetente['id'] as String? ?? '',
        nome: remetente['nome'] as String? ?? '',
        cargo: remetente['cargo'] as String? ?? '',
        fotoUrl: remetente['fotoUrl'] as String?,
      ),
      criadoEm: DateTime.tryParse(json['criadoEm'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      editadoEm: json['editadoEm'] != null
          ? DateTime.tryParse(json['editadoEm'] as String)?.toLocal()
          : null,
      editado: json['editado'] as bool? ?? false,
      excluido: json['excluido'] as bool? ?? false,
      status: (json['lido'] == true)
          ? MessageStatus.read
          : MessageStatus.delivered,
    );
  }
}

/// Modelo de usuário para seleção de participantes
class UserSummary {
  final String id;
  final String nome;
  final String cargo;
  final String setorId;
  final String setorNome;
  final int hierarquiaNivel;
  final String? fotoUrl;
  final bool ativo;

  const UserSummary({
    required this.id,
    required this.nome,
    required this.cargo,
    required this.setorId,
    required this.setorNome,
    required this.hierarquiaNivel,
    this.fotoUrl,
    required this.ativo,
  });

  String get hierarquiaNome {
    switch (hierarquiaNivel) {
      case 1: return 'Direção';
      case 2: return 'Coordenação';
      case 3: return 'Supervisão';
      default: return 'Funcionário';
    }
  }

  static UserSummary fromJson(Map<String, dynamic> j) {
    final setor = j['setor'] as Map<String, dynamic>? ?? {};
    return UserSummary(
      id: j['id'] as String,
      nome: j['nome'] as String? ?? '',
      cargo: j['cargo'] as String? ?? '',
      setorId: setor['id'] as String? ?? j['setorId'] as String? ?? '',
      setorNome: setor['nome'] as String? ?? '',
      hierarquiaNivel: j['hierarquiaNivel'] as int? ?? 4,
      fotoUrl: j['fotoUrl'] as String?,
      ativo: j['ativo'] as bool? ?? true,
    );
  }
}
