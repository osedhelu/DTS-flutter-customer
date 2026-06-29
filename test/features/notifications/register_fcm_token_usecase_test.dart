import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_customer/features/notifications/domain/repositories/device_token_repository.dart';
import 'package:dts_customer/features/notifications/domain/usecases/register_fcm_token_usecase.dart';

class MockDeviceTokenRepository extends Mock implements DeviceTokenRepository {}

void main() {
  late MockDeviceTokenRepository repository;
  late RegisterFcmTokenUseCase useCase;

  setUp(() {
    repository = MockDeviceTokenRepository();
    useCase = RegisterFcmTokenUseCase(repository);
  });

  test('register_fcm_token_usecase_test', () async {
    when(
      () => repository.registerToken(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
      ),
    ).thenAnswer((_) async {});

    await useCase.call(token: 'fcm-token-abc', platform: 'android');

    verify(
      () => repository.registerToken(
        token: 'fcm-token-abc',
        platform: 'android',
      ),
    ).called(1);
  });
}
