import '../entities/emergency_entity.dart';

abstract class EmergencyRepository {
  Future<EmergencyAlertEntity?> getActiveEmergency();
  Future<EmergencyAlertEntity> createEmergencyAlert({
    required EmergencyType tipo,
    required String titulo,
    String? descricao,
    required String localizacao,
  });
  Future<bool> resolveEmergencyAlert(String id, {String? observacao});
  Future<List<EmergencyAlertEntity>> getEmergencyHistory();
}
