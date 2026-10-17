import 'package:dts_customer/features/rides/domain/entities/ride.dart';
import 'package:dts_customer/features/rides/domain/entities/ride_location.dart';
import 'package:dts_customer/features/rides/domain/entities/ride_status.dart';
import 'package:dts_customer/features/rides/domain/entities/ride_tracking_update.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ride_status_from_api_and_helpers_test', () {
    expect(RideStatus.fromApi('searching_driver'), RideStatus.searchingDriver);
    expect(RideStatus.fromApi('DRIVER_ACCEPTED'), RideStatus.driverAccepted);
    expect(RideStatus.fromApi('ride_completed'), RideStatus.rideCompleted);
    expect(RideStatus.fromApi(null), RideStatus.unknown);
    expect(RideStatus.fromApi('wat'), RideStatus.unknown);

    expect(RideStatus.searchingDriver.isActive, isTrue);
    expect(RideStatus.rideInProgress.isActive, isTrue);
    expect(RideStatus.rideCompleted.isActive, isFalse);
    expect(RideStatus.cancelled.isTerminal, isTrue);

    expect(RideStatus.driverEnRouteToPickup.canCancel, isTrue);
    expect(RideStatus.rideInProgress.canCancel, isFalse);
    expect(RideStatus.searchingDriver.label, 'Buscando conductor');
  });

  test('ride_is_active_and_copy_with_status_test', () {
    const pickup = RideLocation(address: 'A', latitude: 1, longitude: 2);
    const dropoff = RideLocation(address: 'B', latitude: 3, longitude: 4);
    const ride = Ride(
      id: 9,
      status: RideStatus.searchingDriver,
      pickup: pickup,
      dropoff: dropoff,
      driverId: 3,
    );

    expect(ride.isActive, isTrue);
    expect(ride.hasDriver, isTrue);

    final updated = ride.copyWith(status: RideStatus.rideInProgress);
    expect(updated.status, RideStatus.rideInProgress);
    expect(updated.id, 9);
    expect(updated.driverId, 3);
    expect(updated.pickup, pickup);
  });

  test('ride_tracking_update_from_json_test', () {
    final Map<String, dynamic> locationJson = {
      'type': 'location',
      'order_id': 42,
      'latitude': 4.711,
      'longitude': '-74.0721',
      'eta_minutes': 8,
      'recorded_at': '2026-07-12T21:00:00Z',
    };
    final location = RideTrackingUpdate.fromJson(locationJson);

    expect(location.rideId, 42);
    expect(location.driverLatitude, 4.711);
    expect(location.driverLongitude, -74.0721);
    expect(location.etaMinutes, 8);
    expect(location.status, isNull);
    expect(location.recordedAt, DateTime.parse('2026-07-12T21:00:00Z'));

    final status = RideTrackingUpdate.fromJson(const {
      'type': 'order_status',
      'order_id': 42,
      'status': 'ride_in_progress',
    });
    expect(status.status, RideStatus.rideInProgress);
    expect(status.driverLatitude, isNull);
  });
}
