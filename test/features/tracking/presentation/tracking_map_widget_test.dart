import 'package:dts_customer/core/di/providers.dart';
import 'package:dts_customer/core/di/repository_providers.dart';
import 'package:dts_customer/core/network/token_storage.dart';
import 'package:dts_customer/features/tracking/domain/entities/tracking_data.dart';
import 'package:dts_customer/features/tracking/domain/entities/tracking_location_update.dart';
import 'package:dts_customer/features/tracking/domain/usecases/get_tracking_usecase.dart';
import 'package:dts_customer/features/tracking/infrastructure/datasources/tracking_ws_datasource.dart';
import 'package:dts_customer/features/tracking/presentation/screens/tracking_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_providers.dart';

class MockGetTrackingUseCase extends Mock implements GetTrackingUseCase {}

class MockTrackingWsDataSource extends Mock implements TrackingWsDataSource {}

void main() {
  late MockGetTrackingUseCase getTrackingUseCase;
  late MockTrackingWsDataSource wsDataSource;
  late InMemoryTokenStorage tokenStorage;

  setUp(() {
    getTrackingUseCase = MockGetTrackingUseCase();
    wsDataSource = MockTrackingWsDataSource();
    tokenStorage = InMemoryTokenStorage();
    when(
      () => wsDataSource.watchLocations(
        orderId: any(named: 'orderId'),
        accessToken: any(named: 'accessToken'),
      ),
    ).thenAnswer((_) => const Stream<TrackingLocationUpdate>.empty());
    when(() => wsDataSource.disconnect()).thenAnswer((_) async {});
  });

  testWidgets('tracking_map_widget_test', (tester) async {
    when(() => getTrackingUseCase(10)).thenAnswer(
      (_) async => const TrackingData(
        orderId: 10,
        status: 'ON_THE_WAY',
        driverLatitude: 4.71,
        driverLongitude: -74.07,
        destinationLatitude: 4.72,
        destinationLongitude: -74.08,
      ),
    );

    await tester.pumpWidget(
      buildTestApp(
        overrides: [
          getTrackingUseCaseProvider.overrideWithValue(getTrackingUseCase),
          trackingWsDataSourceProvider.overrideWithValue(wsDataSource),
          tokenStorageProvider.overrideWithValue(tokenStorage),
          mapWidgetBuilderProvider.overrideWithValue(
            ({
              required LatLng? driverPosition,
              required LatLng? destinationPosition,
              required String status,
            }) {
              return ColoredBox(
                key: const Key('tracking_map_placeholder'),
                color: Colors.blue,
                child: Text(status),
              );
            },
          ),
        ],
        child: const MaterialApp(
          home: TrackingMapScreen(orderId: 10),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('tracking_status')), findsOneWidget);
    expect(find.byKey(const Key('tracking_map_placeholder')), findsOneWidget);
  });
}
