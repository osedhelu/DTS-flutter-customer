import 'package:equatable/equatable.dart';

/// Punto GPS en vivo recibido por WebSocket (broadcast del conductor).
class TrackingLocationUpdate extends Equatable {
  const TrackingLocationUpdate({
    required this.orderId,
    required this.latitude,
    required this.longitude,
    this.recordedAt,
    this.sequence,
  });

  final int orderId;
  final double latitude;
  final double longitude;
  final DateTime? recordedAt;
  final int? sequence;

  factory TrackingLocationUpdate.fromJson(Map<String, dynamic> json) {
    return TrackingLocationUpdate(
      orderId: json['order_id'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      recordedAt: json['recorded_at'] != null
          ? DateTime.tryParse(json['recorded_at'] as String)
          : null,
      sequence: json['sequence'] as int?,
    );
  }

  @override
  List<Object?> get props =>
      [orderId, latitude, longitude, recordedAt, sequence];
}
