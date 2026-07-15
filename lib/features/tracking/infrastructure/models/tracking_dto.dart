import '../../domain/entities/tracking_data.dart';

class TrackingDto {
  const TrackingDto({
    required this.orderId,
    required this.status,
    this.driverLatitude,
    this.driverLongitude,
    this.destinationLatitude,
    this.destinationLongitude,
    this.updatedAt,
    this.isLive = false,
  });

  final int orderId;
  final String status;
  final double? driverLatitude;
  final double? driverLongitude;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final DateTime? updatedAt;
  final bool isLive;

  factory TrackingDto.fromJson(Map<String, dynamic> json) {
    double? driverLat = _toDouble(json['driver_latitude'] ?? json['latitude']);
    double? driverLng = _toDouble(json['driver_longitude'] ?? json['longitude']);

    final points = json['points'];
    if ((driverLat == null || driverLng == null) && points is List && points.isNotEmpty) {
      final last = points.last;
      if (last is Map<String, dynamic>) {
        driverLat ??= _toDouble(last['latitude']);
        driverLng ??= _toDouble(last['longitude']);
      }
    }

    final status = (json['order_status'] ?? json['status'] ?? '') as String;

    return TrackingDto(
      orderId: json['order_id'] as int? ?? json['id'] as int? ?? 0,
      status: status,
      driverLatitude: driverLat,
      driverLongitude: driverLng,
      destinationLatitude: _toDouble(
        json['destination_latitude'] ?? json['service_latitude'],
      ),
      destinationLongitude: _toDouble(
        json['destination_longitude'] ?? json['service_longitude'],
      ),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      isLive: json['is_live'] as bool? ??
          const {'driver_assigned', 'picked_up', 'on_the_way'}.contains(status),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  TrackingData toEntity() => TrackingData(
        orderId: orderId,
        status: status,
        driverLatitude: driverLatitude,
        driverLongitude: driverLongitude,
        destinationLatitude: destinationLatitude,
        destinationLongitude: destinationLongitude,
        updatedAt: updatedAt,
        isLive: isLive,
      );
}
