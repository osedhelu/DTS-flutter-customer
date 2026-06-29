import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../cart/application/providers/cart_providers.dart';
import '../../../../core/di/providers.dart';
import '../../domain/entities/order.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _submitting = false;
  String? _error;

  Future<void> _confirm() async {
    final cart = ref.read(cartNotifierProvider);
    if (cart == null || cart.isEmpty) {
      setState(() => _error = 'El carrito está vacío');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final order = await ref.read(createOrderUseCaseProvider).call(
            CreateOrderParams(
              storeId: cart.storeId,
              items: cart.items
                  .map(
                    (item) => CreateOrderItem(
                      productId: item.product.id,
                      quantity: item.quantity,
                    ),
                  )
                  .toList(),
            ),
          );
      ref.read(cartNotifierProvider.notifier).clear();
      if (!mounted) return;
      context.go('/orders/${order.id}/tracking');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: cart == null
          ? const Center(child: Text('Carrito vacío'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Comercio: ${cart.storeName}'),
                  const SizedBox(height: 16),
                  ...cart.items.map(
                    (item) => ListTile(
                      title: Text(item.product.name),
                      subtitle: Text('x${item.quantity}'),
                      trailing: Text('\$${item.subtotal.toStringAsFixed(2)}'),
                    ),
                  ),
                  const Divider(),
                  Text(
                    'Total: \$${cart.total.toStringAsFixed(2)}',
                    key: const Key('checkout_total'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('confirm_order_button'),
                      onPressed: _submitting ? null : _confirm,
                      child: _submitting
                          ? const CircularProgressIndicator()
                          : const Text('Confirmar pedido'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
