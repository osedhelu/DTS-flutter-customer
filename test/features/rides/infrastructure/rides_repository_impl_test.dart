import 'package:dts_customer/core/network/token_storage.dart';
import 'package:dts_customer/features/rides/domain/entities/fare_quote.dart';
import 'package:dts_customer/features/rides/domain/entities/ride_location.dart';
import 'package:dts_customer/features/rides/domain/entities/ride_request.dart';
import 'package:dts_customer/features/rides/domain/entities/ride_status.dart';
import 'package:dts_customer/features/rides/domain/entities/ride_tracking_update.dart';
import 'package:dts_customer/features/rides/infrastructure/datasources/rides_remote_datasource.dart';
import 'package:dts_customer/features/rides/infrastructure/datasources/rides_ws_datasource.dart';
import 'package:dts_customer/features/rides/infrastructure/models/fare_quote_dto.dart';
import 'package:dts_customer/features/rides/infrastructure/models/ride_dto.dart';
import 'package:dts_customer/features/rides/infrastructure/repositories/rides_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRidesRemoteDataSource extends Mock implements RidesRemoteDataSource {}

class MockRidesWsDataSource extends Mock implements RidesWsDataSource {}

class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage(this.token);

  String? token;

  @override
  Future<String?> getAccessToken() async => token;

  @override
  Future<String?> getRefreshToken() async => null;

  @override
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {}

  @override
  Future<void> clear() async {}
}

const _pickup = RideLocation(address: 'A', latitude: 1, longitude: 2);
const _dropoff = RideLocation(address: 'B', latitude: 3, longitude: 4);

void main() {
  late MockRidesRemoteDataSource remote;
  late MockRidesWsDataSource ws;

  setUp(() {
    remote = MockRidesRemoteDataSource();
    ws = MockRidesWsDataSource();
  });

  RidesRepositoryImpl build({String? token = 'jwt'}) {
    return RidesRepositoryImpl(
      remoteDataSource: remote,
      wsDataSource: ws,
      tokenStorage: FakeTokenStorage(token),
    );
  }

  test('rides_repository_quote_maps_dto_to_entity_test', () async {
    const params = QuoteRideParams(pickup: _pickup, dropoff: _dropoff);
    when(() => remote.quoteRide(params)).thenAnswer(
      (_) async => FareQuoteDto(
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
      ),
    );

    final quote = await build().quoteRide(params);

    expect(quote.quoteId, 'q-1');
    expect(quote.estimatedDurationMinutes, 18);
    expect(quote.zoneName, 'Centro');
    verify(() => remote.quoteRide(params)).called(1);
  });

  test('rides_repository_cancel_maps_status_test', () async {
    when(() => remote.cancelRide(7)).thenAnswer(
      (_) async => const RideDto(
        id: 7,
        status: RideStatus.cancelled,
        pickup: _pickup,
        dropoff: _dropoff,
      ),
    );

    final ride = await build().cancelRide(7);

    expect(ride.status, RideStatus.cancelled);
    verify(() => remote.cancelRide(7)).called(1);
  });

  test('rides_repository_list_maps_each_dto_test', () async {
    when(() => remote.listRides()).thenAnswer(
      (_) async => [
        const RideDto(
          id: 1,
          status: RideStatus.rideCompleted,
          pickup: _pickup,
          dropoff: _dropoff,
        ),
        const RideDto(
          id: 2,
          status: RideStatus.searchingDriver,
          pickup: _pickup,
          dropoff: _dropoff,
        ),
      ],
    );

    final rides = await build().listRides();

    expect(rides, hasLength(2));
    expect(rides.first.status, RideStatus.rideCompleted);
    expect(rides.last.isActive, isTrue);
  });

  test('rides_repository_watch_uses_stored_token_test', () async {
    const update = RideTrackingUpdate(
      rideId: 7,
      status: RideStatus.rideInProgress,
    );
    when(() => ws.watchRide(rideId: 7, accessToken: 'jwt'))
        .thenAnswer((_) => Stream.value(update));

    final first = await build().watchRide(7).first;

    expect(first.status, RideStatus.rideInProgress);
    verify(() => ws.watchRide(rideId: 7, accessToken: 'jwt')).called(1);
  });

  test('rides_repository_watch_without_token_is_empty_test', () async {
    expect(await build(token: null).watchRide(7).toList(), isEmpty);
    verifyNever(() => remote.fetchRide(7));
  });
}
