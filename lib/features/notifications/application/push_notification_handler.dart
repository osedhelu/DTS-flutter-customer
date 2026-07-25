import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart' show SchedulerPhase;
import 'package:flutter/widgets.dart';
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

  bool get isChat =>
      type == 'chat_message' || type == 'CHAT_MESSAGE';

  String get location {
    if (orderId <= 0) return '';
    return isChat ? '/orders/$orderId/chat' : '/tracking/$orderId';
  }

  factory PushNotificationPayload.fromMessage(RemoteMessage message) {
    final data = message.data;
    final rawType = data['type']?.toString().trim().isNotEmpty == true
        ? data['type']!.toString().trim()
        : (data['notification_type']?.toString().trim() ?? '');
    return PushNotificationPayload(
      orderId: int.tryParse(data['order_id']?.toString() ?? '') ?? 0,
      type: rawType,
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
  void Function(String location)? _navigate;

  final StreamController<PushNotificationPayload> _tapController =
      StreamController<PushNotificationPayload>.broadcast();

  /// Tap ocurrido antes de que alguien escuche (cold start / race).
  PushNotificationPayload? _pendingTap;

  Stream<PushNotificationPayload> get onNotificationTap => _tapController.stream;

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;

  /// Inyecta navegación directa (p. ej. `router.go`) tras montar el router.
  void bindNavigate(void Function(String location) navigate) {
    _navigate = navigate;
    final pending = takePendingTap();
    if (pending != null) {
      _dispatch(pending);
    }
  }

  PushNotificationPayload? takePendingTap() {
    final pending = _pendingTap;
    _pendingTap = null;
    return pending;
  }

  Future<void> initialize({bool processLaunchMessages = true}) async {
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
          playSound: true,
        ),
      );
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'order_chat',
          'Chat de pedidos',
          description: 'Mensajes del chat del pedido',
          importance: Importance.max,
          playSound: true,
        ),
      );
    }

    await _firebaseService.requestNotificationPermissionIfNeeded();

    _foregroundSub = _firebaseService.onMessage.listen(_onForegroundMessage);
    _openedSub =
        _firebaseService.onMessageOpenedApp.listen(_onMessageOpenedApp);

    if (processLaunchMessages) {
      await consumeLaunchMessages();
    }
  }

  /// Procesa el mensaje que abrió la app (FCM o notificación local).
  Future<void> consumeLaunchMessages() async {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _onMessageOpenedApp(initial);
    }

    final launch = await _localNotifications.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      final payload = launch!.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        _handlePayload(payload);
      }
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
          importance: isChat ? Importance.max : Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
        ),
      ),
      payload: _encodePayload(payload),
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    _dispatch(PushNotificationPayload.fromMessage(message));
  }

  void handleBackgroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Background push: ${message.data}');
    }
  }

  void handleTap(PushNotificationPayload payload) => _dispatch(payload);

  void _handlePayload(String encoded) {
    final parts = encoded.split('|');
    if (parts.length != 2) return;
    final orderId = int.tryParse(parts[0]) ?? 0;
    _dispatch(PushNotificationPayload(orderId: orderId, type: parts[1]));
  }

  String _encodePayload(PushNotificationPayload payload) =>
      '${payload.orderId}|${payload.type}';

  void _dispatch(PushNotificationPayload payload) {
    if (!_tapController.isClosed) {
      _tapController.add(payload);
    }
    final location = payload.location;
    if (location.isEmpty) return;

    final navigate = _navigate;
    if (navigate != null) {
      navigate(location);
      return;
    }
    _pendingTap = payload;
  }
}

/// Navega cuando el router ya no está en splash/login (cold start).
void navigatePushDestination(GoRouter router, String location) {
  if (location.isEmpty) return;

  var attempts = 0;
  void attempt() {
    attempts++;
    String loc = '/';
    try {
      loc = router.routerDelegate.currentConfiguration.uri.path;
    } catch (_) {
      loc = '/';
    }
    final waitingGate = loc == '/splash' || loc == '/login';
    if (waitingGate && attempts < 60) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(milliseconds: 16), attempt);
      });
      return;
    }
    router.go(location);
  }

  final binding = WidgetsBinding.instance;
  if (binding.schedulerPhase == SchedulerPhase.idle) {
    attempt();
  } else {
    binding.addPostFrameCallback((_) => attempt());
  }
}

void attachPushNavigation({
  required PushNotificationHandler handler,
  required GoRouter router,
}) {
  // Una sola vía: bindNavigate. El stream sigue disponible para tests/observabilidad.
  handler.bindNavigate(
    (location) => navigatePushDestination(router, location),
  );
}
