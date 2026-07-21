import 'package:dio/dio.dart';

import '../models/auth_tokens_dto.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthTokensDto> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/accounts/login/',
      data: {'username': username, 'password': password},
    );

    return AuthTokensDto.fromJson(response.data!);
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String phone,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/accounts/register/',
      data: {
        'username': username,
        'email': email,
        'password': password,
        'role': 'customer',
        'phone': phone,
      },
    );
  }

  Future<AuthTokensDto> signInWithGoogle({required String idToken}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/accounts/auth/google/',
      data: {'id_token': idToken},
    );

    return AuthTokensDto.fromJson(response.data!);
  }

  Future<AuthTokensDto> signInWithApple({required String idToken}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/accounts/auth/apple/',
      data: {'id_token': idToken},
    );

    return AuthTokensDto.fromJson(response.data!);
  }

  Future<void> requestPasswordReset(String email) async {
    await _dio.post<Map<String, dynamic>>(
      '/accounts/password-reset/request/',
      data: {'email': email},
    );
  }
}
