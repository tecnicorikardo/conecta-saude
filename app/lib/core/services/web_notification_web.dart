import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('showHospitalNotification')
external void _showHospitalNotification(
    JSString title, JSString body, JSString tag, JSString url, JSString? type);

void showNativeNotificationWeb(String title, String body, {String? tag, String? url, String? type}) {
  try {
    _showHospitalNotification(
      title.toJS,
      body.toJS,
      (tag ?? 'conecta_saude').toJS,
      (url ?? '/').toJS,
      type?.toJS,
    );
  } catch (e) {
    debugPrint('Erro ao chamar showHospitalNotification via JS: $e');
  }
}
