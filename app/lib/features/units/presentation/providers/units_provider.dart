import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/http_service.dart';
import '../../domain/entities/hospital_unit_entity.dart';

final unitsProvider = FutureProvider<List<HospitalUnitEntity>>((ref) async {
  try {
    final http = ref.watch(httpServiceProvider);
    final response = await http.get('/units');
    final data = response.data;

    if (data is Map<String, dynamic> && data['data'] is List) {
      final list = data['data'] as List;
      return list
          .map((item) => HospitalUnitEntity.fromJson(item as Map<String, dynamic>))
          .toList();
    }
  } catch (_) {}

  // Fallback para unidades padrão
  return const [
    HospitalUnitEntity(
      id: 'unit-chc-centro',
      nome: 'Complexo Hospitalar Carioca (Central)',
      sigla: 'CHC-Centro',
      cidade: 'Rio de Janeiro',
    ),
    HospitalUnitEntity(
      id: 'unit-hmzs',
      nome: 'Hospital Municipal Zona Sul',
      sigla: 'HMZS',
      cidade: 'Rio de Janeiro',
    ),
    HospitalUnitEntity(
      id: 'unit-upa24h',
      nome: 'UPA 24h Regional',
      sigla: 'UPA-24H',
      cidade: 'Rio de Janeiro',
    ),
  ];
});
