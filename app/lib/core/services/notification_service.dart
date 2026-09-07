import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'http_service.dart';

/// Provedor reativo do status de autorização de notificações
final pushPermissionStatusProvider = StateProvider<AuthorizationStatus>((ref) {
  return AuthorizationStatus.notDetermined;
});

/// Provedor do token FCM atual
final currentFcmTokenProvider = StateProvider<String?>((ref) => null);

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
      // 1. Verificar permissões atuais com timeout seguro
      NotificationSettings? currentSettings;
      try {
        currentSettings = await _fcm
            .getNotificationSettings()
            .timeout(const Duration(seconds: 4));
      } catch (_) {}

      final authStatus = currentSettings?.authorizationStatus ??
          AuthorizationStatus.notDetermined;

      _ref.read(pushPermissionStatusProvider.notifier).state = authStatus;
      debugPrint('[FCM] Status de permissão inicial: $authStatus');

      // Se já autorizado ou provisório, sincroniza token automaticamente
      if (authStatus == AuthorizationStatus.authorized ||
          authStatus == AuthorizationStatus.provisional) {
        unawaited(syncToken());
      }

      // 2. Configurar apresentação em primeiro plano
      try {
        await _fcm.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (_) {}

      // 3. Escutar renovação periódica de token
      _fcm.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _ref.read(currentFcmTokenProvider.notifier).state = newToken;
        _sendTokenToBackend(newToken);
      });

      // 4. Escutar mensagens recebidas com o app em primeiro plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
            '[FCM Foreground] Push recebido: ${message.notification?.title} - ${message.notification?.body}');
      });

      // 5. Escutar abertura do app ao tocar na notificação push (background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
            '[FCM Background Click] Notificação clicada: ${message.data}');
      });
    } catch (e) {
      debugPrint('[FCM] Falha ao inicializar NotificationService: $e');
    }
  }

  /// Solicita permissão explicitamente via clique de botão do usuário com proteção contra travamento
  Future<AuthorizationStatus> requestPermissionExplicitly() async {
    try {
      final settings = await _fcm
          .requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      )
          .timeout(const Duration(seconds: 5));

      _ref.read(pushPermissionStatusProvider.notifier).state =
          settings.authorizationStatus;
      debugPrint(
          '[FCM] Permissão solicitada pelo usuário: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        unawaited(syncToken());
      }

      return settings.authorizationStatus;
    } catch (e) {
      debugPrint('[FCM] Erro ao solicitar permissão de notificação: $e');
      try {
        final current = await _fcm
            .getNotificationSettings()
            .timeout(const Duration(seconds: 2));
        _ref.read(pushPermissionStatusProvider.notifier).state =
            current.authorizationStatus;
        return current.authorizationStatus;
      } catch (_) {
        return AuthorizationStatus.denied;
      }
    }
  }

  /// Obtém o FCM token atual do dispositivo e envia para o Postgres via backend com timeout
  Future<String?> syncToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      String? token;
      try {
        token = await _fcm
            .getToken()
            .timeout(const Duration(seconds: 5), onTimeout: () {
          debugPrint('[FCM] getToken timeout após 5s.');
          return null;
        });
      } catch (tokenErr) {
        debugPrint('[FCM] Erro ao recuperar token FCM: $tokenErr');
      }

      if (token != null && token.isNotEmpty) {
        _fcmToken = token;
        _ref.read(currentFcmTokenProvider.notifier).state = token;
        debugPrint('[FCM] Token obtido com sucesso: $token');
        await _sendTokenToBackend(token);
        return token;
      }
    } catch (e) {
      debugPrint('[FCM] Erro durante sincronização do token: $e');
    }
    return null;
  }

  /// Desinscreve o token no logout para evitar notificações para usuário deslogado
  Future<void> unregisterToken() async {
    try {
      if (_fcmToken != null) {
        final http = _ref.read(httpServiceProvider);
        await http.patch('/auth/fcm-token', data: {'fcmToken': null});
        try {
          await _fcm.deleteToken().timeout(const Duration(seconds: 3));
        } catch (_) {}
        _fcmToken = null;
        _ref.read(currentFcmTokenProvider.notifier).state = null;
        debugPrint('[FCM] Token removido com sucesso no logout.');
      }
    } catch (e) {
      debugPrint('[FCM] Erro ao remover token no logout: $e');
    }
  }

  /// Envia o token FCM para o endpoint PATCH /api/auth/fcm-token
  Future<void> _sendTokenToBackend(String? token) async {
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
