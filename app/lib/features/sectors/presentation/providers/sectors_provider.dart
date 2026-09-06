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

  // Fallback para os 3 centros SUS
  return const [
    SectorEntity(
      id: 'sec-ccdti',
      nome: 'Centro Carioca de Diagnóstico e Tratamento por Imagem',
      sigla: 'CCDTI',
    ),
    SectorEntity(
      id: 'sec-cco',
      nome: 'Centro Carioca do Olho',
      sigla: 'CCO',
    ),
    SectorEntity(
      id: 'sec-cce',
      nome: 'Centro Carioca de Especialidades',
      sigla: 'CCE',
    ),
    SectorEntity(
      id: 'sec-direcao',
      nome: 'Direção Geral',
      sigla: 'DG',
    ),
  ];
});
