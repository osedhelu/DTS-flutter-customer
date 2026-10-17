import 'package:equatable/equatable.dart';

import 'ride_status.dart';

/// Actualización en vivo del viaje recibida por WebSocket (broadcast del
/// conductor) o por cambio de estado (`order_status`).
class RideTrackingUpdate extends Equatable {
  const RideTrackingUpdate({
    required this.rideId,
    this.status,
    this.driverLatitude,
    this.driverLongitude,
    this.destinationLatitude,
    this.destinationLongitude,
    this.etaMinutes,
    this.recordedAt,
  });

  final int rideId;
  final RideStatus? status;

  /// Nulo cuando el mensaje es solo de cambio de estado (`order_status`).
  final double? driverLatitude;
  final double? driverLongitude;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final int? etaMinutes;
  final DateTime? recordedAt;

  factory RideTrackingUpdate.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] ?? json['order_status'];
    return RideTrackingUpdate(
      rideId: (json['order_id'] as num?)?.toInt() ?? 0,
      status:
          rawStatus == null ? null : RideStatus.fromApi(rawStatus.toString()),
      driverLatitude: _toDouble(json['latitude']),
      driverLongitude: _toDouble(json['longitude']),
      destinationLatitude: _toDouble(json['destination_latitude']),
      destinationLongitude: _toDouble(json['destination_longitude']),
      etaMinutes: json['eta_minutes'] != null
          ? (json['eta_minutes'] as num).toInt()
          : null,
      recordedAt: json['recorded_at'] != null
          ? DateTime.tryParse(json['recorded_at'] as String)
          : null,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    return value is num ? value.toDouble() : double.tryParse(value.toString());
  }

  @override
  List<Object?> get props => [
        rideId,
        status,
        driverLatitude,
        driverLongitude,
        destinationLatitude,
        destinationLongitude,
        etaMinutes,
        recordedAt,
      ];
}
