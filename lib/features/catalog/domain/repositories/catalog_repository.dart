import '../entities/category.dart';
import '../entities/product.dart';

class ProductFilters {
  const ProductFilters({
    this.productType,
    this.categoryId,
    this.subcategoryId,
  });

  final ProductType? productType;
  final int? categoryId;
  final int? subcategoryId;
}

abstract class CatalogRepository {
  Future<List<Product>> getProductsByStore(int storeId, {ProductFilters? filters});

  Future<List<ProductCategory>> getCategoriesByStore(int storeId);
}
