import '../entities/product_detail.dart';
import '../repositories/catalog_repository.dart';

class GetProductDetailUseCase {
  const GetProductDetailUseCase(this._repository);

  final CatalogRepository _repository;

  Future<ProductDetail> call({
    required int storeId,
    required int productId,
  }) {
    return _repository.getProductDetail(storeId, productId);
  }
}
