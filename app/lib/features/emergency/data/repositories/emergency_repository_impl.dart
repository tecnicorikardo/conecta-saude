import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/http_service.dart';
import '../../domain/entities/emergency_entity.dart';
import '../../domain/repositories/emergency_repository.dart';

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  final http = ref.watch(httpServiceProvider);
  return EmergencyRepositoryImpl(http);
});

class EmergencyRepositoryImpl implements EmergencyRepository {
  final HttpService _http;

  EmergencyRepositoryImpl(this._http);

  @override
  Future<EmergencyAlertEntity?> getActiveEmergency() async {
    try {
      final response = await _http.get('/emergency/active');
      final data = response.data['data'];
      if (data == null) return null;
      return EmergencyAlertEntity.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<EmergencyAlertEntity> createEmergencyAlert({
    required EmergencyType tipo,
    required String titulo,
    String? descricao,
    required String localizacao,
  }) async {
    try {
      final response = await _http.post(
        '/emergency',
        data: {
          'tipo': tipo.value,
          'titulo': titulo,
          if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
          'localizacao': localizacao,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return EmergencyAlertEntity.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<bool> resolveEmergencyAlert(String id, {String? observacao}) async {
    try {
      final response = await _http.patch(
        '/emergency/$id/resolve',
        data: {
          if (observacao != null && observacao.isNotEmpty) 'observacao': observacao,
        },
      );
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<EmergencyAlertEntity>> getEmergencyHistory() async {
    try {
      final response = await _http.get('/emergency/history');
      final items = response.data['data']?['items'] as List? ?? [];
      return items
          .map((item) => EmergencyAlertEntity.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Exception _handleError(DioException e) {
    final msg = e.response?.data?['error'] as String?;
    final status = e.response?.statusCode;
    if (status == 401) return Exception('Sessão expirada.');
    if (status == 403) return Exception(msg ?? 'Sem permissão para esta ação.');
    return Exception(msg ?? 'Erro ao processar emergência.');
  }
}
