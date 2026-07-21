import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../cart/application/providers/cart_providers.dart';
import '../../application/providers/catalog_providers.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/catalog_repository.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key, required this.storeId, this.storeName});

  final int storeId;
  final String? storeName;

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider(widget.storeId));
    final categoriesAsync = ref.watch(categoriesProvider(widget.storeId));
    final filters = ref.watch(catalogFiltersProvider);
    final cartCount = ref.watch(cartItemCountProvider);
    final cart = ref.watch(cartNotifierProvider);
    final showStickyCart =
        cart != null && cart.storeId == widget.storeId && cartCount > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.storeName ?? 'Catálogo'),
        actions: [
          if (cartCount > 0)
            IconButton(
              key: const Key('catalog_cart_button'),
              icon: Badge(
                label: Text('$cartCount'),
                child: const Icon(Icons.shopping_cart),
              ),
              onPressed: () => context.push('/cart'),
            ),
        ],
      ),
      bottomNavigationBar: showStickyCart
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(
                  key: const Key('sticky_cart_bar'),
                  onPressed: () => context.push('/cart'),
                  child: Text(
                    'Ver carrito ($cartCount) · \$${cart.total.toStringAsFixed(2)}',
                  ),
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              key: const Key('catalog_search_field'),
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar productos o servicios…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  ref.read(catalogFiltersProvider.notifier).setSearch(value),
            ),
          ),
          _FilterBar(
            filters: filters,
            categoriesAsync: categoriesAsync,
            onTypeChanged: (type) =>
                ref.read(catalogFiltersProvider.notifier).setProductType(type),
            onCategoryChanged: (id) =>
                ref.read(catalogFiltersProvider.notifier).setCategory(id),
            onSubcategoryChanged: (id) =>
                ref.read(catalogFiltersProvider.notifier).setSubcategory(id),
            onSortChanged: (sort) =>
                ref.read(catalogFiltersProvider.notifier).setSort(sort),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (products) {
                if (products.isEmpty) {
                  return const Center(child: Text('Sin resultados'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _ProductTile(
                      product: product,
                      onTap: () {
                        if (product.isService) {
                          context.push(
                            '/stores/${widget.storeId}/catalog/services/${product.id}',
                            extra: widget.storeName,
                          );
                        } else {
                          context.push(
                            '/stores/${widget.storeId}/catalog/products/${product.id}',
                            extra: widget.storeName,
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

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        key: Key('product_tile_${product.id}'),
        leading: product.primaryImageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.primaryImageUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image),
                ),
              )
            : CircleAvatar(
                child: Icon(
                  product.isService ? Icons.home_repair_service : Icons.inventory_2,
                ),
              ),
        title: Text(product.name),
        subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
        trailing: _ProductTypeBadge(type: product.productType),
        onTap: onTap,
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
    required this.onSortChanged,
  });

  final CatalogFiltersState filters;
  final AsyncValue<List<ProductCategory>> categoriesAsync;
  final ValueChanged<ProductType?> onTypeChanged;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<int?> onSubcategoryChanged;
  final ValueChanged<ProductSort> onSortChanged;

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
                label: const Text('Físico'),
                selected: filters.productType == ProductType.physical,
                onSelected: (_) => onTypeChanged(
                  filters.productType == ProductType.physical
                      ? null
                      : ProductType.physical,
                ),
              ),
              FilterChip(
                key: const Key('filter_service'),
                label: const Text('Servicio'),
                selected: filters.productType == ProductType.service,
                onSelected: (_) => onTypeChanged(
                  filters.productType == ProductType.service
                      ? null
                      : ProductType.service,
                ),
              ),
            ],
          ),
          DropdownButton<ProductSort>(
            key: const Key('catalog_sort_dropdown'),
            isExpanded: true,
            value: filters.sort,
            items: const [
              DropdownMenuItem(
                value: ProductSort.nameAsc,
                child: Text('Orden: nombre'),
              ),
              DropdownMenuItem(
                value: ProductSort.priceAsc,
                child: Text('Precio: menor a mayor'),
              ),
              DropdownMenuItem(
                value: ProductSort.priceDesc,
                child: Text('Precio: mayor a menor'),
              ),
            ],
            onChanged: (value) {
              if (value != null) onSortChanged(value);
            },
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
    final label = type == ProductType.service ? 'Servicio' : 'Físico';
    return Chip(
      key: Key('badge_$label'),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
