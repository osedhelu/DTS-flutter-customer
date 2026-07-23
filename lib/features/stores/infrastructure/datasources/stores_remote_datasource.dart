import 'package:dio/dio.dart';

import '../../../../core/utils/pagination.dart';
import '../models/store_dto.dart';

class StoresRemoteDataSource {
  const StoresRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<StoreDto>> fetchStores({
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    final query = <String, dynamic>{};
    if (latitude != null && longitude != null) {
      query['latitude'] = latitude;
      query['longitude'] = longitude;
      if (radiusKm != null) {
        query['radius_km'] = radiusKm;
      }
    }

    final response = await _dio.get<dynamic>(
      '/stores/',
      queryParameters: query.isEmpty ? null : query,
    );
    return parsePaginatedList(response.data, StoreDto.fromJson);
  }
}
