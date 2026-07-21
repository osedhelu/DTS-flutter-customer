import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
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
  String _dynamicNotes = '';

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      productDetailProvider(
        (storeId: widget.storeId, productId: widget.productId),
      ),
    );
    final theme = Theme.of(context);

    return Scaffold(
      body: detailAsync.when(
        loading: () => const DtsLoading(),
        error: (e, _) => DtsErrorView(
          message: 'No se pudo cargar el servicio',
          onRetry: () => ref.invalidate(
            productDetailProvider(
              (storeId: widget.storeId, productId: widget.productId),
            ),
          ),
        ),
        data: (detail) {
          final product = detail.product;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                title: const Text('Servicio'),
                flexibleSpace: FlexibleSpaceBar(
                  background: DtsNetworkImage(url: product.primaryImageUrl),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        product.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DtsPriceTag(amount: product.price, emphasized: true),
                      if (product.durationMinutes != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Duración estimada: ${product.durationMinutes} min',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if ((product.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        DtsSectionCard(
                          title: 'Descripción',
                          child: Text(product.description!),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      DtsSectionCard(
                        title: 'Detalles',
                        child: DynamicFieldsForm(
                          fieldConfig: detail.fieldConfig,
                          onChanged: (values) {
                            setState(() {
                              _dynamicNotes = formatDynamicValuesNotes(values);
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: detailAsync.maybeWhen(
        data: (detail) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: DtsPrimaryButton(
              key: const Key('request_service_button'),
              label: 'Solicitar servicio',
              icon: Icons.handshake_outlined,
              onPressed: () {
                ref.read(cartNotifierProvider.notifier).addProduct(
                      storeId: widget.storeId,
                      storeName: widget.storeName,
                      product: detail.product,
                      notes: _dynamicNotes.isEmpty ? null : _dynamicNotes,
                    );
                context.push('/checkout/service');
              },
            ),
          ),
        ),
        orElse: () => null,
      ),
    );
  }
}
