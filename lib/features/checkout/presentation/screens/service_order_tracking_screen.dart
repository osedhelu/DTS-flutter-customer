import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/repository_providers.dart';
import '../../domain/entities/order.dart';

const _serviceStatusLabels = {
  'PENDING': 'Pendiente',
  'ACCEPTED_BY_MERCHANT': 'Aceptado',
  'IN_PREPARATION': 'En preparación',
  'SCHEDULED': 'Programado',
  'IN_PROGRESS': 'En curso',
  'COMPLETED': 'Completado',
  'CANCELLED': 'Cancelado',
};

class ServiceOrderTrackingScreen extends ConsumerWidget {
  const ServiceOrderTrackingScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(serviceOrderProvider(orderId));

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
