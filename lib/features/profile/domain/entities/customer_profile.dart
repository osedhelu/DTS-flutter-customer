import 'package:equatable/equatable.dart';

class CustomerProfile extends Equatable {
  const CustomerProfile({
    required this.fullName,
    required this.phone,
    required this.photoUrl,
    required this.defaultAddress,
  });

  final String fullName;
  final String phone;
  final String photoUrl;
  final String defaultAddress;

  @override
  List<Object?> get props => [fullName, phone, photoUrl, defaultAddress];
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
