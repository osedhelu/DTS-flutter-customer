import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../profile/domain/entities/customer_profile.dart';
import '../../application/providers/featured_products_provider.dart';

class StoreListScreen extends ConsumerStatefulWidget {
  const StoreListScreen({super.key});

  @override
  ConsumerState<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends ConsumerState<StoreListScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _banners = [];
  _HomeStoreFilter _storeFilter = _HomeStoreFilter.all;
  String? _greetingName;
  String? _shortAddress;

  @override
  void initState() {
    super.initState();
    _loadBanners();
    _loadProfileSnippet();
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

  Future<void> _loadProfileSnippet() async {
    try {
      final ds = ref.read(customerProfileRemoteDataSourceProvider);
      final profile = await ds.getProfile();
      var addressText = profile.defaultAddress.trim();
      if (addressText.isEmpty) {
        try {
          final addresses = await ds.listAddresses();
          CustomerAddress? preferred;
          for (final a in addresses) {
            if (a.isDefault) {
              preferred = a;
              break;
            }
          }
          preferred ??= addresses.isNotEmpty ? addresses.first : null;
          addressText = preferred?.address.trim() ?? '';
        } catch (_) {}
      }
      if (!mounted) return;
      final name = profile.fullName.trim();
      final first = name.isEmpty ? null : name.split(' ').first;
      setState(() {
        _greetingName = first;
        _shortAddress = addressText.isEmpty ? null : addressText;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(storesListProvider);
    final featuredAsync = ref.watch(featuredProductsProvider);
    final query = _search.text.trim().toLowerCase();
    final theme = Theme.of(context);
    final greeting = _greetingName == null
        ? '¿Qué se te antoja?'
        : 'Hola, $_greetingName';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DtsBrandMark(size: 32),
            const SizedBox(height: 2),
            Text(
              greeting,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
        toolbarHeight: 72,
        actions: [
          if ((_shortAddress ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          _shortAddress!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: storesAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            DtsSkeleton(height: 48),
            SizedBox(height: AppSpacing.md),
            DtsSkeleton(height: 140),
            SizedBox(height: AppSpacing.lg),
            DtsStoreCardSkeleton(),
            SizedBox(height: AppSpacing.md),
            DtsStoreCardSkeleton(),
          ],
        ),
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
                        (s.address?.toLowerCase().contains(query) ?? false),
                  )
                  .toList();
          filtered = switch (_storeFilter) {
            _HomeStoreFilter.all => filtered,
            _HomeStoreFilter.services =>
              filtered.where((s) => s.isServicesVertical).toList(),
            _HomeStoreFilter.products =>
              filtered.where((s) => !s.isServicesVertical).toList(),
          };

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(storesListProvider);
              ref.invalidate(featuredProductsProvider);
              await _loadBanners();
              await _loadProfileSnippet();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Buscar comercios…',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final e in [
                            (_HomeStoreFilter.all, 'Todos', 'home_filter_all'),
                            (
                              _HomeStoreFilter.products,
                              'Productos',
                              'home_filter_products'
                            ),
                            (
                              _HomeStoreFilter.services,
                              'Servicios',
                              'home_filter_services'
                            ),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                key: Key(e.$3),
                                label: Text(e.$2),
                                selected: _storeFilter == e.$1,
                                onSelected: (_) =>
                                    setState(() => _storeFilter = e.$1),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_banners.isNotEmpty)
                  const SliverToBoxAdapter(child: SizedBox(height: 4)),
                if (_banners.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 148,
                      child: PageView.builder(
                        controller: PageController(viewportFraction: 0.92),
                        itemCount: _banners.length,
                        itemBuilder: (context, i) {
                          final b = _banners[i];
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: _BannerCard(banner: b),
                          );
                        },
                      ),
                    ),
                  ),
                featuredAsync.when(
                  data: (featured) {
                    if (featured.isEmpty) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 12 * (1 - value)),
                              child: child,
                            ),
                          ),
                          child: DtsHorizontalRail(
                            title: 'Más vendidos',
                            subtitle: 'Lo que más piden hoy',
                            height: 232,
                            children: [
                              for (final item in featured)
                                DtsProductCard(
                                  name: item.product.name,
                                  price: item.product.price,
                                  imageUrl: item.product.primaryImageUrl,
                                  badge: item.product.promotionBadge ?? 'Top',
                                  onTap: () {
                                    final p = item.product;
                                    final path = p.isService
                                        ? '/stores/${p.storeId}/catalog/services/${p.id}'
                                        : '/stores/${p.storeId}/catalog/products/${p.id}';
                                    context.push(path, extra: item.storeName);
                                  },
                                  onAdd: item.product.isService
                                      ? null
                                      : () {
                                          ref
                                              .read(
                                                cartNotifierProvider.notifier,
                                              )
                                              .addProduct(
                                                storeId: item.product.storeId,
                                                storeName: item.storeName,
                                                product: item.product,
                                              );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Agregado al carrito',
                                              ),
                                            ),
                                          );
                                        },
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
                      child: DtsSkeleton(height: 180),
                    ),
                  ),
                  error: (_, __) =>
                      const SliverToBoxAdapter(child: SizedBox.shrink()),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: DtsSectionHeader(
                      title: 'Comercios cerca',
                      subtitle: filtered.isEmpty
                          ? null
                          : '${filtered.length} disponibles',
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: DtsEmptyState(
                      icon: Icons.storefront_outlined,
                      title: 'Sin comercios',
                      message: 'No hay comercios disponibles ahora.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final store = filtered[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 280 + (index * 40).clamp(0, 200)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 10 * (1 - value)),
                              child: child,
                            ),
                          ),
                          child: KeyedSubtree(
                            key: Key('store_tile_${store.id}'),
                            child: DtsStoreCard(
                              name: store.name,
                              logoUrl: store.logoUrl,
                              address: store.address,
                              isOpen: store.isOpen,
                              onTap: () =>
                                  context.push('/stores/${store.id}'),
                            ),
                          ),
                        );
                      },
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

enum _HomeStoreFilter { all, products, services }

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});

  final Map<String, dynamic> banner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = '${banner['title'] ?? banner['name'] ?? 'Promo'}';
    final imageUrl = (banner['image_url'] ?? banner['image'] ?? '').toString();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            DtsNetworkImage(url: imageUrl)
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.coral, AppColors.amber],
                ),
              ),
            ),
          if (imageUrl.isNotEmpty)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x99000000)],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
