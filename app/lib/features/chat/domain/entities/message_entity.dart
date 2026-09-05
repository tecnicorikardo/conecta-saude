import 'package:equatable/equatable.dart';

enum MessageStatus { sending, sent, delivered, read }

enum MessageType { text, audio, image }

class MessageSender extends Equatable {
  final String id;
  final String nome;
  final String? fotoUrl;
  final String cargo;

  const MessageSender({
    required this.id,
    required this.nome,
    this.fotoUrl,
    required this.cargo,
  });

  @override
  List<Object?> get props => [id, nome, fotoUrl, cargo];
}

class MessageEntity extends Equatable {
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

  /// Para áudio: duração em segundos
  final int? audioDuration;

  /// Para áudio: caminho local ou URL remota
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

  bool get isOwn => false; // sobrescrito via provider

  MessageEntity copyWith({
    String? texto,
    bool? editado,
    DateTime? editadoEm,
    bool? excluido,
    MessageStatus? status,
    String? audioPath,
  }) {
    return MessageEntity(
      id: id,
      conversationId: conversationId,
      texto: texto ?? this.texto,
      tipo: tipo,
      remetente: remetente,
      criadoEm: criadoEm,
      editadoEm: editadoEm ?? this.editadoEm,
      editado: editado ?? this.editado,
      excluido: excluido ?? this.excluido,
      status: status ?? this.status,
      audioDuration: audioDuration,
      audioPath: audioPath ?? this.audioPath,
    );
  }

  @override
  List<Object?> get props => [
        id, conversationId, texto, tipo, remetente,
        criadoEm, editadoEm, editado, excluido, status,
        audioDuration, audioPath,
      ];
}
