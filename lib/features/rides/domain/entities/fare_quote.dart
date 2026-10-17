import 'package:equatable/equatable.dart';

/// Desglose de tarifa de un viaje (espejo del backend `FareBreakdown`).
class FareBreakdown extends Equatable {
  const FareBreakdown({
    required this.base,
    required this.distance,
    required this.time,
    required this.surge,
    required this.total,
    this.surgeMultiplier = 1,
  });

  final double base;
  final double distance;
  final double time;
  final double surge;
  final double total;
  final double surgeMultiplier;

  bool get hasSurge => surge > 0;

  @override
  List<Object?> get props =>
      [base, distance, time, surge, total, surgeMultiplier];
}

/// Cotización de un viaje antes de solicitarlo.
class FareQuote extends Equatable {
  const FareQuote({
    required this.quoteId,
    required this.estimatedDistanceKm,
    required this.estimatedDurationMinutes,
    required this.fareBreakdown,
    required this.expiresAt,
    this.zoneName,
  });

  final String quoteId;
  final double estimatedDistanceKm;
  final int estimatedDurationMinutes;
  final FareBreakdown fareBreakdown;
  final DateTime expiresAt;
  final String? zoneName;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [
        quoteId,
        estimatedDistanceKm,
        estimatedDurationMinutes,
        fareBreakdown,
        expiresAt,
        zoneName,
      ];
}
