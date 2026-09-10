import 'package:equatable/equatable.dart';

class HospitalUnitEntity extends Equatable {
  final String id;
  final String nome;
  final String? sigla;
  final String? endereco;
  final String? cidade;
  final bool ativo;

  const HospitalUnitEntity({
    required this.id,
    required this.nome,
    this.sigla,
    this.endereco,
    this.cidade,
    this.ativo = true,
  });

  factory HospitalUnitEntity.fromJson(Map<String, dynamic> json) {
    return HospitalUnitEntity(
      id: json['id'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      sigla: json['sigla'] as String?,
      endereco: json['endereco'] as String?,
      cidade: json['cidade'] as String?,
      ativo: json['ativo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'sigla': sigla,
      'endereco': endereco,
      'cidade': cidade,
      'ativo': ativo,
    };
  }

  @override
  List<Object?> get props => [id, nome, sigla, endereco, cidade, ativo];
}
