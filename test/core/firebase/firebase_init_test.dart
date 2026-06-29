import 'package:dts_customer/core/firebase/firebase_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

void main() {
  test('firebase_init_test', () async {
    final messaging = MockFirebaseMessaging();
    when(() => messaging.requestPermission()).thenAnswer((_) async => const NotificationSettings(
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
        ));
    when(() => messaging.getToken()).thenAnswer((_) async => 'mock-token');

    final service = FirebaseServiceImpl(
      messaging: messaging,
      initializeApp: () async {},
    );

    await service.initialize();
    final token = await service.getFcmToken();

    expect(token, 'mock-token');
    verify(() => messaging.requestPermission()).called(1);
  });
}
