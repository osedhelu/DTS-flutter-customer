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
    this.isLive = true,
  });

  final int orderId;
  final String status;
  final double? driverLatitude;
  final double? driverLongitude;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final DateTime? updatedAt;
  final bool isLive;

  static const _liveStatuses = {
    'driver_assigned',
    'picked_up',
    'on_the_way',
    'DRIVER_ASSIGNED',
    'PICKED_UP',
    'ON_THE_WAY',
  };

  bool get shouldShowDriverLive =>
      isLive || _liveStatuses.contains(status);

  @override
  List<Object?> get props => [
        orderId,
        status,
        driverLatitude,
        driverLongitude,
        destinationLatitude,
        destinationLongitude,
        updatedAt,
        isLive,
      ];
}
