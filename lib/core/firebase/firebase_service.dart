import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

typedef FirebaseBackgroundHandler = Future<void> Function(RemoteMessage message);

abstract class FirebaseService {
  Future<void> initialize();

  Future<void> requestNotificationPermissionIfNeeded();

  Future<String?> getFcmToken();

  Stream<RemoteMessage> get onMessage;

  Stream<RemoteMessage> get onMessageOpenedApp;

  void setBackgroundMessageHandler(FirebaseBackgroundHandler handler);
}

class FirebaseServiceImpl implements FirebaseService {
  FirebaseServiceImpl({
    FirebaseMessaging? messaging,
    Future<void> Function()? initializeApp,
  })  : _messagingOverride = messaging,
        _initializeApp = initializeApp ??
            (() async {
              await Firebase.initializeApp(
                options: DefaultFirebaseOptions.currentPlatform,
              );
            });

  final FirebaseMessaging? _messagingOverride;
  final Future<void> Function() _initializeApp;

  FirebaseMessaging get _messaging =>
      _messagingOverride ?? FirebaseMessaging.instance;

  @override
  Future<void> initialize() async {
    if (kIsWeb) return;
    if (Firebase.apps.isNotEmpty) return;
    await _initializeApp();
  }

  @override
  Future<void> requestNotificationPermissionIfNeeded() async {
    if (kIsWeb) return;
    await _messaging.requestPermission();
  }

  @override
  Future<String?> getFcmToken() => _messaging.getToken();

  @override
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  @override
  void setBackgroundMessageHandler(FirebaseBackgroundHandler handler) {
    FirebaseMessaging.onBackgroundMessage(handler);
  }
}
