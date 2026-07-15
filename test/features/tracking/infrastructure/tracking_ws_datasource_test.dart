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
      'wss://example.test/ws/orders/42/tracking/?token=jwt-token',
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

  test('env_ws_base_url_from_api', () {
    expect(
      EnvConfig.wsBaseUrl,
      'wss://dts-backend-production-c84e.up.railway.app',
    );
  });
}
