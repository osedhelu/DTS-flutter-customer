import '../entities/category.dart';
import '../entities/product.dart';
import '../entities/product_detail.dart';

class ProductFilters {
  const ProductFilters({
    this.productType,
    this.categoryId,
    this.subcategoryId,
    this.search,
  });

  final ProductType? productType;
  final int? categoryId;
  final int? subcategoryId;
  final String? search;
}

enum ProductSort { nameAsc, priceAsc, priceDesc }

abstract class CatalogRepository {
  Future<List<Product>> getProductsByStore(int storeId, {ProductFilters? filters});

  Future<List<ProductCategory>> getCategoriesByStore(int storeId);

  Future<ProductDetail> getProductDetail(int storeId, int productId);
}
