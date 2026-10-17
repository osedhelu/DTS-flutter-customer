import '../../domain/entities/ride.dart';
import '../../domain/entities/ride_location.dart';
import '../../domain/entities/ride_status.dart';

/// DTO de serialización de un viaje (`/api/v1/rides/`).
class RideDto {
  const RideDto({
    required this.id,
    required this.status,
    required this.pickup,
    required this.dropoff,
    this.total = 0,
    this.estimatedDurationMinutes,
    this.estimatedDistanceKm,
    this.fareBreakdown = const {},
    this.driverId,
    this.paymentStatus = 'pending',
    this.createdAt,
  });

  final int id;
  final RideStatus status;
  final RideLocation pickup;
  final RideLocation dropoff;
  final double total;
  final int? estimatedDurationMinutes;
  final double? estimatedDistanceKm;
  final Map<String, dynamic> fareBreakdown;
  final int? driverId;
  final String paymentStatus;
  final DateTime? createdAt;

  factory RideDto.fromJson(Map<String, dynamic> json) {
    return RideDto(
      id: (json['id'] as num).toInt(),
      status: RideStatus.fromApi(json['status']?.toString()),
      pickup: RideLocation(
        address: json['pickup_address'] as String? ?? '',
        latitude: _toDouble(json['pickup_latitude']) ?? 0,
        longitude: _toDouble(json['pickup_longitude']) ?? 0,
      ),
      dropoff: RideLocation(
        address: json['dropoff_address'] as String? ?? '',
        latitude: _toDouble(json['dropoff_latitude']) ?? 0,
        longitude: _toDouble(json['dropoff_longitude']) ?? 0,
      ),
      total: _toDouble(json['total']) ?? 0,
      estimatedDurationMinutes:
          (json['estimated_duration_minutes'] as num?)?.toInt(),
      estimatedDistanceKm: _toDouble(json['estimated_distance_km']),
      fareBreakdown: json['fare_breakdown'] is Map
          ? Map<String, dynamic>.from(json['fare_breakdown'] as Map)
          : const {},
      driverId: (json['driver_id'] as num?)?.toInt(),
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    return value is num ? value.toDouble() : double.tryParse(value.toString());
  }

  Ride toEntity() => Ride(
        id: id,
        status: status,
        pickup: pickup,
        dropoff: dropoff,
        total: total,
        estimatedDurationMinutes: estimatedDurationMinutes,
        estimatedDistanceKm: estimatedDistanceKm,
        fareBreakdown: fareBreakdown,
        driverId: driverId,
        paymentStatus: paymentStatus,
        createdAt: createdAt,
      );
}
