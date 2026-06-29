import 'package:equatable/equatable.dart';

enum ProductType { physical, service }

ProductType productTypeFromApi(String value) {
  switch (value.toUpperCase()) {
    case 'SERVICE':
      return ProductType.service;
    default:
      return ProductType.physical;
  }
}

String productTypeToApi(ProductType type) {
  switch (type) {
    case ProductType.service:
      return 'SERVICE';
    case ProductType.physical:
      return 'PHYSICAL';
  }
}

class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.storeId,
    required this.productType,
    this.categoryId,
    this.subcategoryId,
    this.description,
    this.durationMinutes,
    this.primaryImageUrl,
    this.stock = 0,
  });

  final int id;
  final String name;
  final double price;
  final int storeId;
  final ProductType productType;
  final int? categoryId;
  final int? subcategoryId;
  final String? description;
  final int? durationMinutes;
  final String? primaryImageUrl;
  final int stock;

  bool get isService => productType == ProductType.service;

  @override
  List<Object?> get props => [
        id,
        name,
        price,
        storeId,
        productType,
        categoryId,
        subcategoryId,
        description,
        durationMinutes,
        primaryImageUrl,
        stock,
      ];
}
