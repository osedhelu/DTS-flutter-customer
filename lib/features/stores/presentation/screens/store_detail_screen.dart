import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/widgets/widgets.dart';

class StoreDetailScreen extends ConsumerStatefulWidget {
  const StoreDetailScreen({super.key, required this.storeId});

  final int storeId;

  @override
  ConsumerState<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends ConsumerState<StoreDetailScreen> {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get<Map<String, dynamic>>(
        '/stores/${widget.storeId}/public/',
      );
      if (!mounted) return;
      setState(() {
        _detail = res.data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar la tienda';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = _detail;

    return Scaffold(
      appBar: AppBar(title: Text(detail?['name']?.toString() ?? 'Tienda')),
      body: _loading
          ? const DtsLoading()
          : _error != null
              ? DtsErrorView(message: _error!, onRetry: _load)
              : detail == null
                  ? const DtsEmptyState(
                      icon: Icons.storefront_outlined,
                      title: 'Tienda no encontrada',
                      message: 'Intenta más tarde.',
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DtsNetworkImage(
                            url: detail['logo_url']?.toString(),
                            height: 160,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            detail['name']?.toString() ?? '',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if ((detail['description']?.toString() ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(detail['description'].toString()),
                            ),
                          const SizedBox(height: 12),
                          DtsStatusChip(
                            label: detail['is_open'] == true ? 'Abierto' : 'Cerrado',
                            tone: detail['is_open'] == true
                                ? DtsChipTone.success
                                : DtsChipTone.neutral,
                          ),
                          if (detail['accepts_orders'] != true) ...[
                            const SizedBox(height: 8),
                            Text(
                              'No acepta pedidos en este momento',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (detail['latitude'] != null &&
                              detail['longitude'] != null)
                            SizedBox(
                              height: 160,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(
                                      (detail['latitude'] as num).toDouble(),
                                      (detail['longitude'] as num).toDouble(),
                                    ),
                                    zoom: 14,
                                  ),
                                  markers: {
                                    Marker(
                                      markerId: const MarkerId('store'),
                                      position: LatLng(
                                        (detail['latitude'] as num).toDouble(),
                                        (detail['longitude'] as num).toDouble(),
                                      ),
                                    ),
                                  },
                                  zoomControlsEnabled: false,
                                  myLocationButtonEnabled: false,
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          DtsPrimaryButton(
                            label: 'Ver catálogo',
                            onPressed: detail['accepts_orders'] == true
                                ? () => context.push(
                                      '/stores/${widget.storeId}/catalog?name=${Uri.encodeComponent(detail['name']?.toString() ?? '')}',
                                    )
                                : null,
                          ),
                        ],
                      ),
                    ),
    );
  }
}
