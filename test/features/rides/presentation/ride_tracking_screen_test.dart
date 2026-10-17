import 'package:dts_customer/core/di/providers.dart';
import 'package:dts_customer/features/rides/domain/entities/ride.dart';
import 'package:dts_customer/features/rides/domain/entities/ride_location.dart';
import 'package:dts_customer/features/rides/domain/entities/ride_status.dart';
import 'package:dts_customer/features/rides/domain/entities/ride_tracking_update.dart';
import 'package:dts_customer/features/rides/domain/usecases/cancel_ride_usecase.dart';
import 'package:dts_customer/features/rides/domain/usecases/get_ride_usecase.dart';
import 'package:dts_customer/features/rides/domain/usecases/watch_ride_usecase.dart';
import 'package:dts_customer/features/rides/presentation/screens/ride_tracking_screen.dart';
import 'package:dts_customer/features/rides/presentation/widgets/rides_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_providers.dart';
import 'rides_widget_helpers.dart';

class MockGetRideUseCase extends Mock implements GetRideUseCase {}

class MockWatchRideUseCase extends Mock implements WatchRideUseCase {}

class MockCancelRideUseCase extends Mock implements CancelRideUseCase {}

const _pickup = RideLocation(
  address: 'Calle 10 # 5-20',
  latitude: 4.7,
  longitude: -74.1,
);
const _dropoff = RideLocation(
  address: 'Carrera 7 # 45-10',
  latitude: 4.6,
  longitude: -74.2,
);
const _activeRide = Ride(
  id: 5,
  status: RideStatus.searchingDriver,
  pickup: _pickup,
  dropoff: _dropoff,
  total: 9000,
);

void main() {
  late MockGetRideUseCase getRide;
  late MockWatchRideUseCase watchRide;
  late MockCancelRideUseCase cancelRide;

  setUp(() {
    getRide = MockGetRideUseCase();
    watchRide = MockWatchRideUseCase();
    cancelRide = MockCancelRideUseCase();
  });

  testWidgets('ride_tracking_shows_status_and_cancels_test', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    when(() => getRide.call(5)).thenAnswer((_) async => _activeRide);
    when(() => watchRide.call(5))
        .thenAnswer((_) => const Stream<RideTrackingUpdate>.empty());
    when(() => cancelRide.call(5)).thenAnswer(
      (_) async => _activeRide.copyWith(status: RideStatus.cancelled),
    );

    final router = GoRouter(
      initialLocation: '/rides/5/tracking',
      routes: [
        GoRoute(
          path: '/rides/:rideId/tracking',
          builder: (_, state) => RideTrackingScreen(
            rideId: int.parse(state.pathParameters['rideId']!),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          getRideUseCaseProvider.overrideWithValue(getRide),
          watchRideUseCaseProvider.overrideWithValue(watchRide),
          cancelRideUseCaseProvider.overrideWithValue(cancelRide),
          ridesMapBuilderProvider.overrideWithValue(fakeRidesMapBuilder),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ride_tracking_screen')), findsOneWidget);
    expect(find.byKey(const Key('ride_status_label')), findsOneWidget);
    expect(find.text('Buscando conductor'), findsOneWidget);
    expect(find.byKey(const Key('cancel_ride_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('cancel_ride_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_cancel_ride')));
    await tester.pumpAndSettle();

    verify(() => cancelRide.call(5)).called(1);
    expect(find.text('Cancelado'), findsWidgets);
    expect(find.byKey(const Key('cancel_ride_button')), findsNothing);

    // Desmonta el widget para cancelar el timer de polling.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ride_tracking_hides_cancel_for_in_progress_ride_test',
      (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const inProgress = Ride(
      id: 6,
      status: RideStatus.rideInProgress,
      pickup: _pickup,
      dropoff: _dropoff,
      total: 9000,
    );
    when(() => getRide.call(6)).thenAnswer((_) async => inProgress);
    when(() => watchRide.call(6))
        .thenAnswer((_) => const Stream<RideTrackingUpdate>.empty());

    final router = GoRouter(
      initialLocation: '/rides/6/tracking',
      routes: [
        GoRoute(
          path: '/rides/:rideId/tracking',
          builder: (_, state) => RideTrackingScreen(
            rideId: int.parse(state.pathParameters['rideId']!),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          getRideUseCaseProvider.overrideWithValue(getRide),
          watchRideUseCaseProvider.overrideWithValue(watchRide),
          ridesMapBuilderProvider.overrideWithValue(fakeRidesMapBuilder),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('En viaje'), findsWidgets);
    expect(find.byKey(const Key('cancel_ride_button')), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
