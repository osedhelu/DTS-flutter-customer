import 'package:dts_customer/features/rides/domain/entities/fare_quote.dart';
import 'package:dts_customer/features/rides/domain/entities/ride.dart';
import 'package:dts_customer/features/rides/domain/entities/ride_location.dart';
import 'package:dts_customer/features/rides/domain/entities/ride_request.dart';
import 'package:dts_customer/features/rides/domain/entities/ride_status.dart';
import 'package:dts_customer/features/rides/domain/entities/ride_tracking_update.dart';
import 'package:dts_customer/features/rides/domain/repositories/rides_repository.dart';
import 'package:dts_customer/features/rides/domain/usecases/cancel_ride_usecase.dart';
import 'package:dts_customer/features/rides/domain/usecases/create_ride_usecase.dart';
import 'package:dts_customer/features/rides/domain/usecases/get_ride_usecase.dart';
import 'package:dts_customer/features/rides/domain/usecases/list_rides_usecase.dart';
import 'package:dts_customer/features/rides/domain/usecases/quote_ride_usecase.dart';
import 'package:dts_customer/features/rides/domain/usecases/watch_ride_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRidesRepository extends Mock implements RidesRepository {}

const _pickup = RideLocation(
  address: 'Calle 1',
  latitude: 4.711,
  longitude: -74.0721,
);
const _dropoff = RideLocation(
  address: 'Calle 2',
  latitude: 4.65,
  longitude: -74.08,
);

Ride _ride({RideStatus status = RideStatus.searchingDriver, int id = 7}) {
  return Ride(
    id: id,
    status: status,
    pickup: _pickup,
    dropoff: _dropoff,
    total: 12500,
  );
}

void main() {
  late MockRidesRepository repository;

  setUp(() {
    repository = MockRidesRepository();
  });

  test('quote_ride_usecase_delegates_to_repository_test', () async {
    const params = QuoteRideParams(pickup: _pickup, dropoff: _dropoff);
    final quote = FareQuote(
      quoteId: 'q-1',
      estimatedDistanceKm: 6.4,
      estimatedDurationMinutes: 18,
      fareBreakdown: const FareBreakdown(
        base: 2.5,
        distance: 1.5,
        time: 0.5,
        surge: 0,
        total: 4.5,
      ),
      expiresAt: DateTime(2026, 7, 12, 21, 5),
      zoneName: 'Centro',
    );
    when(() => repository.quoteRide(params)).thenAnswer((_) async => quote);

    final result = await QuoteRideUseCase(repository).call(params);

    expect(result, quote);
    verify(() => repository.quoteRide(params)).called(1);
  });

  test('create_ride_usecase_delegates_to_repository_test', () async {
    const params = CreateRideParams(
      pickup: _pickup,
      dropoff: _dropoff,
      estimatedDurationMinutes: 18,
      estimatedDistanceKm: 6.4,
    );
    final ride = _ride();
    when(() => repository.createRide(params)).thenAnswer((_) async => ride);

    final result = await CreateRideUseCase(repository).call(params);

    expect(result, ride);
    verify(() => repository.createRide(params)).called(1);
  });

  test('cancel_ride_usecase_delegates_to_repository_test', () async {
    final ride = _ride(status: RideStatus.cancelled);
    when(() => repository.cancelRide(7)).thenAnswer((_) async => ride);

    final result = await CancelRideUseCase(repository).call(7);

    expect(result.status, RideStatus.cancelled);
    verify(() => repository.cancelRide(7)).called(1);
  });

  test('get_ride_usecase_delegates_to_repository_test', () async {
    final ride = _ride();
    when(() => repository.getRide(7)).thenAnswer((_) async => ride);

    final result = await GetRideUseCase(repository).call(7);

    expect(result.id, 7);
    verify(() => repository.getRide(7)).called(1);
  });

  test('list_rides_usecase_delegates_to_repository_test', () async {
    when(() => repository.listRides())
        .thenAnswer((_) async => [_ride(id: 1), _ride(id: 2)]);

    final result = await ListRidesUseCase(repository).call();

    expect(result, hasLength(2));
    verify(() => repository.listRides()).called(1);
  });

  test('watch_ride_usecase_delegates_to_repository_test', () {
    const update = RideTrackingUpdate(rideId: 7);
    when(() => repository.watchRide(7)).thenAnswer((_) => Stream.value(update));

    final stream = WatchRideUseCase(repository).call(7);

    expect(
      stream,
      emitsInOrder([
        isA<RideTrackingUpdate>().having((u) => u.rideId, 'rideId', 7),
      ]),
    );
  });
}
