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
