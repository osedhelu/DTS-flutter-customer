import 'package:dts_customer/core/di/providers.dart';
import 'package:dts_customer/core/firebase/firebase_service.dart';
import 'package:dts_customer/core/network/token_storage.dart';
import 'package:dts_customer/features/auth/domain/repositories/auth_repository.dart';
import 'package:dts_customer/features/notifications/application/push_notification_handler.dart';
import 'package:dts_customer/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseService extends Mock implements FirebaseService {}

class MockPushNotificationHandler extends Mock
    implements PushNotificationHandler {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('app boots with provider scope', (tester) async {
    final firebase = MockFirebaseService();
    final pushHandler = MockPushNotificationHandler();
    final authRepository = MockAuthRepository();

    when(() => firebase.initialize()).thenAnswer((_) async {});
    when(() => pushHandler.initialize()).thenAnswer((_) async {});
    when(() => pushHandler.onNotificationTap).thenAnswer(
      (_) => const Stream.empty(),
    );
    when(() => authRepository.isAuthenticated()).thenAnswer((_) async => false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseServiceProvider.overrideWithValue(firebase),
          pushNotificationHandlerProvider.overrideWithValue(pushHandler),
          authRepositoryProvider.overrideWithValue(authRepository),
          tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        ],
        child: const DtsCustomerApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
