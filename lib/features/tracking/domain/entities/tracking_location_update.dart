import 'package:equatable/equatable.dart';

/// Punto GPS en vivo recibido por WebSocket (broadcast del conductor).
class TrackingLocationUpdate extends Equatable {
  const TrackingLocationUpdate({
    required this.orderId,
    required this.latitude,
    required this.longitude,
    this.recordedAt,
    this.sequence,
    this.orderStatus,
    this.destinationLatitude,
    this.destinationLongitude,
  });

  final int orderId;
  final double latitude;
  final double longitude;
  final DateTime? recordedAt;
  final int? sequence;
  final String? orderStatus;
  final double? destinationLatitude;
  final double? destinationLongitude;

  factory TrackingLocationUpdate.fromJson(Map<String, dynamic> json) {
    return TrackingLocationUpdate(
      orderId: json['order_id'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
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
      ];
}
