import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/widgets.dart';
import '../../../catalog/domain/entities/product.dart';
import '../../application/providers/cart_providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito'),
        actions: [
          if (cart != null && !cart.isEmpty)
            TextButton(
              onPressed: () => ref.read(cartNotifierProvider.notifier).clear(),
              child: const Text('Vaciar'),
            ),
        ],
      ),
      body: cart == null || cart.isEmpty
          ? DtsEmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Carrito vacío',
              message: 'Agrega productos desde un comercio.',
              actionLabel: 'Ir a comercios',
              onAction: () => context.go('/home'),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: DtsSectionHeader(
                    title: cart.storeName,
                    subtitle: '${cart.itemCount} artículos',
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Card(
                        child: ListTile(
                          title: Text(item.product.name),
                          subtitle: Text(
                            '\$${item.product.price.toStringAsFixed(2)} c/u',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => ref
                                    .read(cartNotifierProvider.notifier)
                                    .setQuantity(
                                      item.product.id,
                                      item.quantity - 1,
                                    ),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text(
                                '${item.quantity}',
                                style: theme.textTheme.titleMedium,
                              ),
                              IconButton(
                                onPressed: () => ref
                                    .read(cartNotifierProvider.notifier)
                                    .setQuantity(
                                      item.product.id,
                                      item.quantity + 1,
                                    ),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Total: \$${cart.total.toStringAsFixed(2)}',
                          style: theme.textTheme.titleLarge,
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 12),
                        DtsPrimaryButton(
                          label: 'Ir al checkout',
                          onPressed: () {
                            final hasPhysical = cart.items
                                .any((i) => !i.product.isService);
                            final hasService = cart.items
                                .any((i) => i.product.isService);
                            if (hasPhysical && hasService) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'No puedes mezclar productos y servicios. Vacía el carrito o pide por separado.',
                                  ),
                                ),
                              );
                              return;
                            }
                            context.push(
                              hasService ? '/checkout/service' : '/checkout',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
