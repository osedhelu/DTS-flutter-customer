import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/firebase/firebase_service.dart';

bool get _isAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

class PushNotificationPayload {
  const PushNotificationPayload({
    required this.orderId,
    required this.type,
  });

  final int orderId;
  final String type;

  bool get isChat => type == 'chat_message';

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
    if (_isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
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

    if (_isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'order_updates',
          'Pedidos',
          description: 'Actualizaciones de estado del pedido',
          importance: Importance.high,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'order_chat',
          'Chat de pedidos',
          description: 'Mensajes del chat con el conductor',
          importance: Importance.high,
        ),
      );
    }

    await _firebaseService.requestNotificationPermissionIfNeeded();

    _foregroundSub = _firebaseService.onMessage.listen(_onForegroundMessage);
    _openedSub =
        _firebaseService.onMessageOpenedApp.listen(_onMessageOpenedApp);

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _onMessageOpenedApp(initial);
    }
  }

  void dispose() {
    _foregroundSub?.cancel();
    _openedSub?.cancel();
    _tapController.close();
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final payload = PushNotificationPayload.fromMessage(message);
    final isChat = payload.isChat;
    await _localNotifications.show(
      isChat ? 100000 + payload.orderId : payload.orderId,
      message.notification?.title ??
          (isChat ? 'Nuevo mensaje' : 'Actualización de pedido'),
      message.notification?.body ??
          (isChat
              ? (message.data['preview']?.toString() ?? payload.type)
              : payload.type),
      NotificationDetails(
        android: AndroidNotificationDetails(
          isChat ? 'order_chat' : 'order_updates',
          isChat ? 'Chat de pedidos' : 'Pedidos',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(presentSound: true),
      ),
      payload: _encodePayload(payload),
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    final payload = PushNotificationPayload.fromMessage(message);
    _openDestination(payload);
  }

  void handleBackgroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Background push: ${message.data}');
    }
  }

  void handleTap(PushNotificationPayload payload) => _openDestination(payload);

  void _handlePayload(String encoded) {
    final parts = encoded.split('|');
    if (parts.length != 2) return;
    _openDestination(
      PushNotificationPayload(orderId: int.parse(parts[0]), type: parts[1]),
    );
  }

  String _encodePayload(PushNotificationPayload payload) =>
      '${payload.orderId}|${payload.type}';

  void _openDestination(PushNotificationPayload payload) {
    _tapController.add(payload);
    if (payload.orderId <= 0) return;
    final location = payload.isChat
        ? '/orders/${payload.orderId}/chat'
        : '/tracking/${payload.orderId}';
    _navigate?.call(location);
  }
}

void attachPushNavigation({
  required PushNotificationHandler handler,
  required GoRouter router,
}) {
  handler.onNotificationTap.listen((payload) {
    if (payload.orderId <= 0) return;
    final location = payload.isChat
        ? '/orders/${payload.orderId}/chat'
        : '/tracking/${payload.orderId}';
    router.go(location);
  });
}
