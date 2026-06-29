import 'package:dio/dio.dart';

import '../../../../core/utils/pagination.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../models/category_dto.dart';
import '../models/product_dto.dart';

class CatalogRemoteDataSource {
  const CatalogRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ProductDto>> fetchProducts(
    int storeId, {
    ProductFilters? filters,
  }) async {
    final query = <String, dynamic>{};
    if (filters?.productType != null) {
      query['product_type'] = productTypeToApi(filters!.productType!);
    }
    if (filters?.categoryId != null) {
      query['category_id'] = filters!.categoryId;
    }
    if (filters?.subcategoryId != null) {
      query['subcategory_id'] = filters!.subcategoryId;
    }

    final response = await _dio.get<dynamic>(
      '/stores/$storeId/products/',
      queryParameters: query.isEmpty ? null : query,
    );
    return parsePaginatedList(response.data, ProductDto.fromJson);
  }

  Future<List<CategoryDto>> fetchCategories(int storeId) async {
    final response = await _dio.get<dynamic>('/stores/$storeId/categories/');
    return parsePaginatedList(response.data, CategoryDto.fromJson);
  }
}
