import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// VAPID key para Firebase Web Push (Web Push Certificate).
/// Obtida em: Firebase Console → Project Settings → Cloud Messaging
///             → Web configuration → Web Push certificates
/// IMPORTANTE: Esta chave deve ser preenchida com a chave do projeto real.
/// A VAPID key é obrigatória para receber notificações push no navegador Web e PWA.
const String kFirebaseWebVapidKey =
    'BMQUpfbg_qto7ISLf4OLd5MVn7pscrHlmX5EYk6GXslBPI32hbUQipuMN7b6g9-o4l8NvI5nZ0fLNzUjARIdC-M';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCfahJx22q7Be42eNAOW7xV3hWTLmemWII',
    appId: '1:779815545602:web:dfb3580daef5888122701b',
    messagingSenderId: '779815545602',
    projectId: 'conecta-hospital',
    authDomain: 'conecta-hospital.firebaseapp.com',
    storageBucket: 'conecta-hospital.firebasestorage.app',
    measurementId: 'G-RVYFQW2HQH',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCfahJx22q7Be42eNAOW7xV3hWTLmemWII',
    appId: '1:779815545602:web:dfb3580daef5888122701b',
    messagingSenderId: '779815545602',
    projectId: 'conecta-hospital',
    authDomain: 'conecta-hospital.firebaseapp.com',
    storageBucket: 'conecta-hospital.firebasestorage.app',
  );
}
