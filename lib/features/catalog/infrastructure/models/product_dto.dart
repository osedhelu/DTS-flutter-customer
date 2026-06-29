import '../../domain/entities/product.dart';

class ProductDto {
  const ProductDto({
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
  final String productType;
  final int? categoryId;
  final int? subcategoryId;
  final String? description;
  final int? durationMinutes;
  final String? primaryImageUrl;
  final int stock;

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    return ProductDto(
      id: json['id'] as int,
      name: json['name'] as String,
      price: double.parse(json['price'].toString()),
      storeId: json['store_id'] as int,
      productType: json['product_type'] as String,
      categoryId: json['category_id'] as int?,
      subcategoryId: json['subcategory_id'] as int?,
      description: json['description'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      primaryImageUrl: json['primary_image_url'] as String?,
      stock: json['stock'] as int? ?? 0,
    );
  }

  Product toEntity() => Product(
        id: id,
        name: name,
        price: price,
        storeId: storeId,
        productType: productTypeFromApi(productType),
        categoryId: categoryId,
        subcategoryId: subcategoryId,
        description: description,
        durationMinutes: durationMinutes,
        primaryImageUrl: primaryImageUrl,
        stock: stock,
      );
}
