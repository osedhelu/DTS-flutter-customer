import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/repository_providers.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_detail.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/usecases/get_products_by_store_usecase.dart';
import '../../domain/usecases/get_product_detail_usecase.dart';

class CatalogFiltersState {
  const CatalogFiltersState({
    this.productType,
    this.categoryId,
    this.subcategoryId,
    this.search = '',
    this.sort = ProductSort.nameAsc,
  });

  final ProductType? productType;
  final int? categoryId;
  final int? subcategoryId;
  final String search;
  final ProductSort sort;

  ProductFilters toFilters() => ProductFilters(
        productType: productType,
        categoryId: categoryId,
        subcategoryId: subcategoryId,
        search: search.trim().isEmpty ? null : search.trim(),
      );

  CatalogFiltersState copyWith({
    ProductType? productType,
    int? categoryId,
    int? subcategoryId,
    String? search,
    ProductSort? sort,
    bool clearProductType = false,
    bool clearCategory = false,
    bool clearSubcategory = false,
  }) {
    return CatalogFiltersState(
      productType: clearProductType ? null : productType ?? this.productType,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      subcategoryId:
          clearSubcategory ? null : subcategoryId ?? this.subcategoryId,
      search: search ?? this.search,
      sort: sort ?? this.sort,
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

  void setSearch(String value) {
    state = state.copyWith(search: value);
  }

  void setSort(ProductSort sort) {
    state = state.copyWith(sort: sort);
  }
}

List<Product> sortProducts(List<Product> products, ProductSort sort) {
  final copy = [...products];
  switch (sort) {
    case ProductSort.priceAsc:
      copy.sort((a, b) => a.price.compareTo(b.price));
    case ProductSort.priceDesc:
      copy.sort((a, b) => b.price.compareTo(a.price));
    case ProductSort.nameAsc:
      copy.sort((a, b) => a.name.compareTo(b.name));
  }
  return copy;
}

final getProductsByStoreUseCaseProvider = Provider<GetProductsByStoreUseCase>((ref) {
  return GetProductsByStoreUseCase(ref.watch(catalogRepositoryProvider));
});

final getProductDetailUseCaseProvider = Provider<GetProductDetailUseCase>((ref) {
  return GetProductDetailUseCase(ref.watch(catalogRepositoryProvider));
});

final catalogFiltersProvider =
    StateNotifierProvider<CatalogFiltersNotifier, CatalogFiltersState>((ref) {
  return CatalogFiltersNotifier();
});

final categoriesProvider =
    FutureProvider.family<List<ProductCategory>, int>((ref, storeId) {
  return ref.watch(catalogRepositoryProvider).getCategoriesByStore(storeId);
});

final productsProvider = FutureProvider.family<List<Product>, int>((ref, storeId) async {
  final filters = ref.watch(catalogFiltersProvider);
  final products = await ref.watch(getProductsByStoreUseCaseProvider).call(
        storeId: storeId,
        filters: filters.toFilters(),
      );
  return sortProducts(products, filters.sort);
});

final productDetailProvider =
    FutureProvider.family<ProductDetail, ({int storeId, int productId})>(
        (ref, params) {
  return ref.watch(getProductDetailUseCaseProvider).call(
        storeId: params.storeId,
        productId: params.productId,
      );
});
