import 'package:equatable/equatable.dart';

/// Punto de origen o destino de un viaje (dirección + coordenadas).
class RideLocation extends Equatable {
  const RideLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final double latitude;
  final double longitude;

  bool get isValid => address.trim().isNotEmpty;

  RideLocation copyWith({
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return RideLocation(
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  List<Object?> get props => [address, latitude, longitude];
}
