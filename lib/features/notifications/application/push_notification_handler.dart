import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/firebase/firebase_service.dart';

class PushNotificationPayload {
  const PushNotificationPayload({
    required this.orderId,
    required this.type,
  });

  final int orderId;
  final String type;

  factory PushNotificationPayload.fromMessage(RemoteMessage message) {
    final data = message.data;
    return PushNotificationPayload(
      orderId: int.parse(data['order_id']?.toString() ?? '0'),
      type: data['type']?.toString() ?? '',
    );
  }
}

class PushNotificationHandler {
  PushNotificationHandler({
    required FirebaseService firebaseService,
    FlutterLocalNotificationsPlugin? localNotifications,
    void Function(String location)? navigate,
  })  : _firebaseService = firebaseService,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin(),
        _navigate = navigate;

  final FirebaseService _firebaseService;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final void Function(String location)? _navigate;

  final StreamController<PushNotificationPayload> _tapController =
      StreamController<PushNotificationPayload>.broadcast();

  Stream<PushNotificationPayload> get onNotificationTap => _tapController.stream;

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null) return;
        _handlePayload(payload);
      },
    );

    _foregroundSub = _firebaseService.onMessage.listen(_onForegroundMessage);
    _openedSub =
        _firebaseService.onMessageOpenedApp.listen(_onMessageOpenedApp);
  }

  void dispose() {
    _foregroundSub?.cancel();
    _openedSub?.cancel();
    _tapController.close();
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final payload = PushNotificationPayload.fromMessage(message);
    await _localNotifications.show(
      payload.orderId,
      message.notification?.title ?? 'Actualización de pedido',
      message.notification?.body ?? payload.type,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'order_updates',
          'Pedidos',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: _encodePayload(payload),
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    final payload = PushNotificationPayload.fromMessage(message);
    _openTracking(payload);
  }

  void handleBackgroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Background push: ${message.data}');
    }
  }

  void handleTap(PushNotificationPayload payload) => _openTracking(payload);

  void _handlePayload(String encoded) {
    final parts = encoded.split('|');
    if (parts.length != 2) return;
    _openTracking(
      PushNotificationPayload(orderId: int.parse(parts[0]), type: parts[1]),
    );
  }

  String _encodePayload(PushNotificationPayload payload) =>
      '${payload.orderId}|${payload.type}';

  void _openTracking(PushNotificationPayload payload) {
    _tapController.add(payload);
    if (payload.orderId <= 0) return;
    final location = '/tracking/${payload.orderId}';
    _navigate?.call(location);
  }
}

void attachPushNavigation({
  required PushNotificationHandler handler,
  required GoRouter router,
}) {
  handler.onNotificationTap.listen((payload) {
    if (payload.orderId <= 0) return;
    router.go('/tracking/${payload.orderId}');
  });
}
