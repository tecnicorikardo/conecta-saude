import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyDummyKeyForConectaHospitalSus',
    appId: '1:1029384756:web:abcdef123456',
    messagingSenderId: '1029384756',
    projectId: 'conecta-hospital',
    authDomain: 'conecta-hospital.firebaseapp.com',
    storageBucket: 'conecta-hospital.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDummyKeyForConectaHospitalSus',
    appId: '1:1029384756:android:abcdef123456',
    messagingSenderId: '1029384756',
    projectId: 'conecta-hospital',
    storageBucket: 'conecta-hospital.appspot.com',
  );
}
