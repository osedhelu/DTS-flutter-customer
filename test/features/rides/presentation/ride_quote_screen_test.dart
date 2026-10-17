import 'package:dts_customer/core/di/providers.dart';
import 'package:dts_customer/features/rides/domain/entities/fare_quote.dart';
import 'package:dts_customer/features/rides/domain/entities/ride.dart';
import 'package:dts_customer/features/rides/domain/entities/ride_location.dart';
import 'package:dts_customer/features/rides/domain/entities/ride_request.dart';
import 'package:dts_customer/features/rides/domain/entities/ride_status.dart';
import 'package:dts_customer/features/rides/domain/usecases/create_ride_usecase.dart';
import 'package:dts_customer/features/rides/domain/usecases/quote_ride_usecase.dart';
import 'package:dts_customer/features/rides/presentation/models/ride_draft.dart';
import 'package:dts_customer/features/rides/presentation/screens/ride_quote_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_providers.dart';

class MockQuoteRideUseCase extends Mock implements QuoteRideUseCase {}

class MockCreateRideUseCase extends Mock implements CreateRideUseCase {}

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
const _breakdown = FareBreakdown(
  base: 2.5,
  distance: 1.5,
  time: 0.5,
  surge: 0,
  total: 4.5,
);

void main() {
  late MockQuoteRideUseCase quoteUseCase;
  late MockCreateRideUseCase createUseCase;

  setUp(() {
    quoteUseCase = MockQuoteRideUseCase();
    createUseCase = MockCreateRideUseCase();
  });

  testWidgets('ride_quote_shows_breakdown_and_requests_ride_test',
      (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const draft = RideDraft(pickup: _pickup, dropoff: _dropoff);
    final quote = FareQuote(
      quoteId: 'q-1',
      estimatedDistanceKm: 6.4,
      estimatedDurationMinutes: 18,
      fareBreakdown: _breakdown,
      expiresAt: DateTime(2030, 1, 1),
      zoneName: 'Centro',
    );
    const ride = Ride(
      id: 55,
      status: RideStatus.searchingDriver,
      pickup: _pickup,
      dropoff: _dropoff,
      total: 4.5,
    );

    when(() => quoteUseCase.call(
          const QuoteRideParams(pickup: _pickup, dropoff: _dropoff),
        )).thenAnswer((_) async => quote);
    when(() => createUseCase.call(
          const CreateRideParams(
            pickup: _pickup,
            dropoff: _dropoff,
            fareBreakdown: _breakdown,
            estimatedDurationMinutes: 18,
            estimatedDistanceKm: 6.4,
          ),
        )).thenAnswer((_) async => ride);

    final router = GoRouter(
      initialLocation: '/quote',
      initialExtra: draft,
      routes: [
        GoRoute(path: '/quote', builder: (_, __) => const RideQuoteScreen()),
        GoRoute(
          path: '/rides/:rideId/tracking',
          builder: (_, __) => const Text('tracking-screen'),
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          quoteRideUseCaseProvider.overrideWithValue(quoteUseCase),
          createRideUseCaseProvider.overrideWithValue(createUseCase),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ride_quote_screen')), findsOneWidget);
    expect(find.byKey(const Key('fare_breakdown_card')), findsOneWidget);
    expect(find.text('Origen'), findsOneWidget);
    expect(find.text('Destino'), findsOneWidget);
    expect(find.text('Calle 10 # 5-20'), findsOneWidget);
    expect(find.text('\$4.50'), findsWidgets);

    await tester.tap(find.byKey(const Key('ride_request_button')));
    await tester.pumpAndSettle();

    expect(find.text('tracking-screen'), findsOneWidget);
    verify(() => createUseCase.call(
          const CreateRideParams(
            pickup: _pickup,
            dropoff: _dropoff,
            fareBreakdown: _breakdown,
            estimatedDurationMinutes: 18,
            estimatedDistanceKm: 6.4,
          ),
        )).called(1);
  });

  testWidgets('ride_quote_shows_error_when_quote_fails_test', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    when(() => quoteUseCase.call(
          const QuoteRideParams(pickup: _pickup, dropoff: _dropoff),
        )).thenThrow(Exception('boom'));

    final router = GoRouter(
      initialLocation: '/quote',
      initialExtra: const RideDraft(pickup: _pickup, dropoff: _dropoff),
      routes: [
        GoRoute(path: '/quote', builder: (_, __) => const RideQuoteScreen()),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          quoteRideUseCaseProvider.overrideWithValue(quoteUseCase),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cotizar tu viaje.'), findsOneWidget);
  });
}
