import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Punto GPS en vivo recibido por WebSocket (broadcast del conductor) o
/// actualización de estado (`order_status`).
class TrackingLocationUpdate extends Equatable {
  const TrackingLocationUpdate({
    required this.orderId,
    this.latitude,
    this.longitude,
    this.recordedAt,
    this.sequence,
    this.orderStatus,
    this.destinationLatitude,
    this.destinationLongitude,
    this.etaMinutes,
    this.polylinePoints,
  });

  final int orderId;

  /// Nulo cuando el mensaje es solo de cambio de estado (`order_status`).
  final double? latitude;
  final double? longitude;
  final DateTime? recordedAt;
  final int? sequence;
  final String? orderStatus;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final int? etaMinutes;

  /// Ruta real del conductor hacia su destino actual (OpenRouteService).
  final List<LatLng>? polylinePoints;

  factory TrackingLocationUpdate.fromJson(Map<String, dynamic> json) {
    final rawPolyline = json['polyline'];
    final polylinePoints = <LatLng>[];
    if (rawPolyline is List) {
      for (final point in rawPolyline) {
        if (point is Map<String, dynamic>) {
          final lat = point['latitude'];
          final lng = point['longitude'];
          if (lat is num && lng is num) {
            polylinePoints.add(LatLng(lat.toDouble(), lng.toDouble()));
          }
        }
      }
    }

    return TrackingLocationUpdate(
      orderId: json['order_id'] as int,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      recordedAt: json['recorded_at'] != null
          ? DateTime.tryParse(json['recorded_at'] as String)
          : null,
      sequence: json['sequence'] as int?,
      orderStatus: json['order_status'] as String? ?? json['status'] as String?,
      destinationLatitude: json['destination_latitude'] != null
          ? (json['destination_latitude'] as num).toDouble()
          : null,
      destinationLongitude: json['destination_longitude'] != null
          ? (json['destination_longitude'] as num).toDouble()
          : null,
      etaMinutes: json['eta_minutes'] != null
          ? (json['eta_minutes'] as num).toInt()
          : null,
      polylinePoints: polylinePoints.isEmpty ? null : polylinePoints,
    );
  }

  @override
  List<Object?> get props => [
        orderId,
        latitude,
        longitude,
        recordedAt,
        sequence,
        orderStatus,
        destinationLatitude,
        destinationLongitude,
        etaMinutes,
        polylinePoints,
      ];
}
