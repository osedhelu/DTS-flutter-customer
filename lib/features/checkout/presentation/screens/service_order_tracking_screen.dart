import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/repository_providers.dart';
import '../../domain/entities/order.dart';

const _serviceStatusLabels = {
  'PENDING': 'Pendiente',
  'created': 'Pendiente',
  'ACCEPTED_BY_MERCHANT': 'Aceptado',
  'accepted_by_merchant': 'Aceptado',
  'IN_PREPARATION': 'En preparación',
  'SCHEDULED': 'Programado',
  'scheduled': 'Programado',
  'PROVIDER_EN_ROUTE': 'Proveedor en camino',
  'provider_en_route': 'Proveedor en camino',
  'IN_PROGRESS': 'En curso',
  'in_progress': 'En curso',
  'COMPLETED': 'Completado',
  'completed': 'Completado',
  'CANCELLED': 'Cancelado',
  'cancelled': 'Cancelado',
};

class ServiceOrderTrackingScreen extends ConsumerStatefulWidget {
  const ServiceOrderTrackingScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<ServiceOrderTrackingScreen> createState() =>
      _ServiceOrderTrackingScreenState();
}

class _ServiceOrderTrackingScreenState
    extends ConsumerState<ServiceOrderTrackingScreen> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 8), (_) {
      ref.invalidate(serviceOrderProvider(widget.orderId));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(serviceOrderProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Seguimiento servicio')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (order) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pedido #${order.id}', key: const Key('service_order_id')),
              const SizedBox(height: 8),
              Text(
                _serviceStatusLabels[order.status] ?? order.status,
                key: const Key('service_order_status'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (order.serviceAddress != null) ...[
                const SizedBox(height: 8),
                Text('Dirección: ${order.serviceAddress}'),
              ],
              if (order.scheduledAt != null) ...[
                const SizedBox(height: 8),
                Text('Programado: ${order.scheduledAt!.toLocal()}'),
              ],
              if (order.durationMinutes != null) ...[
                const SizedBox(height: 8),
                Text('Duración estimada: ${order.durationMinutes} min'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final serviceOrderProvider = FutureProvider.family<Order, int>((ref, orderId) {
  return ref.watch(ordersRepositoryProvider).getOrder(orderId);
});
