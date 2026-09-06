import 'package:equatable/equatable.dart';

enum ChannelType {
  institucional,
  setor,
  emergencia,
  geral;

  static ChannelType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'emergencia':
        return ChannelType.emergencia;
      case 'institucional':
        return ChannelType.institucional;
      case 'setor':
        return ChannelType.setor;
      default:
        return ChannelType.geral;
    }
  }

  String get label {
    switch (this) {
      case ChannelType.emergencia:
        return 'Emergência';
      case ChannelType.institucional:
        return 'Institucional';
      case ChannelType.setor:
        return 'Meu Setor';
      case ChannelType.geral:
        return 'Geral';
    }
  }
}

class ChannelEntity extends Equatable {
  final String id;
  final String nome;
  final String? descricao;
  final ChannelType tipo;
  final String? centroTag; // CCD, CCO, CCE, GERAL, EMERGENCIA
  final String? setorId;
  final String? setorNome;
  final int totalMembros;
  final String? ultimaMensagem;
  final DateTime? ultimaMensagemHora;
  final int naoLidas;

  const ChannelEntity({
    required this.id,
    required this.nome,
    this.descricao,
    required this.tipo,
    this.centroTag,
    this.setorId,
    this.setorNome,
    this.totalMembros = 0,
    this.ultimaMensagem,
    this.ultimaMensagemHora,
    this.naoLidas = 0,
  });

  bool get isEmergencia => tipo == ChannelType.emergencia || centroTag == 'EMERGENCIA';

  ChannelEntity copyWith({
    String? id,
    String? nome,
    String? descricao,
    ChannelType? tipo,
    String? centroTag,
    String? setorId,
    String? setorNome,
    int? totalMembros,
    String? ultimaMensagem,
    DateTime? ultimaMensagemHora,
    int? naoLidas,
  }) {
    return ChannelEntity(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      tipo: tipo ?? this.tipo,
      centroTag: centroTag ?? this.centroTag,
      setorId: setorId ?? this.setorId,
      setorNome: setorNome ?? this.setorNome,
      totalMembros: totalMembros ?? this.totalMembros,
      ultimaMensagem: ultimaMensagem ?? this.ultimaMensagem,
      ultimaMensagemHora: ultimaMensagemHora ?? this.ultimaMensagemHora,
      naoLidas: naoLidas ?? this.naoLidas,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nome,
        descricao,
        tipo,
        centroTag,
        setorId,
        setorNome,
        totalMembros,
        ultimaMensagem,
        ultimaMensagemHora,
        naoLidas,
      ];
}

class ChannelMessageEntity extends Equatable {
  final String id;
  final String channelId;
  final String remetenteId;
  final String remetenteNome;
  final String remetenteCargo;
  final String? remetenteFotoUrl;
  final int remetenteHierarquia;
  final String texto;
  final DateTime criadoEm;
  final int readsCount;
  final bool lidoPorMim;

  const ChannelMessageEntity({
    required this.id,
    required this.channelId,
    required this.remetenteId,
    required this.remetenteNome,
    required this.remetenteCargo,
    this.remetenteFotoUrl,
    required this.remetenteHierarquia,
    required this.texto,
    required this.criadoEm,
    this.readsCount = 0,
    this.lidoPorMim = true,
  });

  bool get isDirecao => remetenteHierarquia == 1;
  bool get isCoordenacao => remetenteHierarquia == 2;

  @override
  List<Object?> get props => [
        id,
        channelId,
        remetenteId,
        remetenteNome,
        remetenteCargo,
        remetenteFotoUrl,
        remetenteHierarquia,
        texto,
        criadoEm,
        readsCount,
        lidoPorMim,
      ];
}

class ChannelReaderEntity extends Equatable {
  final String userId;
  final String nome;
  final String cargo;
  final String setorNome;
  final String? fotoUrl;
  final int hierarquiaNivel;
  final DateTime lidoEm;

  const ChannelReaderEntity({
    required this.userId,
    required this.nome,
    required this.cargo,
    required this.setorNome,
    this.fotoUrl,
    required this.hierarquiaNivel,
    required this.lidoEm,
  });

  @override
  List<Object?> get props => [
        userId,
        nome,
        cargo,
        setorNome,
        fotoUrl,
        hierarquiaNivel,
        lidoEm,
      ];
}

class ChannelMessageStatsEntity extends Equatable {
  final String messageId;
  final int totalMembers;
  final int totalReads;
  final int percentual;
  final List<ChannelReaderEntity> readers;

  const ChannelMessageStatsEntity({
    required this.messageId,
    required this.totalMembers,
    required this.totalReads,
    required this.percentual,
    required this.readers,
  });

  @override
  List<Object?> get props => [
        messageId,
        totalMembers,
        totalReads,
        percentual,
        readers,
      ];
}
