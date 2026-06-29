import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

typedef FirebaseBackgroundHandler = Future<void> Function(RemoteMessage message);

abstract class FirebaseService {
  Future<void> initialize();

  Future<String?> getFcmToken();

  Stream<RemoteMessage> get onMessage;

  Stream<RemoteMessage> get onMessageOpenedApp;

  void setBackgroundMessageHandler(FirebaseBackgroundHandler handler);
}

class FirebaseServiceImpl implements FirebaseService {
  FirebaseServiceImpl({
    FirebaseMessaging? messaging,
    Future<void> Function()? initializeApp,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _initializeApp = initializeApp ?? _defaultInitialize;

  final FirebaseMessaging _messaging;
  final Future<void> Function() _initializeApp;

  static Future<void> _defaultInitialize() {
    return Firebase.initializeApp(options: _defaultOptions);
  }

  static const FirebaseOptions _defaultOptions = FirebaseOptions(
    apiKey: 'test-api-key',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'dts-customer-test',
  );

  @override
  Future<void> initialize() async {
    if (kIsWeb) return;
    await _initializeApp();
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
