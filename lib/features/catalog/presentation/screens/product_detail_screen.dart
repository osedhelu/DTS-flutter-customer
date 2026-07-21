import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/application/providers/cart_providers.dart';
import '../../application/providers/catalog_providers.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({
    super.key,
    required this.storeId,
    required this.storeName,
    required this.productId,
  });

  final int storeId;
  final String storeName;
  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(
      productDetailProvider((storeId: storeId, productId: productId)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Producto')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (detail) {
          final product = detail.product;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (detail.images.isNotEmpty)
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: detail.images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => Image.network(
                        detail.images[i],
                        width: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else if (product.primaryImageUrl != null)
                  Image.network(product.primaryImageUrl!, height: 180),
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text('\$${product.price.toStringAsFixed(2)}'),
                if (product.description != null) ...[
                  const SizedBox(height: 8),
                  Text(product.description!),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('add_to_cart_button'),
                    onPressed: () {
                      ref.read(cartNotifierProvider.notifier).addProduct(
                            storeId: storeId,
                            storeName: storeName,
                            product: product,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Agregado al carrito')),
                      );
                    },
                    child: const Text('Agregar al carrito'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
