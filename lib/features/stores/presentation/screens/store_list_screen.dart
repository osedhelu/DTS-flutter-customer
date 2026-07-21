import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/providers/stores_providers.dart';
import '../../domain/entities/store.dart';

class StoreListScreen extends ConsumerStatefulWidget {
  const StoreListScreen({super.key});

  @override
  ConsumerState<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends ConsumerState<StoreListScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _banners = [];
  _HomeStoreFilter _storeFilter = _HomeStoreFilter.all;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    try {
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get('/marketing/banners/active/');
      final data = res.data;
      final list = data is List
          ? data
          : (data is Map ? data['results'] as List? ?? [] : <dynamic>[]);
      if (!mounted) return;
      setState(() {
        _banners = list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(storesListProvider);
    final query = _search.text.trim().toLowerCase();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DTS Delivery'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: ref.watch(cartItemCountProvider) > 0,
              label: Text('${ref.watch(cartItemCountProvider)}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () => context.push('/cart'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Buscar comercios…',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  key: const Key('home_filter_all'),
                  label: const Text('Todos'),
                  selected: _storeFilter == _HomeStoreFilter.all,
                  onSelected: (_) => setState(() => _storeFilter = _HomeStoreFilter.all),
                ),
                FilterChip(
                  key: const Key('home_filter_products'),
                  label: const Text('Productos'),
                  selected: _storeFilter == _HomeStoreFilter.products,
                  onSelected: (_) =>
                      setState(() => _storeFilter = _HomeStoreFilter.products),
                ),
                FilterChip(
                  key: const Key('home_filter_services'),
                  label: const Text('Servicios'),
                  selected: _storeFilter == _HomeStoreFilter.services,
                  onSelected: (_) =>
                      setState(() => _storeFilter = _HomeStoreFilter.services),
                ),
              ],
            ),
          ),
          if (_banners.isNotEmpty)
            SizedBox(
              height: 110,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _banners.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final b = _banners[i];
                  final title = '${b['title'] ?? b['name'] ?? 'Promo'}';
                  return Container(
                    width: 220,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.seed,
                          AppTheme.seed.withValues(alpha: 0.75),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          Expanded(
            child: storesAsync.when(
              loading: () => const DtsLoading(),
              error: (error, _) => DtsErrorView(
                message: 'No se pudieron cargar los comercios',
                onRetry: () => ref.invalidate(storesListProvider),
              ),
              data: (stores) {
                var filtered = query.isEmpty
                    ? stores
                    : stores
                        .where(
                          (s) =>
                              s.name.toLowerCase().contains(query) ||
                              (s.address?.toLowerCase().contains(query) ??
                                  false),
                        )
                        .toList();
                filtered = switch (_storeFilter) {
                  _HomeStoreFilter.all => filtered,
                  _HomeStoreFilter.services => filtered
                      .where((s) => s.isServicesVertical)
                      .toList(),
                  _HomeStoreFilter.products => filtered
                      .where((s) => !s.isServicesVertical)
                      .toList(),
                };
                if (filtered.isEmpty) {
                  return DtsEmptyState(
                    icon: Icons.storefront_outlined,
                    title: 'Sin comercios',
                    message: query.isEmpty
                        ? 'No hay comercios disponibles ahora.'
                        : 'Ningún resultado para “$query”.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(storesListProvider);
                    await _loadBanners();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final store = filtered[index];
                      return _StoreCard(store: store);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _HomeStoreFilter { all, products, services }

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: Key('store_tile_${store.id}'),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: store.isOpen
            ? () => context.push('/stores/${store.id}')
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: store.logoUrl != null && store.logoUrl!.isNotEmpty
                    ? DtsNetworkImage(
                        url: store.logoUrl,
                        width: 64,
                        height: 64,
                        borderRadius: BorderRadius.circular(12),
                      )
                    : _placeholder(theme),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (store.address != null)
                      Text(
                        store.address!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    const SizedBox(height: 6),
                    DtsStatusChip(
                      label: store.isOpen ? 'Abierto' : 'Cerrado',
                      tone: store.isOpen
                          ? DtsChipTone.success
                          : DtsChipTone.neutral,
                    ),
                  ],
                ),
              ),
              if (store.isOpen) const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      width: 64,
      height: 64,
      color: theme.colorScheme.secondaryContainer,
      child: Icon(
        Icons.store,
        color: theme.colorScheme.onSecondaryContainer,
      ),
    );
  }
}
