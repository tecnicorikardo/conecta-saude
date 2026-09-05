import 'package:equatable/equatable.dart';

/// Tipos de conversa suportados pelo backend
enum ConversationType { individual, grupo, setor }

/// Entidade de conversa (lista de conversas)
class ConversationEntity extends Equatable {
  final String id;
  final ConversationType tipo;
  final String? nome;
  final List<ConversationMember> members;
  final ConversationLastMessage? lastMessage;
  final int unreadCount;
  final DateTime atualizadoEm;

  const ConversationEntity({
    required this.id,
    required this.tipo,
    this.nome,
    required this.members,
    this.lastMessage,
    required this.unreadCount,
    required this.atualizadoEm,
  });

  /// Retorna o nome de exibição da conversa
  String displayName(String currentUserId) {
    if (nome != null && nome!.isNotEmpty) return nome!;
    // Para conversa individual, mostra o nome do outro participante
    if (tipo == ConversationType.individual) {
      final outro = members.where((m) => m.id != currentUserId).firstOrNull;
      return outro?.nome ?? 'Conversa';
    }
    return 'Grupo';
  }

  /// Retorna a inicial do nome para o avatar
  String avatarInitial(String currentUserId) {
    final name = displayName(currentUserId);
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [id, tipo, nome, members, lastMessage, unreadCount, atualizadoEm];
}

class ConversationMember extends Equatable {
  final String id;
  final String nome;
  final String? fotoUrl;
  final String? cargo;

  const ConversationMember({
    required this.id,
    required this.nome,
    this.fotoUrl,
    this.cargo,
  });

  @override
  List<Object?> get props => [id, nome, fotoUrl, cargo];
}

class ConversationLastMessage extends Equatable {
  final String id;
  final String? texto;
  final bool excluido;
  final DateTime criadoEm;
  final String remetenteNome;

  const ConversationLastMessage({
    required this.id,
    this.texto,
    required this.excluido,
    required this.criadoEm,
    required this.remetenteNome,
  });

  String get preview {
    if (excluido) return '🚫 Mensagem apagada';
    return texto ?? '';
  }

  @override
  List<Object?> get props => [id, texto, excluido, criadoEm, remetenteNome];
}
