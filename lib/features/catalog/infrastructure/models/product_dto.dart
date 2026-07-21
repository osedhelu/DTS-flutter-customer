import '../../domain/entities/product.dart';
import '../../domain/entities/product_detail.dart';

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
    this.promotionBadge,
    this.stock = 0,
    this.dynamicValues = const {},
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
  final String? promotionBadge;
  final int stock;
  final Map<String, dynamic> dynamicValues;

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
      promotionBadge: json['promotion_badge'] as String?,
      stock: json['stock'] as int? ?? 0,
      dynamicValues: _parseDynamicValues(json['dynamic_values']),
    );
  }

  static Map<String, dynamic> _parseDynamicValues(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    return const {};
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
        promotionBadge: promotionBadge,
        stock: stock,
        dynamicValues: dynamicValues,
      );
}

ProductDetail productDetailFromPublicJson(Map<String, dynamic> json) {
  final images = (json['images'] as List<dynamic>? ?? [])
      .map((item) {
        if (item is Map<String, dynamic>) {
          return item['url'] as String? ??
              item['image_url'] as String? ??
              '';
        }
        return item.toString();
      })
      .where((url) => url.isNotEmpty)
      .cast<String>()
      .toList();

  final dto = ProductDto.fromJson(json);
  final primary =
      dto.primaryImageUrl ?? (images.isNotEmpty ? images.first : null);

  return ProductDetail(
    product: ProductDto(
      id: dto.id,
      name: dto.name,
      price: dto.price,
      storeId: dto.storeId,
      productType: dto.productType,
      categoryId: dto.categoryId,
      subcategoryId: dto.subcategoryId,
      description: dto.description,
      durationMinutes: dto.durationMinutes,
      primaryImageUrl: primary,
      promotionBadge: dto.promotionBadge,
      stock: dto.stock,
      dynamicValues: dto.dynamicValues,
    ).toEntity(),
    images: images,
    dynamicValues: dto.dynamicValues,
    fieldConfig: (json['field_config'] as Map<String, dynamic>?) ?? const {},
  );
}
