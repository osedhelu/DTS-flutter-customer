import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dts_customer/features/tracking/domain/entities/tracking_data.dart';
import 'package:dts_customer/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:dts_customer/features/tracking/domain/usecases/get_tracking_usecase.dart';

class MockTrackingRepository extends Mock implements TrackingRepository {}

void main() {
  late MockTrackingRepository repository;
  late GetTrackingUseCase useCase;

  setUp(() {
    repository = MockTrackingRepository();
    useCase = GetTrackingUseCase(repository);
  });

  test('get_tracking_usecase_test', () async {
    const tracking = TrackingData(
      orderId: 42,
      status: 'ON_THE_WAY',
      driverLatitude: 4.71,
      driverLongitude: -74.07,
    );

    when(() => repository.getTracking(42)).thenAnswer((_) async => tracking);

    final result = await useCase(42);

    expect(result.status, 'ON_THE_WAY');
    expect(result.driverLatitude, 4.71);
    verify(() => repository.getTracking(42)).called(1);
  });
}
