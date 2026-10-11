import 'package:shared_preferences/shared_preferences.dart';

/// Ocultação local do histórico, isolada por conta e conversa.
class ConversationHistoryStore {
  final Map<String, DateTime> _clearedAt = {};
  String _key(String userId, String conversationId) =>
      '$userId:$conversationId';

  DateTime? cached(String userId, String conversationId) =>
      _clearedAt[_key(userId, conversationId)];

  Future<DateTime?> read(String userId, String conversationId) async {
    final key = _key(userId, conversationId);
    if (_clearedAt.containsKey(key)) return _clearedAt[key];
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt('chat_cleared_at_$key');
    if (ms == null) return null;
    return _clearedAt[key] = DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> clear(String userId, String conversationId, DateTime at) async {
    final key = _key(userId, conversationId);
    final prefs = await SharedPreferences.getInstance();
    final saved =
        await prefs.setInt('chat_cleared_at_$key', at.millisecondsSinceEpoch);
    if (!saved) {
      throw Exception('Não foi possível salvar a limpeza neste dispositivo.');
    }
    _clearedAt[key] = at;
  }
}
