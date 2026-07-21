import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../checkout/domain/entities/order.dart';

class CustomerOrderDetailScreen extends ConsumerStatefulWidget {
  const CustomerOrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<CustomerOrderDetailScreen> createState() =>
      _CustomerOrderDetailScreenState();
}

class _CustomerOrderDetailScreenState
    extends ConsumerState<CustomerOrderDetailScreen> {
  Order? _order;
  bool _loading = true;
  String? _error;
  bool _busy = false;

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
      final order =
          await ref.read(ordersRepositoryProvider).getOrder(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Pedido no encontrado';
        _loading = false;
      });
    }
  }

  Future<void> _cancel() async {
    setState(() => _busy = true);
    try {
      await ref.read(ordersRepositoryProvider).cancelOrder(widget.orderId);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cancelar')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${widget.orderId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.push('/orders/${widget.orderId}/chat'),
          ),
        ],
      ),
      body: _loading
          ? const DtsLoading()
          : _error != null || order == null
              ? DtsErrorView(message: _error ?? 'Error', onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    DtsStatusChip(
                      label: DtsStatusChip.labelForStatus(order.status),
                      tone: DtsStatusChip.toneForStatus(order.status),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      order.storeName.isNotEmpty
                          ? order.storeName
                          : 'Comercio #${order.storeId}',
                      style: theme.textTheme.headlineSmall,
                    ),
                    Text('Total: \$${order.total.toStringAsFixed(2)}'),
                    if (order.addressLabel.isNotEmpty)
                      Text('Dirección: ${order.addressLabel}'),
                    if (order.customerNotes?.isNotEmpty == true)
                      Text('Notas: ${order.customerNotes}'),
                    if (order.driverName?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Text('Conductor: ${order.driverName}'),
                    ],
                    const SizedBox(height: 24),
                    if (order.isActive && !order.isService)
                      DtsPrimaryButton(
                        label: 'Ver en mapa',
                        onPressed: () =>
                            context.push('/tracking/${order.id}'),
                      ),
                    if (order.isActive && order.isService)
                      DtsPrimaryButton(
                        label: 'Ver seguimiento',
                        onPressed: () => context
                            .push('/service-tracking/${order.id}'),
                      ),
                    if (order.driverPhone?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => launchUrl(
                          Uri.parse('tel:${order.driverPhone}'),
                        ),
                        icon: const Icon(Icons.phone),
                        label: const Text('Llamar conductor'),
                      ),
                    ],
                    if (order.status == 'delivered' || order.status == 'cancelled') ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => context.push('/stores/${order.storeId}'),
                        child: const Text('Pedir de nuevo'),
                      ),
                    ],
                    if (order.isActive) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _busy ? null : _cancel,
                        child: const Text('Cancelar pedido'),
                      ),
                    ],
                  ],
                ),
    );
  }
}
