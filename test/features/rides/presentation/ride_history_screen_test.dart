import 'package:dts_customer/core/di/providers.dart';
import 'package:dts_customer/features/rides/domain/entities/ride.dart';
import 'package:dts_customer/features/rides/domain/entities/ride_location.dart';
import 'package:dts_customer/features/rides/domain/entities/ride_status.dart';
import 'package:dts_customer/features/rides/domain/usecases/list_rides_usecase.dart';
import 'package:dts_customer/features/rides/presentation/screens/ride_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_providers.dart';

class MockListRidesUseCase extends Mock implements ListRidesUseCase {}

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

void main() {
  late MockListRidesUseCase listRides;

  setUp(() {
    listRides = MockListRidesUseCase();
  });

  testWidgets('ride_history_lists_rides_test', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    when(() => listRides.call()).thenAnswer(
      (_) async => [
        Ride(
          id: 1,
          status: RideStatus.rideCompleted,
          pickup: _pickup,
          dropoff: _dropoff,
          total: 12000,
          createdAt: DateTime(2026, 7, 12, 21),
        ),
        const Ride(
          id: 2,
          status: RideStatus.searchingDriver,
          pickup: _pickup,
          dropoff: _dropoff,
          total: 9000,
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        overrides: [listRidesUseCaseProvider.overrideWithValue(listRides)],
        child: const MaterialApp(home: RideHistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ride_history_item_1')), findsOneWidget);
    expect(find.byKey(const Key('ride_history_item_2')), findsOneWidget);
    expect(find.text('Viaje #1'), findsOneWidget);
    expect(find.text('\$12000.00'), findsOneWidget);
    expect(find.text('Viaje completado'), findsOneWidget);
    verify(() => listRides.call()).called(1);
  });

  testWidgets('ride_history_shows_empty_state_test', (tester) async {
    when(() => listRides.call()).thenAnswer((_) async => []);

    await tester.pumpWidget(
      buildTestApp(
        overrides: [listRidesUseCaseProvider.overrideWithValue(listRides)],
        child: const MaterialApp(home: RideHistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sin viajes todavía'), findsOneWidget);
  });
}
