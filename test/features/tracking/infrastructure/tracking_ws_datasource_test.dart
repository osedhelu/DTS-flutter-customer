import 'dart:async';
import 'dart:convert';

import 'package:dts_customer/core/config/env.dart';
import 'package:dts_customer/features/tracking/domain/entities/tracking_location_update.dart';
import 'package:dts_customer/features/tracking/infrastructure/datasources/tracking_ws_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWsConnection implements TrackingWsConnection {
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
  test('tracking_ws_datasource_test', () async {
    final controller = StreamController<dynamic>.broadcast();
    Uri? connectedUri;

    final datasource = TrackingWsDataSource(
      wsBaseUrl: 'wss://example.test',
      connectionFactory: (uri) {
        connectedUri = uri;
        return _FakeWsConnection(controller);
      },
    );

    final updates = <TrackingLocationUpdate>[];
    final sub = datasource
        .watchLocations(orderId: 42, accessToken: 'jwt-token')
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
        'recorded_at': '2026-07-12T21:00:00+00:00',
        'sequence': 3,
      }),
    );
    controller.add(jsonEncode({'type': 'error', 'detail': 'ignored'}));
    controller.add(
      {
        'type': 'location',
        'order_id': 42,
        'latitude': 4.712,
        'longitude': -74.073,
        'sequence': 4,
      },
    );

    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(updates, hasLength(2));
    expect(updates.first.orderId, 42);
    expect(updates.first.latitude, 4.711);
    expect(updates.first.longitude, -74.0721);
    expect(updates.first.sequence, 3);
    expect(updates.last.latitude, 4.712);

    await datasource.disconnect();
    await sub.cancel();
  });

  test('tracking_ws_parse_polyline_and_order_status', () async {
    final controller = StreamController<dynamic>.broadcast();

    final datasource = TrackingWsDataSource(
      wsBaseUrl: 'wss://example.test',
      connectionFactory: (uri) => _FakeWsConnection(controller),
    );

    final updates = <TrackingLocationUpdate>[];
    final sub = datasource
        .watchLocations(orderId: 55, accessToken: 'jwt')
        .listen(updates.add);

    controller.add(
      jsonEncode({
        'type': 'location',
        'order_id': 55,
        'latitude': 4.711,
        'longitude': -74.0721,
        'order_status': 'on_the_way',
        'eta_minutes': 10,
        'polyline': [
          {'latitude': 4.711, 'longitude': -74.0721},
          {'latitude': 4.70, 'longitude': -74.07},
          {'latitude': 4.65, 'longitude': -74.08},
        ],
      }),
    );
    controller.add(
      jsonEncode({
        'type': 'order_status',
        'order_id': 55,
        'status': 'delivered',
      }),
    );

    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(updates, hasLength(2));
    expect(updates.first.polylinePoints, hasLength(3));
    expect(updates.first.etaMinutes, 10);
    expect(updates.first.orderStatus, 'on_the_way');
    expect(updates.last.orderStatus, 'delivered');
    // order_status conserva las últimas coordenadas conocidas.
    expect(updates.last.latitude, 4.711);
    expect(updates.last.longitude, -74.0721);

    await datasource.disconnect();
    await sub.cancel();
  });

  test('env_ws_base_url_from_api', () {
    expect(
      EnvConfig.wsBaseUrl,
      'wss://api.dtsdrop.com',
    );
  });
}
