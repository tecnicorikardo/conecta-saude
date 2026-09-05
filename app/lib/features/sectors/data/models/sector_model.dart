import '../../domain/entities/sector_entity.dart';

/// Modelo de dados de setor hospitalar com conversão JSON.
class SectorModel extends SectorEntity {
  const SectorModel({
    required super.id,
    required super.nome,
    super.descricao,
    required super.ativo,
    super.criadoEm,
  });

  factory SectorModel.fromJson(Map<String, dynamic> json) {
    return SectorModel(
      id: json['id'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      descricao: json['descricao'] as String?,
      ativo: json['ativo'] as bool? ?? true,
      criadoEm: json['criadoEm'] != null
          ? DateTime.tryParse(json['criadoEm'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
      if (criadoEm != null) 'criadoEm': criadoEm!.toIso8601String(),
    };
  }
}
