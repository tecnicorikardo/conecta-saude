import 'package:equatable/equatable.dart';

/// Entidade representativa de um setor hospitalar.
class SectorEntity extends Equatable {
  final String id;
  final String nome;
  final String? descricao;
  final bool ativo;
  final DateTime? criadoEm;

  const SectorEntity({
    required this.id,
    required this.nome,
    this.descricao,
    required this.ativo,
    this.criadoEm,
  });

  @override
  List<Object?> get props => [id, nome, descricao, ativo, criadoEm];
}
