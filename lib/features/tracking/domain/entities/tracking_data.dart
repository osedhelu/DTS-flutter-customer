import 'package:equatable/equatable.dart';

class TrackingData extends Equatable {
  const TrackingData({
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

  @override
  List<Object?> get props => [
        orderId,
        status,
        driverLatitude,
        driverLongitude,
        destinationLatitude,
        destinationLongitude,
        updatedAt,
      ];
}
