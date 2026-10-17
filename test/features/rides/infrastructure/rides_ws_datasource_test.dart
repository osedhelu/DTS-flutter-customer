import 'dart:async';
import 'dart:convert';

import 'package:dts_customer/core/config/env.dart';
import 'package:dts_customer/features/rides/domain/entities/ride_status.dart';
import 'package:dts_customer/features/rides/domain/entities/ride_tracking_update.dart';
import 'package:dts_customer/features/rides/infrastructure/datasources/rides_ws_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWsConnection implements RidesWsConnection {
  _FakeWsConnection(this._controller);

  final StreamController<dynamic> _controller;

  @override
  Stream<dynamic> get messages => _controller.stream;

  @override
  Future<void> close() async {
    await _controller.close();
  }
}

void main() {
  test('rides_ws_datasource_streams_locations_and_status_test', () async {
    final controller = StreamController<dynamic>.broadcast();
    Uri? connectedUri;

    final datasource = RidesWsDataSource(
      wsBaseUrl: 'wss://example.test',
      connectionFactory: (uri) {
        connectedUri = uri;
        return _FakeWsConnection(controller);
      },
    );

    final updates = <RideTrackingUpdate>[];
    final sub = datasource
        .watchRide(rideId: 42, accessToken: 'jwt-token')
        .listen(updates.add);

    expect(
      connectedUri.toString(),
      'wss://example.test:443/ws/orders/42/tracking/?token=jwt-token',
    );

    controller.add(
      jsonEncode({
        'type': 'location',
        'order_id': 42,
        'latitude': 4.711,
        'longitude': -74.0721,
        'recorded_at': '2026-07-12T21:00:00Z',
      }),
    );
    controller.add(jsonEncode({'type': 'error', 'detail': 'ignored'}));
    controller.add(
      jsonEncode({
        'type': 'order_status',
        'order_id': 42,
        'status': 'driver_accepted',
      }),
    );

    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(updates, hasLength(2));
    expect(updates.first.rideId, 42);
    expect(updates.first.driverLatitude, 4.711);
    expect(updates.first.driverLongitude, -74.0721);
    expect(updates.last.status, RideStatus.driverAccepted);
    // El cambio de estado conserva la última posición conocida del conductor.
    expect(updates.last.driverLatitude, 4.711);
    expect(updates.last.driverLongitude, -74.0721);

    await datasource.disconnect();
    await sub.cancel();
  });

  test('rides_ws_builds_tracking_uri_test', () {
    final datasource = RidesWsDataSource(
      wsBaseUrl: 'wss://api.test',
      connectionFactory: (uri) => _FakeWsConnection(StreamController()),
    );

    expect(
      datasource.buildUri(rideId: 5, accessToken: 'a b').toString(),
      'wss://api.test:443/ws/orders/5/tracking/?token=a+b',
    );
    expect(EnvConfig.wsBaseUrl, 'wss://api.dtsdrop.com');
  });
}
