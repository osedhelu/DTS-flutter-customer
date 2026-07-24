import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/widgets.dart';
import '../../../cart/application/providers/cart_providers.dart';
import '../../../shell/presentation/screens/customer_shell_screen.dart';
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
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              onPressed: () => goToCart(context),
            ),
        ],
      ),
      bottomNavigationBar: showStickyCart
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  key: const Key('sticky_cart_bar'),
                  onPressed: () => goToCart(context),
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
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) =>
                  ref.read(catalogFiltersProvider.notifier).setSearch(value),
            ),
          ),
          _FilterChipsBar(
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
              loading: () => GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemCount: 6,
                itemBuilder: (_, __) => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Expanded(child: DtsSkeleton(height: double.infinity)),
                        SizedBox(height: 10),
                        DtsSkeleton(height: 14),
                        SizedBox(height: 8),
                        DtsSkeleton(width: 64, height: 14),
                      ],
                    ),
                  ),
                ),
              ),
              error: (error, _) => DtsErrorView(
                message: 'No se pudo cargar el catálogo',
                onRetry: () => ref.invalidate(productsProvider(widget.storeId)),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return const DtsEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Sin resultados',
                    message: 'Prueba otro filtro o búsqueda.',
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return DtsProductCard(
                      key: Key('product_tile_${product.id}'),
                      name: product.name,
                      price: product.price,
                      imageUrl: product.primaryImageUrl,
                      badge: product.isService
                          ? 'Servicio'
                          : product.promotionBadge,
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
                      onAdd: product.isService
                          ? null
                          : () {
                              ref.read(cartNotifierProvider.notifier).addProduct(
                                    storeId: widget.storeId,
                                    storeName: widget.storeName ?? 'Comercio',
                                    product: product,
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${product.name} agregado'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
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

class _FilterChipsBar extends StatelessWidget {
  const _FilterChipsBar({
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

  Future<void> _openFiltersSheet(BuildContext context) async {
    final categories = categoriesAsync.valueOrNull ?? const <ProductCategory>[];
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20 + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filtros',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text('Ordenar', style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in [
                    (ProductSort.nameAsc, 'Nombre'),
                    (ProductSort.priceAsc, 'Precio ↑'),
                    (ProductSort.priceDesc, 'Precio ↓'),
                  ])
                    ChoiceChip(
                      key: e.$1 == ProductSort.nameAsc
                          ? const Key('catalog_sort_dropdown')
                          : null,
                      label: Text(e.$2),
                      selected: filters.sort == e.$1,
                      onSelected: (_) {
                        onSortChanged(e.$1);
                        Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Categoría', style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      key: const Key('category_dropdown'),
                      label: const Text('Todas'),
                      selected: filters.categoryId == null,
                      onSelected: (_) {
                        onCategoryChanged(null);
                        Navigator.pop(ctx);
                      },
                    ),
                    ...categories.map(
                      (c) => ChoiceChip(
                        label: Text(c.name),
                        selected: filters.categoryId == c.id,
                        onSelected: (_) {
                          onCategoryChanged(c.id);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
              ],
              Builder(
                builder: (_) {
                  ProductCategory? selected;
                  for (final c in categories) {
                    if (c.id == filters.categoryId) {
                      selected = c;
                      break;
                    }
                  }
                  if (selected == null || selected.subcategories.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Subcategoría',
                        style: Theme.of(ctx).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            key: const Key('subcategory_dropdown'),
                            label: const Text('Todas'),
                            selected: filters.subcategoryId == null,
                            onSelected: (_) {
                              onSubcategoryChanged(null);
                              Navigator.pop(ctx);
                            },
                          ),
                          ...selected.subcategories.map(
                            (s) => ChoiceChip(
                              label: Text(s.name),
                              selected: filters.subcategoryId == s.id,
                              onSelected: (_) {
                                onSubcategoryChanged(s.id);
                                Navigator.pop(ctx);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
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
            const SizedBox(width: 8),
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
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Más filtros'),
              onPressed: () => _openFiltersSheet(context),
            ),
            if (filters.categoryId != null ||
                filters.sort != ProductSort.nameAsc) ...[
              const SizedBox(width: 8),
              InputChip(
                label: Text(
                  filters.sort == ProductSort.priceAsc
                      ? 'Precio ↑'
                      : filters.sort == ProductSort.priceDesc
                          ? 'Precio ↓'
                          : 'Filtros',
                ),
                onDeleted: () {
                  onSortChanged(ProductSort.nameAsc);
                  onCategoryChanged(null);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
