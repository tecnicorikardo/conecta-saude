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
}
