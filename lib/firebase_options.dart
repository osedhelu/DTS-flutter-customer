import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase config for DTS Customer (project discorp-4a37b).
/// Android/iOS package: com.osedhelu.dts
abstract final class DefaultFirebaseOptions {
  /// Web OAuth client (type 3) — required by google_sign_in for ID token.
  static const String googleServerClientId =
      '887878350921-gq6lg3en3nldle72d9r751u8uhn75dn2.apps.googleusercontent.com';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web no está soportado en DTS Customer.');
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError(
          'Plataforma no soportada: $defaultTargetPlatform',
        ),
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAiWdADnizuPi_5PyH3yNmV523CNlu6jMo',
    appId: '1:887878350921:android:6cecda7e50f0414107a798',
    messagingSenderId: '887878350921',
    projectId: 'discorp-4a37b',
    storageBucket: 'discorp-4a37b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCGhDym4H6gaJe8zIUZEA6ln0xDl1o3Hxo',
    appId: '1:887878350921:ios:cb3b0e6900a219ff07a798',
    messagingSenderId: '887878350921',
    projectId: 'discorp-4a37b',
    storageBucket: 'discorp-4a37b.firebasestorage.app',
    iosBundleId: 'com.osedhelu.dts',
    iosClientId:
        '887878350921-nefem02td9h6vouu22thtca9qv7akah8.apps.googleusercontent.com',
  );
}
