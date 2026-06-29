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
  });

  final int orderId;
  final String status;
  final double? driverLatitude;
  final double? driverLongitude;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final DateTime? updatedAt;

  factory TrackingDto.fromJson(Map<String, dynamic> json) {
    return TrackingDto(
      orderId: json['order_id'] as int? ?? json['id'] as int,
      status: json['status'] as String,
      driverLatitude: _toDouble(json['driver_latitude'] ?? json['latitude']),
      driverLongitude: _toDouble(json['driver_longitude'] ?? json['longitude']),
      destinationLatitude: _toDouble(
        json['destination_latitude'] ?? json['service_latitude'],
      ),
      destinationLongitude: _toDouble(
        json['destination_longitude'] ?? json['service_longitude'],
      ),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    return double.parse(value.toString());
  }

  TrackingData toEntity() => TrackingData(
        orderId: orderId,
        status: status,
        driverLatitude: driverLatitude,
        driverLongitude: driverLongitude,
        destinationLatitude: destinationLatitude,
        destinationLongitude: destinationLongitude,
        updatedAt: updatedAt,
      );
}
