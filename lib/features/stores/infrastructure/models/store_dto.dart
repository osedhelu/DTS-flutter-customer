import '../../domain/entities/store.dart';

class StoreDto {
  const StoreDto({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.address,
    this.isOpen = true,
    this.vertical,
  });

  final int id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? address;
  final bool isOpen;
  final String? vertical;

  factory StoreDto.fromJson(Map<String, dynamic> json) {
    return StoreDto(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      address: json['address'] as String?,
      isOpen: json['is_open'] as bool? ?? true,
      vertical: json['vertical'] as String?,
    );
  }

  Store toEntity() => Store(
        id: id,
        name: name,
        description: description,
        logoUrl: logoUrl,
        address: address,
        isOpen: isOpen,
        vertical: vertical,
      );
}
