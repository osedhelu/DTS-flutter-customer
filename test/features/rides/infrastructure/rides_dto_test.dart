import 'package:dts_customer/features/rides/domain/entities/ride_status.dart';
import 'package:dts_customer/features/rides/infrastructure/models/fare_quote_dto.dart';
import 'package:dts_customer/features/rides/infrastructure/models/ride_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ride_dto_maps_json_to_entity_test', () {
    final dto = RideDto.fromJson({
      'id': 7,
      'status': 'driver_en_route_to_pickup',
      'pickup_address': 'Calle 1',
      'pickup_latitude': '4.711',
      'pickup_longitude': -74.0721,
      'dropoff_address': 'Calle 2',
      'dropoff_latitude': 4.65,
      'dropoff_longitude': -74.08,
      'total': '12500.00',
      'estimated_duration_minutes': 18,
      'estimated_distance_km': '6.4',
      'fare_breakdown': {'base': '2.5', 'total': 12.5},
      'driver_id': 3,
      'payment_status': 'paid',
      'created_at': '2026-07-12T21:00:00Z',
      'encoded_polyline': 'wbw[rebcMfrJnrM',
    });

    final ride = dto.toEntity();

    expect(ride.id, 7);
    expect(ride.status, RideStatus.driverEnRouteToPickup);
    expect(ride.pickup.address, 'Calle 1');
    expect(ride.pickup.latitude, 4.711);
    expect(ride.pickup.longitude, -74.0721);
    expect(ride.dropoff.address, 'Calle 2');
    expect(ride.total, 12500.0);
    expect(ride.estimatedDurationMinutes, 18);
    expect(ride.estimatedDistanceKm, 6.4);
    expect(ride.fareBreakdown['base'], '2.5');
    expect(ride.driverId, 3);
    expect(ride.paymentStatus, 'paid');
    expect(ride.createdAt, DateTime.parse('2026-07-12T21:00:00Z'));
    expect(ride.isActive, isTrue);
    // Ruta real sobre calles: decodifica la polyline a 2 puntos.
    expect(ride.encodedPolyline, 'wbw[rebcMfrJnrM');
    expect(ride.routePoints, hasLength(2));
    expect(ride.routePoints.first.latitude, closeTo(4.711, 1e-5));
  });

  test('ride_dto_tolerates_missing_optional_fields_test', () {
    final ride =
        RideDto.fromJson({'id': 1, 'status': 'ride_completed'}).toEntity();

    expect(ride.id, 1);
    expect(ride.status, RideStatus.rideCompleted);
    expect(ride.pickup.address, '');
    expect(ride.total, 0);
    expect(ride.fareBreakdown, isEmpty);
    expect(ride.isActive, isFalse);
  });

  test('fare_quote_dto_maps_breakdown_including_surge_test', () {
    final dto = FareQuoteDto.fromJson({
      'quote_id': 'abc',
      'estimated_distance_km': '6.4',
      'estimated_duration_minutes': 18,
      'fare_breakdown': {
        'base': 2.5,
        'distance': '1.5',
        'time': 0.5,
        'surge': '1.2',
        'total': 5.7,
        'surge_multiplier': '1.2',
      },
      'expires_at': '2026-07-12T21:05:00Z',
      'zone_name': 'Centro',
      'encoded_polyline': 'wbw[rebcMfrJnrM',
    });

    final quote = dto.toEntity();

    expect(quote.quoteId, 'abc');
    expect(quote.estimatedDistanceKm, 6.4);
    expect(quote.estimatedDurationMinutes, 18);
    expect(quote.fareBreakdown.base, 2.5);
    expect(quote.fareBreakdown.distance, 1.5);
    expect(quote.fareBreakdown.surge, 1.2);
    expect(quote.fareBreakdown.surgeMultiplier, 1.2);
    expect(quote.fareBreakdown.hasSurge, isTrue);
    expect(quote.fareBreakdown.total, 5.7);
    expect(quote.zoneName, 'Centro');
    expect(quote.expiresAt, DateTime.parse('2026-07-12T21:05:00Z'));
    expect(quote.encodedPolyline, 'wbw[rebcMfrJnrM');
    expect(quote.routePoints, hasLength(2));
  });
}
