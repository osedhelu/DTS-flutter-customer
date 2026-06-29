import '../entities/product.dart';
import '../repositories/catalog_repository.dart';

class GetProductsByStoreUseCase {
  const GetProductsByStoreUseCase(this._repository);

  final CatalogRepository _repository;

  Future<List<Product>> call({
    required int storeId,
    ProductFilters? filters,
  }) {
    return _repository.getProductsByStore(storeId, filters: filters);
  }
}
