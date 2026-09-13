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
      id: '1971e49c-f631-44ac-bed1-4ae10316e5eb',
      nome: 'Super Centro Carioca de Saúde',
      sigla: 'SCCS',
      cidade: 'Rio de Janeiro',
    ),
  ];
});
