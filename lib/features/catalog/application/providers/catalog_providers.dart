import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/repository_providers.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/usecases/get_products_by_store_usecase.dart';

class CatalogFiltersState {
  const CatalogFiltersState({
    this.productType,
    this.categoryId,
    this.subcategoryId,
  });

  final ProductType? productType;
  final int? categoryId;
  final int? subcategoryId;

  ProductFilters toFilters() => ProductFilters(
        productType: productType,
        categoryId: categoryId,
        subcategoryId: subcategoryId,
      );

  CatalogFiltersState copyWith({
    ProductType? productType,
    int? categoryId,
    int? subcategoryId,
    bool clearProductType = false,
    bool clearCategory = false,
    bool clearSubcategory = false,
  }) {
    return CatalogFiltersState(
      productType: clearProductType ? null : productType ?? this.productType,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      subcategoryId:
          clearSubcategory ? null : subcategoryId ?? this.subcategoryId,
    );
  }
}

class CatalogFiltersNotifier extends StateNotifier<CatalogFiltersState> {
  CatalogFiltersNotifier() : super(const CatalogFiltersState());

  void setProductType(ProductType? type) {
    state = state.copyWith(productType: type, clearProductType: type == null);
  }

  void setCategory(int? categoryId) {
    state = state.copyWith(
      categoryId: categoryId,
      clearCategory: categoryId == null,
      clearSubcategory: true,
    );
  }

  void setSubcategory(int? subcategoryId) {
    state = state.copyWith(
      subcategoryId: subcategoryId,
      clearSubcategory: subcategoryId == null,
    );
  }
}

final getProductsByStoreUseCaseProvider = Provider<GetProductsByStoreUseCase>((ref) {
  return GetProductsByStoreUseCase(ref.watch(catalogRepositoryProvider));
});

final catalogFiltersProvider =
    StateNotifierProvider<CatalogFiltersNotifier, CatalogFiltersState>((ref) {
  return CatalogFiltersNotifier();
});

final categoriesProvider =
    FutureProvider.family<List<ProductCategory>, int>((ref, storeId) {
  return ref.watch(catalogRepositoryProvider).getCategoriesByStore(storeId);
});

final productsProvider = FutureProvider.family<List<Product>, int>((ref, storeId) {
  final filters = ref.watch(catalogFiltersProvider);
  return ref.watch(getProductsByStoreUseCaseProvider).call(
        storeId: storeId,
        filters: filters.toFilters(),
      );
});
