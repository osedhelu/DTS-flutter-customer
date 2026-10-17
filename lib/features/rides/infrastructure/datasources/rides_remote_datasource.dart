import 'package:dio/dio.dart';

import '../../../../core/utils/pagination.dart';
import '../../domain/entities/ride_request.dart';
import '../models/fare_quote_dto.dart';
import '../models/ride_dto.dart';

/// API REST del motor de rideshare (`/api/v1/rides/`).
class RidesRemoteDataSource {
  const RidesRemoteDataSource(this._dio);

  final Dio _dio;

  Future<FareQuoteDto> quoteRide(QuoteRideParams params) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/rides/quote/',
      data: {
        'pickup_latitude': params.pickup.latitude,
        'pickup_longitude': params.pickup.longitude,
        'dropoff_latitude': params.dropoff.latitude,
        'dropoff_longitude': params.dropoff.longitude,
        if ((params.zoneName ?? '').isNotEmpty) 'zone_name': params.zoneName,
      },
    );
    return FareQuoteDto.fromJson(response.data!);
  }

  Future<RideDto> createRide(CreateRideParams params) async {
    final breakdown = params.fareBreakdown;
    final response = await _dio.post<Map<String, dynamic>>(
      '/rides/',
      data: {
        'pickup_address': params.pickup.address,
        'pickup_latitude': params.pickup.latitude,
        'pickup_longitude': params.pickup.longitude,
        'dropoff_address': params.dropoff.address,
        'dropoff_latitude': params.dropoff.latitude,
        'dropoff_longitude': params.dropoff.longitude,
        if (params.estimatedDurationMinutes != null)
          'estimated_duration_minutes': params.estimatedDurationMinutes,
        if (params.estimatedDistanceKm != null)
          'estimated_distance_km': params.estimatedDistanceKm,
        if (breakdown != null)
          'fare_breakdown': {
            'base': breakdown.base,
            'distance': breakdown.distance,
            'time': breakdown.time,
            'surge': breakdown.surge,
            'total': breakdown.total,
            'surge_multiplier': breakdown.surgeMultiplier,
          },
      },
    );
    return RideDto.fromJson(response.data!);
  }

  Future<List<RideDto>> listRides() async {
    final response = await _dio.get<dynamic>('/rides/');
    return parsePaginatedList(response.data, RideDto.fromJson);
  }

  Future<RideDto> fetchRide(int rideId) async {
    final response = await _dio.get<Map<String, dynamic>>('/rides/$rideId/');
    return RideDto.fromJson(response.data!);
  }

  Future<RideDto> cancelRide(int rideId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/rides/$rideId/cancel/',
    );
    return RideDto.fromJson(response.data!);
  }
}
