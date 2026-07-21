import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/providers/cart_providers.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key, this.embeddedInShell = false});

  /// Cuando está en el tab shell, no muestra botón atrás implícito.
  final bool embeddedInShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito'),
        automaticallyImplyLeading: !embeddedInShell,
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
              icon: Icons.shopping_bag_outlined,
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
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DtsNetworkImage(
                                url: item.product.primaryImageUrl,
                                width: 64,
                                height: 64,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${item.product.price.toStringAsFixed(2)} c/u',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 8),
                                    DtsQtyStepper(
                                      quantity: item.quantity,
                                      onChanged: (q) => ref
                                          .read(cartNotifierProvider.notifier)
                                          .setQuantity(item.product.id, q),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${item.subtotal.toStringAsFixed(2)}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Total',
                              style: theme.textTheme.titleMedium,
                            ),
                            const Spacer(),
                            DtsPriceTag(amount: cart.total, emphasized: true),
                          ],
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
