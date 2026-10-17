import '../../domain/entities/fare_quote.dart';

/// DTO de serialización de una cotización (`/api/v1/rides/quote/`).
class FareQuoteDto {
  const FareQuoteDto({
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
  final String? encodedPolyline;

  factory FareQuoteDto.fromJson(Map<String, dynamic> json) {
    return FareQuoteDto(
      quoteId: json['quote_id']?.toString() ?? '',
      estimatedDistanceKm: _toDouble(json['estimated_distance_km']) ?? 0,
      estimatedDurationMinutes:
          (json['estimated_duration_minutes'] as num?)?.toInt() ?? 0,
      fareBreakdown: _breakdownFromJson(json['fare_breakdown']),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      zoneName: json['zone_name'] as String?,
      encodedPolyline: json['encoded_polyline'] as String?,
    );
  }

  static FareBreakdown _breakdownFromJson(dynamic value) {
    if (value is! Map) {
      return const FareBreakdown(
        base: 0,
        distance: 0,
        time: 0,
        surge: 0,
        total: 0,
      );
    }
    final map = Map<String, dynamic>.from(value);
    return FareBreakdown(
      base: _toDouble(map['base']) ?? 0,
      distance: _toDouble(map['distance']) ?? 0,
      time: _toDouble(map['time']) ?? 0,
      surge: _toDouble(map['surge']) ?? 0,
      total: _toDouble(map['total']) ?? 0,
      surgeMultiplier: _toDouble(map['surge_multiplier']) ?? 1,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    return value is num ? value.toDouble() : double.tryParse(value.toString());
  }

  FareQuote toEntity() => FareQuote(
        quoteId: quoteId,
        estimatedDistanceKm: estimatedDistanceKm,
        estimatedDurationMinutes: estimatedDurationMinutes,
        fareBreakdown: fareBreakdown,
        expiresAt: expiresAt,
        zoneName: zoneName,
        encodedPolyline: encodedPolyline,
      );
}
