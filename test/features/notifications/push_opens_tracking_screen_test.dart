import 'package:dts_customer/core/firebase/firebase_service.dart';
import 'package:dts_customer/features/notifications/application/push_notification_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseService extends Mock implements FirebaseService {}

void main() {
  test('push_opens_tracking_screen_test', () {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/tracking/:orderId',
          builder: (_, state) => Text('tracking-${state.pathParameters['orderId']}'),
        ),
      ],
    );

    final handler = PushNotificationHandler(
      firebaseService: MockFirebaseService(),
      navigate: router.go,
    );

    attachPushNavigation(handler: handler, router: router);

    handler.handleTap(
      const PushNotificationPayload(orderId: 88, type: 'ON_THE_WAY'),
    );

    expect(router.routeInformationProvider.value.uri.path, '/tracking/88');
  });
}
