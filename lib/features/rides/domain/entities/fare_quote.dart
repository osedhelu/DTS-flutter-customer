import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/utils/polyline_decoder.dart';

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
    this.encodedPolyline,
  });

  final String quoteId;
  final double estimatedDistanceKm;
  final int estimatedDurationMinutes;
  final FareBreakdown fareBreakdown;
  final DateTime expiresAt;
  final String? zoneName;

  /// Geometría comprimida (polilínea de Google) de la ruta real Pickup →
  /// Dropoff sobre calles, calculada por el backend. `null` si no hay
  /// proveedor de rutas configurado.
  final String? encodedPolyline;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Puntos decodificados de la ruta real sobre calles (vacío si no hay).
  List<LatLng> get routePoints {
    final encoded = encodedPolyline;
    if (encoded == null || encoded.isEmpty) return const [];
    return decodePolyline(encoded);
  }

  @override
  List<Object?> get props => [
        quoteId,
        estimatedDistanceKm,
        estimatedDurationMinutes,
        fareBreakdown,
        expiresAt,
        zoneName,
        encodedPolyline,
      ];
}
