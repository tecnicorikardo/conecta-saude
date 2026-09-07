import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'http_service.dart';

/// Serviço unificado de Notificações Push (Firebase Cloud Messaging)
/// Funciona em Web, PWA Standalone (Android/iOS) e Flutter Mobile.
class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _initialized = false;
  String? _fcmToken;

  NotificationService(this._ref);

  String? get currentToken => _fcmToken;

  /// Inicializa as permissões e ouvintes de notificação
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1. Solicitar permissão de notificação (Web / iOS / Android 13+)
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('[FCM] Status de autorização: ${settings.authorizationStatus}');

      // 2. Configurar apresentação em primeiro plano
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Obter e sincronizar token com backend
      await syncToken();

      // 4. Escutar renovação periódica de token
      _fcm.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _sendTokenToBackend(newToken);
      });

      // 5. Escutar mensagens recebidas com o app em primeiro plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM Foreground] Push recebido: ${message.notification?.title} - ${message.notification?.body}');
      });

      // 6. Escutar abertura do app ao tocar na notificação push (background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM Background Click] Notificação clicada: ${message.data}');
      });
    } catch (e) {
      debugPrint('[FCM] Falha ao inicializar NotificationService: $e');
    }
  }

  /// Obtém o FCM token atual do dispositivo e envia para o Postgres via backend
  Future<String?> syncToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      String? token;
      try {
        token = await _fcm.getToken();
      } catch (tokenErr) {
        debugPrint('[FCM] Erro ao recuperar token FCM: $tokenErr');
      }

      if (token != null && token.isNotEmpty) {
        _fcmToken = token;
        debugPrint('[FCM] Token obtido com sucesso: $token');
        await _sendTokenToBackend(token);
        return token;
      }
    } catch (e) {
      debugPrint('[FCM] Erro durante sincronização do token: $e');
    }
    return null;
  }

  /// Envia o token FCM para o endpoint PATCH /api/auth/fcm-token
  Future<void> _sendTokenToBackend(String token) async {
    try {
      final http = _ref.read(httpServiceProvider);
      await http.patch('/auth/fcm-token', data: {'fcmToken': token});
      debugPrint('[FCM] Token salvo no PostgreSQL com sucesso.');
    } catch (e) {
      debugPrint('[FCM] Não foi possível registrar token no backend: $e');
    }
  }
}

/// Provider global do NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(ref);
  return service;
});
