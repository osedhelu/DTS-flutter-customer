import 'package:equatable/equatable.dart';

import '../../../../core/constants/location_radius_constants.dart';

class CustomerProfile extends Equatable {
  const CustomerProfile({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.defaultAddress,
    this.searchCenterLatitude,
    this.searchCenterLongitude,
    this.searchRadiusKm = defaultRadiusKm,
  });

  final String fullName;
  final String email;
  final String phone;
  final String photoUrl;
  final String defaultAddress;
  final double? searchCenterLatitude;
  final double? searchCenterLongitude;
  final double searchRadiusKm;

  bool get hasSearchCenter =>
      searchCenterLatitude != null && searchCenterLongitude != null;

  @override
  List<Object?> get props => [
        fullName,
        email,
        phone,
        photoUrl,
        defaultAddress,
        searchCenterLatitude,
        searchCenterLongitude,
        searchRadiusKm,
      ];
}

class CustomerAddress extends Equatable {
  const CustomerAddress({
    required this.id,
    required this.label,
    required this.address,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  final int id;
  final String label;
  final String address;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  @override
  List<Object?> get props => [id, label, address, latitude, longitude, isDefault];
}
