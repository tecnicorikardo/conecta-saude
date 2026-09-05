import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Configurações do Firebase para o projeto conecta-hospital
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCfahJx22q7Be42eNAOW7xV3hWTLmemWII',
    authDomain: 'conecta-hospital.firebaseapp.com',
    projectId: 'conecta-hospital',
    storageBucket: 'conecta-hospital.firebasestorage.app',
    messagingSenderId: '779815545602',
    appId: '1:779815545602:web:dfb3580daef5888122701b',
    measurementId: 'G-RVYFQW2HQH',
  );

  // Android: adicionar google-services.json em android/app/ e atualizar abaixo
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCfahJx22q7Be42eNAOW7xV3hWTLmemWII',
    authDomain: 'conecta-hospital.firebaseapp.com',
    projectId: 'conecta-hospital',
    storageBucket: 'conecta-hospital.firebasestorage.app',
    messagingSenderId: '779815545602',
    appId: '1:779815545602:android:XXXXXXXXXXXXXXXX', // substituir após baixar google-services.json
  );

  // iOS: adicionar GoogleService-Info.plist e atualizar abaixo
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCfahJx22q7Be42eNAOW7xV3hWTLmemWII',
    authDomain: 'conecta-hospital.firebaseapp.com',
    projectId: 'conecta-hospital',
    storageBucket: 'conecta-hospital.firebasestorage.app',
    messagingSenderId: '779815545602',
    appId: '1:779815545602:ios:XXXXXXXXXXXXXXXX', // substituir após baixar GoogleService-Info.plist
    iosClientId: 'XXXXXXXXXXXXXXXX', // substituir
    iosBundleId: 'com.conectasaude.app',
  );
}
