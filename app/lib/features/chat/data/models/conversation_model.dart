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
      autoExcluir24h: json['autoExcluir24h'] as bool? ?? true,
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
      jornadaInicio: user['jornadaInicio'] as String? ?? j['jornadaInicio'] as String? ?? '07:00',
      jornadaFim: user['jornadaFim'] as String? ?? j['jornadaFim'] as String? ?? '16:00',
      jornadaDias: user['jornadaDias'] as String? ?? j['jornadaDias'] as String? ?? 'seg,ter,qua,qui,sex',
      emPlantaoExtra: user['emPlantaoExtra'] as bool? ?? j['emPlantaoExtra'] as bool? ?? false,
      emServico: user['emServico'] as bool? ?? j['emServico'] as bool?,
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
  final String jornadaInicio;
  final String jornadaFim;
  final String jornadaDias;
  final bool emPlantaoExtra;
  final bool? emServico;

  const UserSummary({
    required this.id,
    required this.nome,
    required this.cargo,
    required this.setorId,
    required this.setorNome,
    required this.hierarquiaNivel,
    this.fotoUrl,
    required this.ativo,
    this.jornadaInicio = '07:00',
    this.jornadaFim = '16:00',
    this.jornadaDias = 'seg,ter,qua,qui,sex',
    this.emPlantaoExtra = false,
    this.emServico,
  });

  bool get isCurrentlyWorking {
    if (emServico != null) return emServico!;
    if (emPlantaoExtra) return true;
    if (!ativo) return false;

    final now = DateTime.now();
    final dayCodes = {
      1: 'seg',
      2: 'ter',
      3: 'qua',
      4: 'qui',
      5: 'sex',
      6: 'sab',
      7: 'dom',
    };
    final todayCode = dayCodes[now.weekday] ?? 'seg';
    final dias = jornadaDias.toLowerCase().split(',').map((d) => d.trim()).toList();
    if (!dias.contains(todayCode)) return false;

    final startParts = jornadaInicio.split(':').map((e) => int.tryParse(e) ?? 0).toList();
    final endParts = jornadaFim.split(':').map((e) => int.tryParse(e) ?? 0).toList();
    final startMinutes = (startParts.isNotEmpty ? startParts[0] : 7) * 60 +
        (startParts.length > 1 ? startParts[1] : 0);
    final endMinutes = (endParts.isNotEmpty ? endParts[0] : 16) * 60 +
        (endParts.length > 1 ? endParts[1] : 0);
    final nowMinutes = now.hour * 60 + now.minute;

    if (endMinutes >= startMinutes) {
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    } else {
      return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
    }
  }

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
      jornadaInicio: j['jornadaInicio'] as String? ?? '07:00',
      jornadaFim: j['jornadaFim'] as String? ?? '16:00',
      jornadaDias: j['jornadaDias'] as String? ?? 'seg,ter,qua,qui,sex',
      emPlantaoExtra: j['emPlantaoExtra'] as bool? ?? false,
      emServico: j['emServico'] as bool?,
    );
  }
}
