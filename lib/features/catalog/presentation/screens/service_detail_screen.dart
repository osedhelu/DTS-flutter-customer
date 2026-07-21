import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../cart/application/providers/cart_providers.dart';
import '../../application/providers/catalog_providers.dart';
import '../widgets/dynamic_fields_form.dart';

class ServiceDetailScreen extends ConsumerStatefulWidget {
  const ServiceDetailScreen({
    super.key,
    required this.storeId,
    required this.storeName,
    required this.productId,
  });

  final int storeId;
  final String storeName;
  final int productId;

  @override
  ConsumerState<ServiceDetailScreen> createState() =>
      _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  Map<String, dynamic> _dynamicValues = const {};
  String _dynamicNotes = '';

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      productDetailProvider(
        (storeId: widget.storeId, productId: widget.productId),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Servicio')),
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
                if (product.primaryImageUrl != null)
                  Image.network(product.primaryImageUrl!, height: 180),
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text('\$${product.price.toStringAsFixed(2)}'),
                if (product.durationMinutes != null) ...[
                  const SizedBox(height: 8),
                  Text('Duración estimada: ${product.durationMinutes} min'),
                ],
                if (product.description != null) ...[
                  const SizedBox(height: 8),
                  Text(product.description!),
                ],
                const SizedBox(height: 12),
                DynamicFieldsForm(
                  fieldConfig: detail.fieldConfig,
                  onChanged: (values) {
                    setState(() {
                      _dynamicValues = values;
                      _dynamicNotes = formatDynamicValuesNotes(values);
                    });
                  },
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('request_service_button'),
                    onPressed: () {
                      ref.read(cartNotifierProvider.notifier).addProduct(
                            storeId: widget.storeId,
                            storeName: widget.storeName,
                            product: product,
                            notes: _dynamicNotes.isEmpty ? null : _dynamicNotes,
                          );
                      context.push('/checkout/service');
                    },
                    child: const Text('Solicitar servicio'),
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
