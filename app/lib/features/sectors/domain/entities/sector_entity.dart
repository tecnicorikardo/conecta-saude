class SectorEntity {
  final String id;
  final String nome;
  final String? sigla;
  final String? descricao;
  final String? icone;
  final String? unitId;
  final bool ativo;

  const SectorEntity({
    required this.id,
    required this.nome,
    this.sigla,
    this.descricao,
    this.icone,
    this.unitId,
    this.ativo = true,
  });

  factory SectorEntity.fromJson(Map<String, dynamic> json) {
    return SectorEntity(
      id: json['id'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      sigla: json['sigla'] as String?,
      descricao: json['descricao'] as String?,
      icone: json['icone'] as String?,
      unitId: json['unitId'] as String? ?? json['unit_id'] as String?,
      ativo: json['ativo'] as bool? ?? true,
    );
  }
}
