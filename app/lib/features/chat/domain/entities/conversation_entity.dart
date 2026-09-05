import 'package:equatable/equatable.dart';
import 'message_entity.dart';

class ConversationParticipant extends Equatable {
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

  String get hierarquiaNome {
    switch (hierarquiaNivel) {
      case 1: return 'Direção';
      case 2: return 'Coordenação';
      case 3: return 'Supervisão';
      default: return 'Funcionário';
    }
  }

  @override
  List<Object?> get props => [id, nome, fotoUrl, cargo, setorNome, hierarquiaNivel];
}

class ConversationEntity extends Equatable {
  final String id;
  final String tipo; // individual | grupo | setor
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
    this.unreadCount = 0,
    required this.atualizadoEm,
  });

  /// Nome para exibição: nome do grupo ou nome do outro participante
  String displayName(String currentUserId) {
    if (nome != null && nome!.isNotEmpty) return nome!;
    if (tipo == 'individual') {
      final other = participantes.where((p) => p.id != currentUserId).firstOrNull;
      return other?.nome ?? 'Conversa';
    }
    return nome ?? 'Grupo';
  }

  String? displayPhoto(String currentUserId) {
    if (tipo == 'individual') {
      return participantes.where((p) => p.id != currentUserId).firstOrNull?.fotoUrl;
    }
    return null;
  }

  String displaySubtitle(String currentUserId) {
    if (tipo == 'individual') {
      final other = participantes.where((p) => p.id != currentUserId).firstOrNull;
      if (other == null) return '';
      return '${other.cargo} • ${other.setorNome}';
    }
    return '${participantes.length} participantes';
  }

  @override
  List<Object?> get props => [id, tipo, nome, participantes, lastMessage, unreadCount, atualizadoEm];
}
