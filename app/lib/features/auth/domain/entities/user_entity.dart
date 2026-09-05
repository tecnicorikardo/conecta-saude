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
  final bool ativo;
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
    required this.ativo,
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
        ativo,
        criadoEm,
      ];
}
