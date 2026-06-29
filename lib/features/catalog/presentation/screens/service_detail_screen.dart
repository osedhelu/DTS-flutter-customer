import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../cart/application/providers/cart_providers.dart';
import '../../domain/entities/product.dart';

class ServiceDetailScreen extends ConsumerWidget {
  const ServiceDetailScreen({
    super.key,
    required this.storeId,
    required this.storeName,
    required this.product,
  });

  final int storeId;
  final String storeName;
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('\$${product.price.toStringAsFixed(2)}'),
            if (product.durationMinutes != null) ...[
              const SizedBox(height: 8),
              Text('Duración: ${product.durationMinutes} min'),
            ],
            if (product.description != null) ...[
              const SizedBox(height: 8),
              Text(product.description!),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('request_service_button'),
                onPressed: () {
                  ref.read(cartNotifierProvider.notifier).addProduct(
                        storeId: storeId,
                        storeName: storeName,
                        product: product,
                      );
                  context.push('/checkout/service');
                },
                child: const Text('Solicitar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
