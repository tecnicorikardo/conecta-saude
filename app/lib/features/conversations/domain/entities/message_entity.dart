import 'package:equatable/equatable.dart';

/// Entidade de mensagem do chat
class MessageEntity extends Equatable {
  final String id;
  final String texto;
  final bool excluido;
  final bool editado;
  final DateTime criadoEm;
  final DateTime? editadoEm;
  final MessageRemetente remetente;
  final bool lido;

  const MessageEntity({
    required this.id,
    required this.texto,
    required this.excluido,
    required this.editado,
    required this.criadoEm,
    this.editadoEm,
    required this.remetente,
    required this.lido,
  });

  /// Retorna se a mensagem ainda pode ser editada (janela de 5 minutos)
  bool get podeEditar {
    if (excluido) return false;
    final agora = DateTime.now();
    return agora.difference(criadoEm).inMinutes < 5;
  }

  @override
  List<Object?> get props => [id, texto, excluido, editado, criadoEm, editadoEm, remetente, lido];
}

class MessageRemetente extends Equatable {
  final String id;
  final String nome;
  final String? fotoUrl;
  final String? cargo;

  const MessageRemetente({
    required this.id,
    required this.nome,
    this.fotoUrl,
    this.cargo,
  });

  @override
  List<Object?> get props => [id, nome, fotoUrl, cargo];
}
