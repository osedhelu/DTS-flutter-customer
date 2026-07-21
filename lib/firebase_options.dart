import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase config for DTS Customer (project dtsdrop-85330).
/// Android/iOS package: com.osedhelu.dts
abstract final class DefaultFirebaseOptions {
  /// Web OAuth client (type 3) — required by google_sign_in for ID token.
  static const String googleServerClientId =
      '1015036938407-3b42tv87mauud225f3vfett7c5rtogof.apps.googleusercontent.com';

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
    apiKey: 'AIzaSyBj-DmYwHfG6kvSKoCF-kqC4tvt3v9pQBI',
    appId: '1:1015036938407:android:987797af4288c33c08b382',
    messagingSenderId: '1015036938407',
    projectId: 'dtsdrop-85330',
    storageBucket: 'dtsdrop-85330.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyANpS7RJ7r3vkAwzmaMlnYm-tJKq4NP2Kw',
    appId: '1:1015036938407:ios:15899df8d947799f08b382',
    messagingSenderId: '1015036938407',
    projectId: 'dtsdrop-85330',
    storageBucket: 'dtsdrop-85330.firebasestorage.app',
    iosBundleId: 'com.osedhelu.dts',
    iosClientId:
        '1015036938407-5sv7g0c6ujt98g2imkq3u6qlddolij9s.apps.googleusercontent.com',
  );
}
