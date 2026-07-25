import 'package:dts_customer/core/firebase/firebase_service.dart';
import 'package:dts_customer/features/notifications/application/push_notification_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseService extends Mock implements FirebaseService {}

void main() {
  testWidgets('push_opens_tracking_screen_test', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const Text('home')),
        GoRoute(
          path: '/tracking/:orderId',
          builder: (_, state) =>
              Text('tracking-${state.pathParameters['orderId']}'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final handler = PushNotificationHandler(
      firebaseService: MockFirebaseService(),
    );
    attachPushNavigation(handler: handler, router: router);

    handler.handleTap(
      const PushNotificationPayload(orderId: 88, type: 'ON_THE_WAY'),
    );
    await tester.pumpAndSettle();

    expect(find.text('tracking-88'), findsOneWidget);
  });
}
