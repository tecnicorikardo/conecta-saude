import 'package:equatable/equatable.dart';

enum AnnouncementPriority {
  normal,
  alta,
  urgente;

  static AnnouncementPriority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'urgente':
        return AnnouncementPriority.urgente;
      case 'alta':
        return AnnouncementPriority.alta;
      default:
        return AnnouncementPriority.normal;
    }
  }

  String get label {
    switch (this) {
      case AnnouncementPriority.urgente:
        return 'Urgente';
      case AnnouncementPriority.alta:
        return 'Alta';
      case AnnouncementPriority.normal:
        return 'Normal';
    }
  }
}

class AnnouncementEntity extends Equatable {
  final String id;
  final String titulo;
  final String mensagem;
  final AnnouncementPriority prioridade;
  final DateTime publicadoEm;
  final String criadorNome;
  final String criadorCargo;
  final bool lido;
  final DateTime? lidoEm;
  final int totalLeituras;
  final int totalUsuarios;

  const AnnouncementEntity({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.prioridade,
    required this.publicadoEm,
    required this.criadorNome,
    required this.criadorCargo,
    this.lido = false,
    this.lidoEm,
    this.totalLeituras = 0,
    this.totalUsuarios = 0,
  });

  int get percentualLeitura =>
      totalUsuarios > 0 ? ((totalLeituras / totalUsuarios) * 100).round() : 0;

  AnnouncementEntity copyWith({
    String? id,
    String? titulo,
    String? mensagem,
    AnnouncementPriority? prioridade,
    DateTime? publicadoEm,
    String? criadorNome,
    String? criadorCargo,
    bool? lido,
    DateTime? lidoEm,
    int? totalLeituras,
    int? totalUsuarios,
  }) {
    return AnnouncementEntity(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      mensagem: mensagem ?? this.mensagem,
      prioridade: prioridade ?? this.prioridade,
      publicadoEm: publicadoEm ?? this.publicadoEm,
      criadorNome: criadorNome ?? this.criadorNome,
      criadorCargo: criadorCargo ?? this.criadorCargo,
      lido: lido ?? this.lido,
      lidoEm: lidoEm ?? this.lidoEm,
      totalLeituras: totalLeituras ?? this.totalLeituras,
      totalUsuarios: totalUsuarios ?? this.totalUsuarios,
    );
  }

  @override
  List<Object?> get props => [
        id,
        titulo,
        mensagem,
        prioridade,
        publicadoEm,
        criadorNome,
        criadorCargo,
        lido,
        lidoEm,
        totalLeituras,
        totalUsuarios,
      ];
}

class AnnouncementReaderEntity extends Equatable {
  final String userId;
  final String nome;
  final String cargo;
  final String setorNome;
  final String? fotoUrl;
  final int hierarquiaNivel;
  final DateTime? lidoEm;

  const AnnouncementReaderEntity({
    required this.userId,
    required this.nome,
    required this.cargo,
    required this.setorNome,
    this.fotoUrl,
    required this.hierarquiaNivel,
    this.lidoEm,
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

class AnnouncementStatsEntity extends Equatable {
  final String announcementId;
  final int totalUsers;
  final int totalReads;
  final int percentual;
  final List<AnnouncementReaderEntity> readers;
  final List<AnnouncementReaderEntity> pending;

  const AnnouncementStatsEntity({
    required this.announcementId,
    required this.totalUsers,
    required this.totalReads,
    required this.percentual,
    required this.readers,
    required this.pending,
  });

  @override
  List<Object?> get props => [
        announcementId,
        totalUsers,
        totalReads,
        percentual,
        readers,
        pending,
      ];
}
