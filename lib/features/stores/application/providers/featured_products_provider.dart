import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../catalog/domain/entities/product.dart';
import '../../../catalog/infrastructure/models/product_dto.dart';
import '../../domain/entities/store.dart';

/// Producto destacado para el rail "Más vendidos" (incluye storeName).
class FeaturedProduct {
  const FeaturedProduct({
    required this.product,
    required this.storeName,
  });

  final Product product;
  final String storeName;
}

/// Intenta endpoint de marketing; si falla, toma productos de tiendas abiertas.
final featuredProductsProvider =
    FutureProvider<List<FeaturedProduct>>((ref) async {
  final dio = ref.watch(apiClientProvider).dio;

  try {
    final res = await dio.get<dynamic>('/marketing/featured-products/');
    final data = res.data;
    final list = data is List
        ? data
        : (data is Map ? data['results'] as List? ?? [] : <dynamic>[]);
    if (list.isNotEmpty) {
      final out = <FeaturedProduct>[];
      for (final raw in list) {
        final map = Map<String, dynamic>.from(raw as Map);
        final dto = ProductDto.fromJson(map);
        final storeName =
            map['store_name']?.toString() ?? map['merchant_name']?.toString() ?? 'Comercio';
        out.add(FeaturedProduct(product: dto.toEntity(), storeName: storeName));
      }
      if (out.isNotEmpty) return out.take(12).toList();
    }
  } catch (_) {}

  final stores = await ref.watch(storesListProvider.future);
  return _fallbackFromOpenStores(ref, stores);
});

Future<List<FeaturedProduct>> _fallbackFromOpenStores(
  Ref ref,
  List<Store> stores,
) async {
  final open = stores.where((s) => s.isOpen).take(4).toList();
  if (open.isEmpty) return const [];

  final catalog = ref.read(catalogRepositoryProvider);
  final collected = <FeaturedProduct>[];

  for (final store in open) {
    try {
      final products = await catalog.getProductsByStore(store.id);
      for (final p in products.take(3)) {
        collected.add(FeaturedProduct(product: p, storeName: store.name));
        if (collected.length >= 10) return collected;
      }
    } catch (_) {}
  }
  return collected;
}
