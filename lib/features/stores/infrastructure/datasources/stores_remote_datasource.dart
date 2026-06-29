import 'package:dio/dio.dart';

import '../../../../core/utils/pagination.dart';
import '../models/store_dto.dart';

class StoresRemoteDataSource {
  const StoresRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<StoreDto>> fetchStores() async {
    final response = await _dio.get<dynamic>('/stores/');
    return parsePaginatedList(response.data, StoreDto.fromJson);
  }
}
