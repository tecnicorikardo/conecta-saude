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
    super.fotoUrl,
    required super.ativo,
    required super.criadoEm,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final setor = json['setor'] as Map<String, dynamic>?;
    return UserModel(
      id: json['id'] as String? ?? '',
      firebaseUid: json['firebaseUid'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      email: json['email'] as String? ?? '',
      cargo: json['cargo'] as String? ?? '',
      hierarquiaNivel: (json['hierarquiaNivel'] as num?)?.toInt() ?? 4,
      setorId: json['setorId'] as String? ?? setor?['id'] as String? ?? '',
      setorNome: json['setorNome'] as String? ?? setor?['nome'] as String? ?? '',
      fotoUrl: json['fotoUrl'] as String?,
      ativo: json['ativo'] as bool? ?? true,
      criadoEm: json['criadoEm'] != null
          ? DateTime.tryParse(json['criadoEm'] as String) ?? DateTime.now()
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
      'fotoUrl': fotoUrl,
      'ativo': ativo,
      'criadoEm': criadoEm.toIso8601String(),
    };
  }
}
