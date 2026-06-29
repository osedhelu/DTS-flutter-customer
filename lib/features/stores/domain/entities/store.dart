import 'package:equatable/equatable.dart';

class Store extends Equatable {
  const Store({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.address,
    this.isOpen = true,
  });

  final int id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? address;
  final bool isOpen;

  @override
  List<Object?> get props => [id, name, description, logoUrl, address, isOpen];
}
