import 'package:dio/dio.dart';

import '../models/tracking_dto.dart';

class TrackingRemoteDataSource {
  const TrackingRemoteDataSource(this._dio);

  final Dio _dio;

  Future<TrackingDto> fetchTracking(int orderId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/orders/$orderId/tracking/',
    );
    return TrackingDto.fromJson(response.data!);
  }
}
