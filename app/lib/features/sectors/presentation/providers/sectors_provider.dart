import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/http_service.dart';
import '../../domain/entities/sector_entity.dart';

final sectorsProvider = FutureProvider<List<SectorEntity>>((ref) async {
  try {
    final http = ref.watch(httpServiceProvider);
    final response = await http.get('/sectors');
    final data = response.data;

    if (data is Map<String, dynamic> && data['data'] is List) {
      final list = data['data'] as List;
      return list
          .map((item) => SectorEntity.fromJson(item as Map<String, dynamic>))
          .toList();
    }
  } catch (_) {}

  // Fallback para os 3 centros SUS + Direção
  return const [
    SectorEntity(
      id: '1c5017ec-4800-4c54-8ce4-90e44c5a1525',
      nome: 'Centro Carioca do Olho (CCO)',
      sigla: 'CCO',
      unitId: '1971e49c-f631-44ac-bed1-4ae10316e5eb',
    ),
    SectorEntity(
      id: '81b50efa-2919-41ce-8ab5-4d81c6c033fa',
      nome: 'Centro Carioca de Especialidades (CCE)',
      sigla: 'CCE',
      unitId: '1971e49c-f631-44ac-bed1-4ae10316e5eb',
    ),
    SectorEntity(
      id: '29b5d5d1-3ae3-4a0e-9a1a-6e71d8770612',
      nome: 'Centro Carioca de Diagnóstico e Tratamento por Imagem (CCDTI)',
      sigla: 'CCDTI',
      unitId: '1971e49c-f631-44ac-bed1-4ae10316e5eb',
    ),
    SectorEntity(
      id: 'bb317361-1736-4c5f-9a2d-d39b8a1c9680',
      nome: 'Direção Geral',
      sigla: 'DG',
      unitId: '1971e49c-f631-44ac-bed1-4ae10316e5eb',
    ),
  ];
});
