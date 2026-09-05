import '../entities/announcement_entity.dart';

abstract class AnnouncementsRepository {
  Future<List<AnnouncementEntity>> getAnnouncements();
  Future<bool> confirmRead(String id);
  Future<AnnouncementEntity> createAnnouncement({
    required String titulo,
    required String mensagem,
    required AnnouncementPriority prioridade,
  });
  Future<Map<String, int>> getStats(String id);
}
