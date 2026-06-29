import 'package:dts_customer/core/di/providers.dart';
import 'package:dts_customer/core/firebase/firebase_service.dart';
import 'package:dts_customer/features/notifications/application/push_notification_handler.dart';
import 'package:dts_customer/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockFirebaseService extends Mock implements FirebaseService {}

class MockPushNotificationHandler extends Mock implements PushNotificationHandler {}

void main() {
  testWidgets('app boots with provider scope', (tester) async {
    final firebase = MockFirebaseService();
    final pushHandler = MockPushNotificationHandler();

    when(() => firebase.initialize()).thenAnswer((_) async {});
    when(() => pushHandler.initialize()).thenAnswer((_) async {});
    when(() => pushHandler.onNotificationTap).thenAnswer(
      (_) => const Stream.empty(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseServiceProvider.overrideWithValue(firebase),
          pushNotificationHandlerProvider.overrideWithValue(pushHandler),
        ],
        child: const DtsCustomerApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
