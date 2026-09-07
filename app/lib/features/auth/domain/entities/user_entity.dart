import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String firebaseUid;
  final String nome;
  final String email;
  final String cargo;
  final int hierarquiaNivel;
  final String setorId;
  final String setorNome;
  final String? fotoUrl;
  final String? matricula;
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
    this.fotoUrl,
    this.matricula,
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

  UserEntity copyWith({
    String? id,
    String? firebaseUid,
    String? nome,
    String? email,
    String? cargo,
    int? hierarquiaNivel,
    String? setorId,
    String? setorNome,
    String? fotoUrl,
    String? matricula,
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
      fotoUrl: fotoUrl ?? this.fotoUrl,
      matricula: matricula ?? this.matricula,
      ativo: ativo ?? this.ativo,
      aprovadoPor: aprovadoPor ?? this.aprovadoPor,
      aprovadoEm: aprovadoEm ?? this.aprovadoEm,
      criadoEm: criadoEm ?? this.criadoEm,
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
        fotoUrl,
        matricula,
        ativo,
        aprovadoPor,
        aprovadoEm,
        criadoEm,
      ];
}
