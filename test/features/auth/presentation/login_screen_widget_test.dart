import 'package:dts_customer/core/di/providers.dart';
import 'package:dts_customer/core/firebase/firebase_service.dart';
import 'package:dts_customer/features/auth/application/post_auth_service.dart';
import 'package:dts_customer/features/auth/domain/entities/auth_session.dart';
import 'package:dts_customer/features/auth/domain/usecases/login_usecase.dart';
import 'package:dts_customer/features/auth/presentation/screens/login_screen.dart';
import 'package:dts_customer/features/notifications/domain/repositories/device_token_repository.dart';
import 'package:dts_customer/features/notifications/domain/usecases/register_fcm_token_usecase.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_providers.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockDeviceTokenRepository extends Mock implements DeviceTokenRepository {}

PostAuthService _testPostAuthService() {
  final messaging = MockFirebaseMessaging();
  when(() => messaging.getToken()).thenAnswer((_) async => null);
  when(() => messaging.requestPermission()).thenAnswer(
    (_) async => const NotificationSettings(
      authorizationStatus: AuthorizationStatus.authorized,
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.notSupported,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.notSupported,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.always,
      sound: AppleNotificationSetting.enabled,
      criticalAlert: AppleNotificationSetting.notSupported,
      timeSensitive: AppleNotificationSetting.notSupported,
      providesAppNotificationSettings: AppleNotificationSetting.notSupported,
    ),
  );
  return PostAuthService(
    registerFcmTokenUseCase: RegisterFcmTokenUseCase(MockDeviceTokenRepository()),
    firebaseService: FirebaseServiceImpl(
      messaging: messaging,
      initializeApp: () async {},
    ),
  );
}

void main() {
  late MockLoginUseCase loginUseCase;

  setUp(() {
    loginUseCase = MockLoginUseCase();
  });

  testWidgets('login_screen_widget_test', (tester) async {
    when(
      () => loginUseCase.call(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        role: 'customer',
        userId: 1,
      ),
    );

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('stores-page')),
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          loginUseCaseProvider.overrideWithValue(loginUseCase),
          postAuthServiceProvider.overrideWith((_) => _testPostAuthService()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('login_username')), 'ana');
    await tester.enterText(find.byKey(const Key('login_password')), 'secret');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    verify(
      () => loginUseCase.call(username: 'ana', password: 'secret'),
    ).called(1);
    expect(find.text('No se pudo iniciar sesión'), findsNothing);
  });
}
