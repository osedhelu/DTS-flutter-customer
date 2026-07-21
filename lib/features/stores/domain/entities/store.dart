import 'package:equatable/equatable.dart';

class Store extends Equatable {
  const Store({
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

  bool get isServicesVertical =>
      (vertical ?? '').toUpperCase() == 'SERVICES';

  @override
  List<Object?> get props => [id, name, description, logoUrl, address, isOpen, vertical];
}
