import 'package:equatable/equatable.dart';

import 'fare_quote.dart';
import 'ride_location.dart';

/// Parámetros para cotizar un viaje.
class QuoteRideParams extends Equatable {
  const QuoteRideParams({
    required this.pickup,
    required this.dropoff,
    this.zoneName,
  });

  final RideLocation pickup;
  final RideLocation dropoff;
  final String? zoneName;

  @override
  List<Object?> get props => [pickup, dropoff, zoneName];
}

/// Parámetros para solicitar un viaje.
class CreateRideParams extends Equatable {
  const CreateRideParams({
    required this.pickup,
    required this.dropoff,
    this.fareBreakdown,
    this.estimatedDurationMinutes,
    this.estimatedDistanceKm,
  });

  final RideLocation pickup;
  final RideLocation dropoff;
  final FareBreakdown? fareBreakdown;
  final int? estimatedDurationMinutes;
  final double? estimatedDistanceKm;

  @override
  List<Object?> get props => [
        pickup,
        dropoff,
        fareBreakdown,
        estimatedDurationMinutes,
        estimatedDistanceKm,
      ];
}
