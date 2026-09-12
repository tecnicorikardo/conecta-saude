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

  /// Verifica se o usuário está atualmente dentro de sua escala/jornada de trabalho
  bool get isCurrentlyWorking {
    if (emPlantaoExtra) return true;
    if (!ativo) return false;

    final now = DateTime.now();

    // Se houve prorrogação/extensão de horas no fim do expediente e ainda está válida hoje
    if (jornadaEstendidaAte != null && now.isBefore(jornadaEstendidaAte!)) {
      return true;
    }

    // 1=seg, 2=ter, 3=qua, 4=qui, 5=sex, 6=sab, 7=dom
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

    if (!dias.contains(todayCode)) {
      return false;
    }

    final startParts = jornadaInicio.split(':').map((e) => int.tryParse(e) ?? 0).toList();
    final endParts = jornadaFim.split(':').map((e) => int.tryParse(e) ?? 0).toList();

    final startMinutes = (startParts.isNotEmpty ? startParts[0] : 7) * 60 +
        (startParts.length > 1 ? startParts[1] : 0);
    final endMinutes = (endParts.isNotEmpty ? endParts[0] : 16) * 60 +
        (endParts.length > 1 ? endParts[1] : 0);
    final nowMinutes = now.hour * 60 + now.minute;

    if (endMinutes >= startMinutes) {
      // Turno regular diurno (ex: 07:00 as 16:00)
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    } else {
      // Turno noturno / cruza meia-noite (ex: 19:00 as 07:00)
      return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
    }
  }

  String get workStatusLabel {
    if (!ativo) return 'Inativo';
    if (emPlantaoExtra) return 'Em Plantão Extra';
    if (jornadaEstendidaAte != null && DateTime.now().isBefore(jornadaEstendidaAte!)) {
      return 'Em Serviço (Hora Extra)';
    }
    if (isCurrentlyWorking) return 'Em Serviço';
    return 'Fora de Serviço';
  }

  Color get workStatusColor {
    if (!ativo) return const Color(0xFF9E9E9E);
    if (emPlantaoExtra) return const Color(0xFF0288D1); // Azul plantão extra
    if (jornadaEstendidaAte != null && DateTime.now().isBefore(jornadaEstendidaAte!)) {
      return const Color(0xFF2E7D32); // Verde SUS
    }
    if (isCurrentlyWorking) return const Color(0xFF2E7D32); // Verde SUS em serviço
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
        ativo,
        aprovadoPor,
        aprovadoEm,
        criadoEm,
      ];
}
