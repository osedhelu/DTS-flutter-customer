import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../checkout/domain/entities/order.dart';

class CustomerOrdersScreen extends ConsumerStatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  ConsumerState<CustomerOrdersScreen> createState() =>
      _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends ConsumerState<CustomerOrdersScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';

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
      final orders = await ref.read(ordersRepositoryProvider).listOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los pedidos';
        _loading = false;
      });
    }
  }

  List<Order> get _filtered {
    return switch (_filter) {
      'active' => _orders.where((o) => o.isActive).toList(),
      'done' =>
        _orders.where((o) => o.status == 'delivered').toList(),
      'cancelled' =>
        _orders.where((o) => o.status == 'cancelled').toList(),
      _ => _orders,
    };
  }

  void _openOrder(Order order) {
    if (order.isService) {
      context.push('/service-tracking/${order.id}');
    } else if (order.isActive) {
      context.push('/tracking/${order.id}');
    } else {
      context.push('/orders/${order.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                for (final e in [
                  ('all', 'Todos'),
                  ('active', 'Activos'),
                  ('done', 'Entregados'),
                  ('cancelled', 'Cancelados'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(e.$2),
                      selected: _filter == e.$1,
                      onSelected: (_) => setState(() => _filter = e.$1),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const DtsLoading()
                : _error != null
                    ? DtsErrorView(message: _error!, onRetry: _load)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _filtered.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 80),
                                  DtsEmptyState(
                                    icon: Icons.receipt_long_outlined,
                                    title: 'Sin pedidos',
                                    message:
                                        'Cuando hagas un pedido, aparecerá aquí.',
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final order = _filtered[i];
                                  return Card(
                                    child: ListTile(
                                      title: Text(
                                        order.storeName.isNotEmpty
                                            ? order.storeName
                                            : 'Pedido #${order.id}',
                                      ),
                                      subtitle: Text(
                                        '${DtsStatusChip.labelForStatus(order.status)} · \$${order.total.toStringAsFixed(2)}',
                                      ),
                                      trailing: DtsStatusChip(
                                        label: DtsStatusChip.labelForStatus(
                                          order.status,
                                        ),
                                        tone: DtsStatusChip.toneForStatus(
                                          order.status,
                                        ),
                                      ),
                                      onTap: () => _openOrder(order),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}
