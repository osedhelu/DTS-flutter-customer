import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../cart/application/providers/cart_providers.dart';
import '../../application/providers/catalog_providers.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key, required this.storeId, this.storeName});

  final int storeId;
  final String? storeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider(storeId));
    final categoriesAsync = ref.watch(categoriesProvider(storeId));
    final filters = ref.watch(catalogFiltersProvider);
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(storeName ?? 'Catálogo'),
        actions: [
          if (cartCount > 0)
            IconButton(
              key: const Key('catalog_cart_button'),
              icon: Badge(label: Text('$cartCount'), child: const Icon(Icons.shopping_cart)),
              onPressed: () => context.push('/checkout'),
            ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            filters: filters,
            categoriesAsync: categoriesAsync,
            onTypeChanged: (type) =>
                ref.read(catalogFiltersProvider.notifier).setProductType(type),
            onCategoryChanged: (id) =>
                ref.read(catalogFiltersProvider.notifier).setCategory(id),
            onSubcategoryChanged: (id) =>
                ref.read(catalogFiltersProvider.notifier).setSubcategory(id),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (products) {
                if (products.isEmpty) {
                  return const Center(child: Text('Sin productos'));
                }
                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      key: Key('product_tile_${product.id}'),
                      title: Text(product.name),
                      subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                      trailing: _ProductTypeBadge(type: product.productType),
                      onTap: () {
                        if (product.isService) {
                          context.push(
                            '/stores/$storeId/catalog/services/${product.id}',
                            extra: product,
                          );
                        } else {
                          context.push(
                            '/stores/$storeId/catalog/products/${product.id}',
                            extra: product,
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filters,
    required this.categoriesAsync,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    required this.onSubcategoryChanged,
  });

  final CatalogFiltersState filters;
  final AsyncValue<List<ProductCategory>> categoriesAsync;
  final ValueChanged<ProductType?> onTypeChanged;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<int?> onSubcategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                key: const Key('filter_physical'),
                label: const Text('Physical'),
                selected: filters.productType == ProductType.physical,
                onSelected: (_) => onTypeChanged(
                  filters.productType == ProductType.physical
                      ? null
                      : ProductType.physical,
                ),
              ),
              FilterChip(
                key: const Key('filter_service'),
                label: const Text('Service'),
                selected: filters.productType == ProductType.service,
                onSelected: (_) => onTypeChanged(
                  filters.productType == ProductType.service
                      ? null
                      : ProductType.service,
                ),
              ),
            ],
          ),
          categoriesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();
              ProductCategory? selectedCategory;
              for (final category in categories) {
                if (category.id == filters.categoryId) {
                  selectedCategory = category;
                  break;
                }
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<int?>(
                    key: const Key('category_dropdown'),
                    isExpanded: true,
                    hint: const Text('Categoría'),
                    value: filters.categoryId,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      ...categories.map(
                        (category) => DropdownMenuItem<int?>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      ),
                    ],
                    onChanged: onCategoryChanged,
                  ),
                  if (selectedCategory != null &&
                      selectedCategory.subcategories.isNotEmpty)
                    DropdownButton<int?>(
                      key: const Key('subcategory_dropdown'),
                      isExpanded: true,
                      hint: const Text('Subcategoría'),
                      value: filters.subcategoryId,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Todas'),
                        ),
                        ...selectedCategory.subcategories.map(
                          (sub) => DropdownMenuItem<int?>(
                            value: sub.id,
                            child: Text(sub.name),
                          ),
                        ),
                      ],
                      onChanged: onSubcategoryChanged,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProductTypeBadge extends StatelessWidget {
  const _ProductTypeBadge({required this.type});

  final ProductType type;

  @override
  Widget build(BuildContext context) {
    final label = type == ProductType.service ? 'Service' : 'Physical';
    return Chip(
      key: Key('badge_$label'),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
