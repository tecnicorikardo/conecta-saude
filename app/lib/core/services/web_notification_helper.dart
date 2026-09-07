import 'package:flutter/foundation.dart';
import 'web_notification_stub.dart'
    if (dart.library.js_interop) 'web_notification_web.dart';

void notifyHospitalUser(String title, String body, {String? tag, String? url}) {
  if (kIsWeb) {
    showNativeNotificationWeb(title, body, tag: tag, url: url);
  }
}
