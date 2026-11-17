import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Konfigurasi Firebase untuk Android & Web (`dekorin-app`).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCNgDh9f6BpEtMfyyeD6pQjerZAyXiApXI',
    authDomain: 'dekorin-app.firebaseapp.com',
    projectId: 'dekorin-app',
    storageBucket: 'dekorin-app.firebasestorage.app',
    messagingSenderId: '448756050947',
    appId: '1:448756050947:web:b2f810cb1da53624b13236',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBV72ymeoTes6uu9sO9l3f_DAEHEBzBbaw',
    appId: '1:448756050947:android:10eaeaf2d12846e8b13236',
    messagingSenderId: '448756050947',
    projectId: 'dekorin-app',
    storageBucket: 'dekorin-app.firebasestorage.app',
  );
}
