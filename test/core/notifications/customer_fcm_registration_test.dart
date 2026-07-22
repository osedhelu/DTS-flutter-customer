import 'package:dts_customer/core/firebase/firebase_service.dart';
import 'package:dts_customer/core/notifications/customer_fcm_registration.dart';
import 'package:dts_customer/features/notifications/domain/repositories/device_token_repository.dart';
import 'package:dts_customer/features/notifications/domain/usecases/register_fcm_token_usecase.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseService extends Mock implements FirebaseService {}

class MockDeviceTokenRepository extends Mock implements DeviceTokenRepository {}

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

void main() {
  late MockFirebaseService firebaseService;
  late MockDeviceTokenRepository tokenRepository;
  late MockFirebaseMessaging messaging;
  late CustomerFcmRegistration registration;

  setUp(() {
    firebaseService = MockFirebaseService();
    tokenRepository = MockDeviceTokenRepository();
    messaging = MockFirebaseMessaging();
    registration = CustomerFcmRegistration(
      firebaseService: firebaseService,
      registerFcmTokenUseCase: RegisterFcmTokenUseCase(tokenRepository),
      messaging: messaging,
    );

    when(() => firebaseService.requestNotificationPermissionIfNeeded())
        .thenAnswer((_) async {});
    when(() => messaging.onTokenRefresh)
        .thenAnswer((_) => const Stream<String>.empty());
  });

  test('register envía token al backend', () async {
    when(() => firebaseService.getFcmToken())
        .thenAnswer((_) async => 'customer-fcm-token');
    when(
      () => tokenRepository.registerToken(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
      ),
    ).thenAnswer((_) async {});

    final ok = await registration.register(apnsAttempts: 1);

    expect(ok, isTrue);
    verify(
      () => tokenRepository.registerToken(
        token: 'customer-fcm-token',
        platform: any(named: 'platform'),
      ),
    ).called(1);
  });

  test('register retorna false si getFcmToken vacío', () async {
    when(() => firebaseService.getFcmToken()).thenAnswer((_) async => null);

    final ok = await registration.register(apnsAttempts: 1);

    expect(ok, isFalse);
    verifyNever(
      () => tokenRepository.registerToken(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
      ),
    );
  });

  test('register no traga: retorna false si el repo falla', () async {
    when(() => firebaseService.getFcmToken()).thenAnswer((_) async => 'tok');
    when(
      () => tokenRepository.registerToken(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
      ),
    ).thenThrow(Exception('api down'));

    final ok = await registration.register(apnsAttempts: 1);

    expect(ok, isFalse);
  });
}
