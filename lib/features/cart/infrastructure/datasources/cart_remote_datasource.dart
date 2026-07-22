import 'package:dio/dio.dart';

import '../../../catalog/domain/entities/product.dart';
import '../../domain/entities/cart.dart';

class CartRemoteDataSource {
  const CartRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Cart?> getCart() async {
    final res = await _dio.get<Map<String, dynamic>>('/cart/');
    return _mapCart(res.data);
  }

  Future<Cart?> upsertItem({
    required int productId,
    required int quantity,
    String? notes,
    bool replaceStore = true,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/cart/items/',
      data: {
        'product_id': productId,
        'quantity': quantity,
        if (notes != null) 'notes': notes,
        'replace_store': replaceStore,
      },
    );
    return _mapCart(res.data);
  }

  Future<Cart?> setQuantity({
    required int productId,
    required int quantity,
  }) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/cart/items/$productId/',
      data: {'quantity': quantity},
    );
    return _mapCart(res.data);
  }

  Future<Cart?> removeItem(int productId) async {
    final res = await _dio.delete<Map<String, dynamic>>(
      '/cart/items/$productId/',
    );
    return _mapCart(res.data);
  }

  Future<void> clearCart() async {
    await _dio.delete('/cart/');
  }

  Cart? _mapCart(Map<String, dynamic>? data) {
    if (data == null) return null;
    final storeId = data['store_id'] as int?;
    final itemsJson = data['items'] as List? ?? const [];
    if (storeId == null || itemsJson.isEmpty) return null;

    final items = itemsJson.map((raw) {
      final m = Map<String, dynamic>.from(raw as Map);
      final product = Product(
        id: m['product_id'] as int,
        name: m['name'] as String? ?? '',
        price: double.tryParse('${m['price']}') ?? 0,
        storeId: m['store_id'] as int? ?? storeId,
        productType: productTypeFromApi('${m['product_type'] ?? 'PHYSICAL'}'),
        primaryImageUrl: m['primary_image_url'] as String?,
        stock: m['stock'] as int? ?? 0,
      );
      return CartItem(
        product: product,
        quantity: m['quantity'] as int? ?? 1,
        notes: (m['notes'] as String?)?.trim().isEmpty == true
            ? null
            : m['notes'] as String?,
      );
    }).toList();

    return Cart(
      storeId: storeId,
      storeName: data['store_name'] as String? ?? '',
      items: items,
    );
  }
}
