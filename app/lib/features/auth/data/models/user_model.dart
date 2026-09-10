import '../../domain/entities/user_entity.dart';

/// Modelo de dados para usuário com serialização JSON.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.firebaseUid,
    required super.nome,
    required super.email,
    required super.cargo,
    required super.hierarquiaNivel,
    required super.setorId,
    required super.setorNome,
    super.unitId,
    super.unitNome,
    super.unitSigla,
    super.fotoUrl,
    super.matricula,
    super.jornadaInicio,
    super.jornadaFim,
    super.jornadaDias,
    super.emPlantaoExtra,
    super.silenciarForaJornada,
    required super.ativo,
    super.aprovadoPor,
    super.aprovadoEm,
    required super.criadoEm,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final setor = json['setor'] as Map<String, dynamic>?;
    final unit = json['unit'] as Map<String, dynamic>?;
    return UserModel(
      id: json['id'] as String? ?? '',
      firebaseUid: json['firebaseUid'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      email: json['email'] as String? ?? '',
      cargo: json['cargo'] as String? ?? '',
      hierarquiaNivel: (json['hierarquiaNivel'] as num?)?.toInt() ?? 4,
      setorId: json['setorId'] as String? ?? setor?['id'] as String? ?? '',
      setorNome: json['setorNome'] as String? ?? setor?['nome'] as String? ?? '',
      unitId: json['unitId'] as String? ?? unit?['id'] as String?,
      unitNome: json['unitNome'] as String? ?? unit?['nome'] as String?,
      unitSigla: json['unitSigla'] as String? ?? unit?['sigla'] as String?,
      fotoUrl: json['fotoUrl'] as String?,
      matricula: json['matricula'] as String?,
      jornadaInicio: json['jornadaInicio'] as String? ?? '07:00',
      jornadaFim: json['jornadaFim'] as String? ?? '16:00',
      jornadaDias: json['jornadaDias'] as String? ?? 'seg,ter,qua,qui,sex',
      emPlantaoExtra: json['emPlantaoExtra'] as bool? ?? false,
      silenciarForaJornada: json['silenciarForaJornada'] as bool? ?? true,
      ativo: json['ativo'] as bool? ?? true,
      aprovadoPor: json['aprovadoPor'] as String?,
      aprovadoEm: json['aprovadoEm'] != null
          ? DateTime.tryParse(json['aprovadoEm'] as String)?.toLocal()
          : null,
      criadoEm: json['criadoEm'] != null
          ? DateTime.tryParse(json['criadoEm'] as String)?.toLocal() ?? DateTime.now()
          : DateTime.now(),
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
      'emPlantaoExtra': emPlantaoExtra,
      'silenciarForaJornada': silenciarForaJornada,
      'ativo': ativo,
      'aprovadoPor': aprovadoPor,
      'aprovadoEm': aprovadoEm?.toIso8601String(),
      'criadoEm': criadoEm.toIso8601String(),
    };
  }
}
