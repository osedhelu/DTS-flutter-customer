import 'package:dio/dio.dart';

import '../../../../core/constants/location_radius_constants.dart';
import '../../domain/entities/customer_profile.dart';

class CustomerProfileRemoteDataSource {
  const CustomerProfileRemoteDataSource(this._dio);

  final Dio _dio;

  Future<CustomerProfile> getProfile() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/accounts/customer/profile/',
    );
    return _profileFromJson(res.data!);
  }

  Future<CustomerProfile> updateProfile({
    String? fullName,
    String? phone,
    String? photoUrl,
    String? defaultAddress,
    double? searchCenterLatitude,
    double? searchCenterLongitude,
    double? searchRadiusKm,
  }) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/accounts/customer/profile/',
      data: {
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (defaultAddress != null) 'default_address': defaultAddress,
        if (searchCenterLatitude != null)
          'search_center_latitude': searchCenterLatitude,
        if (searchCenterLongitude != null)
          'search_center_longitude': searchCenterLongitude,
        if (searchRadiusKm != null) 'search_radius_km': searchRadiusKm,
      },
    );
    return _profileFromJson(res.data!);
  }

  CustomerProfile _profileFromJson(Map<String, dynamic> j) {
    return CustomerProfile(
      fullName: j['full_name'] as String? ?? '',
      email: j['email'] as String? ?? '',
      phone: j['phone'] as String? ?? '',
      photoUrl: j['photo_url'] as String? ?? '',
      defaultAddress: j['default_address'] as String? ?? '',
      searchCenterLatitude:
          (j['search_center_latitude'] as num?)?.toDouble(),
      searchCenterLongitude:
          (j['search_center_longitude'] as num?)?.toDouble(),
      searchRadiusKm:
          (j['search_radius_km'] as num?)?.toDouble() ?? defaultRadiusKm,
    );
  }

  Future<List<CustomerAddress>> listAddresses() async {
    final res = await _dio.get<dynamic>('/accounts/customer/addresses/');
    final data = res.data;
    final List<dynamic> list;
    if (data is Map) {
      list = data['results'] as List? ?? [];
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }
    return list.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return CustomerAddress(
        id: m['id'] as int,
        label: m['label'] as String? ?? '',
        address: m['address'] as String? ?? '',
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        isDefault: m['is_default'] as bool? ?? false,
      );
    }).toList();
  }

  Future<CustomerAddress> createAddress({
    required String label,
    required String address,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/accounts/customer/addresses/',
      data: {
        'label': label,
        'address': address,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'is_default': isDefault,
      },
    );
    final m = res.data!;
    return CustomerAddress(
      id: m['id'] as int,
      label: m['label'] as String? ?? label,
      address: m['address'] as String? ?? address,
      latitude: (m['latitude'] as num?)?.toDouble(),
      longitude: (m['longitude'] as num?)?.toDouble(),
      isDefault: m['is_default'] as bool? ?? isDefault,
    );
  }

  Future<void> deleteAddress(int id) async {
    await _dio.delete('/accounts/customer/addresses/$id/');
  }
}
