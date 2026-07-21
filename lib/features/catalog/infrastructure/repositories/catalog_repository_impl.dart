import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_detail.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_remote_datasource.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  const CatalogRepositoryImpl({required CatalogRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final CatalogRemoteDataSource _remoteDataSource;

  @override
  Future<List<ProductCategory>> getCategoriesByStore(int storeId) async {
    final dtos = await _remoteDataSource.fetchCategories(storeId);
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<List<Product>> getProductsByStore(
    int storeId, {
    ProductFilters? filters,
  }) async {
    final dtos = await _remoteDataSource.fetchProducts(storeId, filters: filters);
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<ProductDetail> getProductDetail(int storeId, int productId) {
    return _remoteDataSource.fetchProductDetail(storeId, productId);
  }
}
