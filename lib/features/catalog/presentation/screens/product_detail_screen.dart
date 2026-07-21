import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../cart/application/providers/cart_providers.dart';
import '../../../shell/presentation/screens/customer_shell_screen.dart';
import '../../application/providers/catalog_providers.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
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
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _qty = 1;

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
          message: 'No se pudo cargar el producto',
          onRetry: () => ref.invalidate(
            productDetailProvider(
              (storeId: widget.storeId, productId: widget.productId),
            ),
          ),
        ),
        data: (detail) {
          final product = detail.product;
          final images = detail.images.isNotEmpty
              ? detail.images
              : [
                  if ((product.primaryImageUrl ?? '').isNotEmpty)
                    product.primaryImageUrl!,
                ];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                title: const Text('Producto'),
                flexibleSpace: FlexibleSpaceBar(
                  background: images.isEmpty
                      ? ColoredBox(
                          color: theme.colorScheme.secondaryContainer,
                          child: const Icon(Icons.image_outlined, size: 64),
                        )
                      : PageView.builder(
                          itemCount: images.length,
                          itemBuilder: (_, i) => DtsNetworkImage(url: images[i]),
                        ),
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
                      if ((product.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        DtsSectionCard(
                          title: 'Descripción',
                          child: Text(
                            product.description!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      DtsSectionCard(
                        title: 'Cantidad',
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: DtsQtyStepper(
                            quantity: _qty,
                            min: 1,
                            onChanged: (v) => setState(() => _qty = v),
                          ),
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
              key: const Key('add_to_cart_button'),
              label: 'Agregar al carrito',
              icon: Icons.add_shopping_cart_rounded,
              onPressed: () {
                ref.read(cartNotifierProvider.notifier).addProduct(
                      storeId: widget.storeId,
                      storeName: widget.storeName,
                      product: detail.product,
                      quantity: _qty,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Agregado al carrito'),
                    action: SnackBarAction(
                      label: 'Ver',
                      onPressed: () => goToCart(context),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        orElse: () => null,
      ),
    );
  }
}
