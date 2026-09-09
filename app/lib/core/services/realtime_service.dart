import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../features/auth/presentation/providers/current_user_provider.dart';
import 'http_service.dart';

final realtimeServiceProvider = Provider.autoDispose<RealtimeService>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final service = RealtimeService(enabled: user?.ativo == true);
  ref.onDispose(service.dispose);
  return service;
});

class RealtimeService {
  RealtimeService({required bool enabled}) {
    if (enabled) unawaited(_connect());
  }
  final _events = StreamController<String?>.broadcast();
  Stream<String?> get changes => _events.stream;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _retry;
  Timer? _authDeadline;
  bool _disposed = false;
  bool connected = false;
  int _attempt = 0;

  Future<void> _connect() async {
    if (_disposed) return;
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (_disposed || token == null) return;
      final api = Uri.parse(kApiBaseUrl);
      final channel = WebSocketChannel.connect(api.replace(
        scheme: api.scheme == 'https' ? 'wss' : 'ws',
        path: '${api.path}/realtime',
      ));
      _channel = channel;
      _subscription = channel.stream.listen((raw) {
        if (_disposed || _channel != channel) return;
        try {
          final event = jsonDecode(raw as String) as Map<String, dynamic>;
          if (event['type'] == 'ready') {
            _authDeadline?.cancel();
            connected = true;
            _attempt = 0;
            _events.add(null); // Recover changes missed while disconnected.
          } else if (event['type'] == 'conversation.changed' &&
              event['conversationId'] is String) {
            _events.add(event['conversationId'] as String);
          }
        } catch (_) { /* Ignore invalid events; HTTP remains authoritative. */ }
      }, onError: (_) => _reconnect(), onDone: _reconnect);
      _authDeadline = Timer(const Duration(seconds: 20), _reconnect);
      await channel.ready;
      if (_disposed || _channel != channel) return;
      channel.sink.add(jsonEncode({'type': 'auth', 'token': token}));
    } catch (_) { _reconnect(); }
  }

  void _reconnect() {
    if (_disposed || _retry?.isActive == true) return;
    connected = false;
    _authDeadline?.cancel();
    final old = _channel;
    _channel = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(old?.sink.close());
    final seconds = min(30, 1 << min(_attempt++, 5));
    _retry = Timer(Duration(milliseconds: seconds * 1000 + Random().nextInt(500)), () {
      _retry = null;
      unawaited(_connect());
    });
  }

  void dispose() {
    _disposed = true;
    connected = false;
    _retry?.cancel();
    _authDeadline?.cancel();
    unawaited(_subscription?.cancel());
    unawaited(_channel?.sink.close());
    unawaited(_events.close());
  }
}
