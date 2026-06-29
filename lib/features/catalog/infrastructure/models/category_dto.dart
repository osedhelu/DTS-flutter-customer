import '../../domain/entities/category.dart';

class CategoryDto {
  const CategoryDto({
    required this.id,
    required this.name,
    this.subcategories = const [],
  });

  final int id;
  final String name;
  final List<SubcategoryDto> subcategories;

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      id: json['id'] as int,
      name: json['name'] as String,
      subcategories: (json['subcategories'] as List<dynamic>? ?? [])
          .map((item) => SubcategoryDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  ProductCategory toEntity() => ProductCategory(
        id: id,
        name: name,
        subcategories: subcategories.map((s) => s.toEntity()).toList(),
      );
}

class SubcategoryDto {
  const SubcategoryDto({
    required this.id,
    required this.name,
    required this.parentId,
  });

  final int id;
  final String name;
  final int parentId;

  factory SubcategoryDto.fromJson(Map<String, dynamic> json) {
    return SubcategoryDto(
      id: json['id'] as int,
      name: json['name'] as String,
      parentId: json['parent_id'] as int,
    );
  }

  ProductSubcategory toEntity() => ProductSubcategory(
        id: id,
        name: name,
        parentId: parentId,
      );
}
