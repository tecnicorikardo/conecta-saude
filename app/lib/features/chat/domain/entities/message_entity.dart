enum MessageType {
  text,
  audio,
  image,
  document,
  emergency,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  error,
}

class MessageSender {
  final String id;
  final String nome;
  final String cargo;
  final String? fotoUrl;

  const MessageSender({
    required this.id,
    required this.nome,
    required this.cargo,
    this.fotoUrl,
  });
}

class MessageEntity {
  final String id;
  final String conversationId;
  final String texto;
  final MessageType tipo;
  final MessageSender remetente;
  final DateTime criadoEm;
  final DateTime? editadoEm;
  final bool editado;
  final bool excluido;
  final MessageStatus status;
  final int? audioDuration;
  final String? audioPath;

  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.texto,
    this.tipo = MessageType.text,
    required this.remetente,
    required this.criadoEm,
    this.editadoEm,
    this.editado = false,
    this.excluido = false,
    this.status = MessageStatus.sent,
    this.audioDuration,
    this.audioPath,
  });

  MessageEntity copyWith({
    String? id,
    String? conversationId,
    String? texto,
    MessageType? tipo,
    MessageSender? remetente,
    DateTime? criadoEm,
    DateTime? editadoEm,
    bool? editado,
    bool? excluido,
    MessageStatus? status,
    int? audioDuration,
    String? audioPath,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      texto: texto ?? this.texto,
      tipo: tipo ?? this.tipo,
      remetente: remetente ?? this.remetente,
      criadoEm: criadoEm ?? this.criadoEm,
      editadoEm: editadoEm ?? this.editadoEm,
      editado: editado ?? this.editado,
      excluido: excluido ?? this.excluido,
      status: status ?? this.status,
      audioDuration: audioDuration ?? this.audioDuration,
      audioPath: audioPath ?? this.audioPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'texto': texto,
      'tipo': tipo.name,
      'remetente': {
        'id': remetente.id,
        'nome': remetente.nome,
        'cargo': remetente.cargo,
        'fotoUrl': remetente.fotoUrl,
      },
      'criadoEm': criadoEm.toIso8601String(),
      'editadoEm': editadoEm?.toIso8601String(),
      'editado': editado,
      'excluido': excluido,
      'status': status.name,
      'audioDuration': audioDuration,
      'audioPath': audioPath,
    };
  }

  factory MessageEntity.fromJson(Map<String, dynamic> j) {
    final rem = j['remetente'] as Map<String, dynamic>? ?? {};
    return MessageEntity(
      id: j['id'] as String? ?? '',
      conversationId: j['conversationId'] as String? ?? '',
      texto: j['texto'] as String? ?? '',
      tipo: MessageType.values.firstWhere(
        (e) => e.name == j['tipo'],
        orElse: () => MessageType.text,
      ),
      remetente: MessageSender(
        id: rem['id'] as String? ?? '',
        nome: rem['nome'] as String? ?? '',
        cargo: rem['cargo'] as String? ?? '',
        fotoUrl: rem['fotoUrl'] as String?,
      ),
      criadoEm: DateTime.tryParse(j['criadoEm'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      editadoEm: j['editadoEm'] != null ? DateTime.tryParse(j['editadoEm'] as String)?.toLocal() : null,
      editado: j['editado'] as bool? ?? false,
      excluido: j['excluido'] as bool? ?? false,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == j['status'],
        orElse: () => MessageStatus.sent,
      ),
      audioDuration: j['audioDuration'] as int?,
      audioPath: j['audioPath'] as String?,
    );
  }
}
