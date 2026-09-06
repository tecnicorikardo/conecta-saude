import 'package:equatable/equatable.dart';

enum EmergencyType { pcr, o2Energia, trauma, seguranca, geral }

extension EmergencyTypeX on EmergencyType {
  String get label {
    switch (this) {
      case EmergencyType.pcr:
        return 'Código Vermelho (PCR / Parada)';
      case EmergencyType.o2Energia:
        return 'Pane de O₂ / Falta de Energia';
      case EmergencyType.trauma:
        return 'Urgência Cirúrgica / Trauma Grave';
      case EmergencyType.seguranca:
        return 'Chamado de Segurança / Contenção';
      case EmergencyType.geral:
        return 'Alerta Geral de Emergência';
    }
  }

  String get shortLabel {
    switch (this) {
      case EmergencyType.pcr:
        return 'PCR / Parada';
      case EmergencyType.o2Energia:
        return 'Pane O₂ / Energia';
      case EmergencyType.trauma:
        return 'Trauma Cirúrgico';
      case EmergencyType.seguranca:
        return 'Segurança';
      case EmergencyType.geral:
        return 'Alerta Geral';
    }
  }

  String get value {
    switch (this) {
      case EmergencyType.pcr:
        return 'pcr';
      case EmergencyType.o2Energia:
        return 'o2_energia';
      case EmergencyType.trauma:
        return 'trauma';
      case EmergencyType.seguranca:
        return 'seguranca';
      case EmergencyType.geral:
        return 'geral';
    }
  }

  static EmergencyType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'pcr':
        return EmergencyType.pcr;
      case 'o2_energia':
        return EmergencyType.o2Energia;
      case 'trauma':
        return EmergencyType.trauma;
      case 'seguranca':
        return EmergencyType.seguranca;
      default:
        return EmergencyType.geral;
    }
  }
}

class EmergencyAlertEntity extends Equatable {
  final String id;
  final EmergencyType tipo;
  final String titulo;
  final String? descricao;
  final String localizacao;
  final String status;
  final DateTime criadoEm;
  final DateTime? resolvidoEm;
  final String criadorNome;
  final String criadorCargo;
  final String criadorSetor;
  final String? criadorFotoUrl;
  final String? resolvidoPorNome;

  const EmergencyAlertEntity({
    required this.id,
    required this.tipo,
    required this.titulo,
    this.descricao,
    required this.localizacao,
    required this.status,
    required this.criadoEm,
    this.resolvidoEm,
    required this.criadorNome,
    required this.criadorCargo,
    required this.criadorSetor,
    this.criadorFotoUrl,
    this.resolvidoPorNome,
  });

  bool get isAtivo => status == 'ativo';

  factory EmergencyAlertEntity.fromJson(Map<String, dynamic> json) {
    final criador = json['criador'] as Map<String, dynamic>?;
    return EmergencyAlertEntity(
      id: json['id'] as String,
      tipo: EmergencyTypeX.fromString(json['tipo'] as String? ?? 'geral'),
      titulo: json['titulo'] as String? ?? 'Alerta de Emergência',
      descricao: json['descricao'] as String?,
      localizacao: json['localizacao'] as String? ?? 'Unidade de Plantão',
      status: json['status'] as String? ?? 'ativo',
      criadoEm: json['criadoEm'] != null
          ? DateTime.parse(json['criadoEm'] as String).toLocal()
          : DateTime.now(),
      resolvidoEm: json['resolvidoEm'] != null
          ? DateTime.parse(json['resolvidoEm'] as String).toLocal()
          : null,
      criadorNome: criador?['nome'] as String? ?? json['criadorNome'] as String? ?? 'Plantão',
      criadorCargo: criador?['cargo'] as String? ?? json['criadorCargo'] as String? ?? 'Servidor',
      criadorSetor: criador?['setorNome'] as String? ?? json['criadorSetor'] as String? ?? '',
      criadorFotoUrl: criador?['fotoUrl'] as String?,
      resolvidoPorNome: json['resolvidoPorNome'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, tipo, titulo, localizacao, status, criadoEm, resolvidoEm];
}
