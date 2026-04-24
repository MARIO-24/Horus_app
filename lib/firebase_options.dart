// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  INSTRUCCIONES:                                                          ║
// ║  Este archivo es un TEMPLATE.  Debes reemplazar los valores              ║
// ║  YOUR_* con los datos reales de tu proyecto Firebase.                    ║
// ║                                                                          ║
// ║  Pasos:                                                                  ║
// ║  1. Ve a https://console.firebase.google.com                             ║
// ║  2. Crea (o abre) tu proyecto                                            ║
// ║  3. Añade una app Android con paquete: com.horusapp.horus_app            ║
// ║  4. Descarga google-services.json → colócalo en android/app/             ║
// ║  5. Habilita Authentication (Email/Password) y Cloud Firestore           ║
// ║  OPCIONAL: usa `flutterfire configure` para generar este archivo auto.   ║
// ╚══════════════════════════════════════════════════════════════════════════╝

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions no está configurado para web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no está configurado para '
          '${defaultTargetPlatform.name}.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAcWMwCILI3za2x3h9RNcikwkg2LPUWtiw',
    appId: '1:981139482230:android:0befbb94de5bdae8952157',
    messagingSenderId: '981139482230',
    projectId: 'horusapp-d4976',
    storageBucket: 'horusapp-d4976.firebasestorage.app',
  );

  // iOS not configured — add GoogleService-Info.plist and fill in values if needed.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '981139482230',
    projectId: 'horusapp-d4976',
    storageBucket: 'horusapp-d4976.firebasestorage.app',
    iosBundleId: 'com.horusapp.horusApp',
  );
}
