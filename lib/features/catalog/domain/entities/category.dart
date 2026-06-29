import 'package:equatable/equatable.dart';

class ProductCategory extends Equatable {
  const ProductCategory({
    required this.id,
    required this.name,
    this.subcategories = const [],
  });

  final int id;
  final String name;
  final List<ProductSubcategory> subcategories;

  @override
  List<Object?> get props => [id, name, subcategories];
}

class ProductSubcategory extends Equatable {
  const ProductSubcategory({
    required this.id,
    required this.name,
    required this.parentId,
  });

  final int id;
  final String name;
  final int parentId;

  @override
  List<Object?> get props => [id, name, parentId];
}
