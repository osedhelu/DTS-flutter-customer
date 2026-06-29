import 'package:dio/dio.dart';

class DeviceTokenRemoteDataSource {
  const DeviceTokenRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> registerToken({
    required String token,
    required String platform,
  }) async {
    await _dio.post<void>(
      '/accounts/device-token/',
      data: {'token': token, 'platform': platform},
    );
  }
}
