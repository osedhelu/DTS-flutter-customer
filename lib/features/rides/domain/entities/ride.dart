import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/utils/polyline_decoder.dart';
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
    this.encodedPolyline,
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

  /// Geometría comprimida (polilínea de Google) de la ruta real Pickup →
  /// Dropoff sobre calles. `null` si el backend no pudo calcularla.
  final String? encodedPolyline;

  bool get isActive => status.isActive;

  bool get hasDriver => driverId != null;

  /// Puntos decodificados de la ruta real sobre calles (vacío si no hay).
  List<LatLng> get routePoints {
    final encoded = encodedPolyline;
    if (encoded == null || encoded.isEmpty) return const [];
    return decodePolyline(encoded);
  }

  Ride copyWith({
    RideStatus? status,
    int? driverId,
    Map<String, dynamic>? fareBreakdown,
    String? encodedPolyline,
    bool clearEncodedPolyline = false,
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
      encodedPolyline:
          clearEncodedPolyline ? null : encodedPolyline ?? this.encodedPolyline,
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
        encodedPolyline,
      ];
}
