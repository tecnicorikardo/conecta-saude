import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class UserEntity extends Equatable {
  final String id;
  final String firebaseUid;
  final String nome;
  final String email;
  final String cargo;
  final int hierarquiaNivel;
  final String setorId;
  final String setorNome;
  final String? unitId;
  final String? unitNome;
  final String? unitSigla;
  final String? fotoUrl;
  final String? matricula;
  final String jornadaInicio; // "HH:mm", default "07:00"
  final String jornadaFim;    // "HH:mm", default "16:00"
  final String jornadaDias;   // "seg,ter,qua,qui,sex"
  final DateTime? jornadaEstendidaAte; // Extensão de horas extras para o dia
  final bool emPlantaoExtra;
  final bool silenciarForaJornada;
  final bool emServico; // Status manual: true=Em Serviço, false=Fora de Serviço
  final bool ativo;
  final String? aprovadoPor;
  final DateTime? aprovadoEm;
  final DateTime criadoEm;

  const UserEntity({
    required this.id,
    required this.firebaseUid,
    required this.nome,
    required this.email,
    required this.cargo,
    required this.hierarquiaNivel,
    required this.setorId,
    required this.setorNome,
    this.unitId,
    this.unitNome,
    this.unitSigla,
    this.fotoUrl,
    this.matricula,
    this.jornadaInicio = '07:00',
    this.jornadaFim = '16:00',
    this.jornadaDias = 'seg,ter,qua,qui,sex',
    this.jornadaEstendidaAte,
    this.emPlantaoExtra = false,
    this.silenciarForaJornada = true,
    this.emServico = true,
    required this.ativo,
    this.aprovadoPor,
    this.aprovadoEm,
    required this.criadoEm,
  });

  bool get isDirecao => hierarquiaNivel == 1;
  bool get isCoordenacao => hierarquiaNivel == 2;
  bool get isSupervisao => hierarquiaNivel == 3;
  bool get isFuncionario => hierarquiaNivel == 4;
  bool get isAdmin => hierarquiaNivel <= 2;

  String get hierarquiaNome {
    switch (hierarquiaNivel) {
      case 1:
        return 'Direção';
      case 2:
        return 'Coordenação';
      case 3:
        return 'Supervisão';
      case 4:
        return 'Funcionário';
      default:
        return 'Desconhecido';
    }
  }

  /// Verifica se o usuário está atualmente em serviço
  /// Agora usa o campo manual emServico ao invés de cálculo automático
  bool get isCurrentlyWorking => emServico;

  String get workStatusLabel {
    if (!ativo) return 'Inativo';
    if (emServico) return 'Em Serviço';
    return 'Fora de Serviço';
  }

  Color get workStatusColor {
    if (!ativo) return const Color(0xFF9E9E9E); // Cinza
    if (emServico) return const Color(0xFF2E7D32); // Verde SUS em serviço
    return const Color(0xFFF57C00); // Laranja fora de serviço
  }

  UserEntity copyWith({
    String? id,
    String? firebaseUid,
    String? nome,
    String? email,
    String? cargo,
    int? hierarquiaNivel,
    String? setorId,
    String? setorNome,
    String? unitId,
    String? unitNome,
    String? unitSigla,
    String? fotoUrl,
    String? matricula,
    String? jornadaInicio,
    String? jornadaFim,
    String? jornadaDias,
    DateTime? jornadaEstendidaAte,
    bool? emPlantaoExtra,
    bool? silenciarForaJornada,
    bool? emServico,
    bool? ativo,
    String? aprovadoPor,
    DateTime? aprovadoEm,
    DateTime? criadoEm,
  }) {
    return UserEntity(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      cargo: cargo ?? this.cargo,
      hierarquiaNivel: hierarquiaNivel ?? this.hierarquiaNivel,
      setorId: setorId ?? this.setorId,
      setorNome: setorNome ?? this.setorNome,
      unitId: unitId ?? this.unitId,
      unitNome: unitNome ?? this.unitNome,
      unitSigla: unitSigla ?? this.unitSigla,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      matricula: matricula ?? this.matricula,
      jornadaInicio: jornadaInicio ?? this.jornadaInicio,
      jornadaFim: jornadaFim ?? this.jornadaFim,
      jornadaDias: jornadaDias ?? this.jornadaDias,
      jornadaEstendidaAte: jornadaEstendidaAte ?? this.jornadaEstendidaAte,
      emPlantaoExtra: emPlantaoExtra ?? this.emPlantaoExtra,
      silenciarForaJornada: silenciarForaJornada ?? this.silenciarForaJornada,
      emServico: emServico ?? this.emServico,
      ativo: ativo ?? this.ativo,
      aprovadoPor: aprovadoPor ?? this.aprovadoPor,
      aprovadoEm: aprovadoEm ?? this.aprovadoEm,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'nome': nome,
      'email': email,
      'cargo': cargo,
      'hierarquiaNivel': hierarquiaNivel,
      'setorId': setorId,
      'setorNome': setorNome,
      'unitId': unitId,
      'unitNome': unitNome,
      'unitSigla': unitSigla,
      'fotoUrl': fotoUrl,
      'matricula': matricula,
      'jornadaInicio': jornadaInicio,
      'jornadaFim': jornadaFim,
      'jornadaDias': jornadaDias,
      'jornadaEstendidaAte': jornadaEstendidaAte?.toIso8601String(),
      'emPlantaoExtra': emPlantaoExtra,
      'silenciarForaJornada': silenciarForaJornada,
      'emServico': emServico,
      'ativo': ativo,
      'aprovadoPor': aprovadoPor,
      'aprovadoEm': aprovadoEm?.toIso8601String(),
      'criadoEm': criadoEm.toIso8601String(),
    };
  }

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String? ?? '',
      firebaseUid: json['firebaseUid'] as String? ?? '',
      nome: json['nome'] as String? ?? 'Usuário',
      email: json['email'] as String? ?? '',
      cargo: json['cargo'] as String? ?? 'Funcionário',
      hierarquiaNivel: json['hierarquiaNivel'] as int? ?? 4,
      setorId: json['setorId'] as String? ?? '',
      setorNome: json['setorNome'] as String? ?? '',
      unitId: json['unitId'] as String?,
      unitNome: json['unitNome'] as String?,
      unitSigla: json['unitSigla'] as String?,
      fotoUrl: json['fotoUrl'] as String?,
      matricula: json['matricula'] as String?,
      jornadaInicio: json['jornadaInicio'] as String? ?? '07:00',
      jornadaFim: json['jornadaFim'] as String? ?? '16:00',
      jornadaDias: json['jornadaDias'] as String? ?? 'seg,ter,qua,qui,sex',
      jornadaEstendidaAte: json['jornadaEstendidaAte'] != null
          ? DateTime.tryParse(json['jornadaEstendidaAte'] as String)
          : null,
      emPlantaoExtra: json['emPlantaoExtra'] as bool? ?? false,
      silenciarForaJornada: json['silenciarForaJornada'] as bool? ?? true,
      emServico: json['emServico'] as bool? ?? true,
      ativo: json['ativo'] as bool? ?? true,
      aprovadoPor: json['aprovadoPor'] as String?,
      aprovadoEm: json['aprovadoEm'] != null
          ? DateTime.tryParse(json['aprovadoEm'] as String)
          : null,
      criadoEm: json['criadoEm'] != null
          ? DateTime.tryParse(json['criadoEm'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        firebaseUid,
        nome,
        email,
        cargo,
        hierarquiaNivel,
        setorId,
        setorNome,
        unitId,
        unitNome,
        unitSigla,
        fotoUrl,
        matricula,
        jornadaInicio,
        jornadaFim,
        jornadaDias,
        jornadaEstendidaAte,
        emPlantaoExtra,
        silenciarForaJornada,
        emServico,
        ativo,
        aprovadoPor,
        aprovadoEm,
        criadoEm,
      ];
}
