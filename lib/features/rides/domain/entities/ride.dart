import 'package:equatable/equatable.dart';

import 'ride_location.dart';
import 'ride_status.dart';

/// Viaje de pasajeros solicitado por el cliente.
class Ride extends Equatable {
  const Ride({
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

  bool get isActive => status.isActive;

  bool get hasDriver => driverId != null;

  Ride copyWith({
    RideStatus? status,
    int? driverId,
    Map<String, dynamic>? fareBreakdown,
  }) {
    return Ride(
      id: id,
      status: status ?? this.status,
      pickup: pickup,
      dropoff: dropoff,
      total: total,
      estimatedDurationMinutes: estimatedDurationMinutes,
      estimatedDistanceKm: estimatedDistanceKm,
      fareBreakdown: fareBreakdown ?? this.fareBreakdown,
      driverId: driverId ?? this.driverId,
      paymentStatus: paymentStatus,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        status,
        pickup,
        dropoff,
        total,
        estimatedDurationMinutes,
        estimatedDistanceKm,
        driverId,
        paymentStatus,
        createdAt,
      ];
}
