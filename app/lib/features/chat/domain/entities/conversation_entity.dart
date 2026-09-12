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
  final bool? emServico;

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
    if (emServico != null) return emServico!;
    if (emPlantaoExtra) return true;

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
