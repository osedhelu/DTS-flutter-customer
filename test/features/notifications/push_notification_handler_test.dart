import 'package:dts_customer/core/firebase/firebase_service.dart';
import 'package:dts_customer/features/notifications/application/push_notification_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseService extends Mock implements FirebaseService {}

class FakeRemoteMessage extends Fake implements RemoteMessage {
  FakeRemoteMessage(this.data, {this.title, this.body});

  @override
  final Map<String, dynamic> data;

  @override
  RemoteNotification? get notification => RemoteNotification(
        title: title,
        body: body,
      );

  final String? title;
  final String? body;
}

void main() {
  late MockFirebaseService firebaseService;
  late PushNotificationHandler handler;
  String? navigatedTo;

  setUp(() {
    firebaseService = MockFirebaseService();
    navigatedTo = null;
    handler = PushNotificationHandler(
      firebaseService: firebaseService,
      navigate: (location) => navigatedTo = location,
    );
  });

  test('tap status push navega a tracking', () {
    handler.handleTap(
      const PushNotificationPayload(orderId: 15, type: 'ON_THE_WAY'),
    );

    expect(navigatedTo, '/tracking/15');
  });

  test('tap chat_message navega a chat del pedido', () {
    handler.handleTap(
      const PushNotificationPayload(orderId: 42, type: 'chat_message'),
    );

    expect(navigatedTo, '/orders/42/chat');
  });

  test('fromMessage usa notification_type si type viene vacío', () {
    final payload = PushNotificationPayload.fromMessage(
      FakeRemoteMessage({
        'order_id': '56',
        'notification_type': 'chat_message',
      }),
    );

    expect(payload.isChat, isTrue);
    expect(payload.location, '/orders/56/chat');
  });

  test('pending tap se aplica al bindNavigate (cold start)', () {
    final coldHandler = PushNotificationHandler(
      firebaseService: firebaseService,
    );

    coldHandler.handleTap(
      const PushNotificationPayload(orderId: 56, type: 'chat_message'),
    );
    expect(coldHandler.takePendingTap()?.orderId, 56);

    coldHandler.handleTap(
      const PushNotificationPayload(orderId: 56, type: 'chat_message'),
    );

    String? bound;
    coldHandler.bindNavigate((location) => bound = location);
    expect(bound, '/orders/56/chat');
  });

  testWidgets('attachPushNavigation abre chat vía router.go', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const Text('home')),
        GoRoute(
          path: '/orders/:orderId/chat',
          builder: (_, state) =>
              Text('chat-${state.pathParameters['orderId']}'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final h = PushNotificationHandler(firebaseService: firebaseService);
    attachPushNavigation(handler: h, router: router);

    h.handleTap(
      const PushNotificationPayload(orderId: 56, type: 'chat_message'),
    );
    await tester.pumpAndSettle();

    expect(find.text('chat-56'), findsOneWidget);
  });
}
