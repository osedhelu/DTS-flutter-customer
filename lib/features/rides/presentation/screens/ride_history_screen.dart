import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../checkout/presentation/utils/api_error_detail.dart';
import '../../application/providers/rides_providers.dart';
import '../../domain/entities/ride.dart';
import '../../domain/entities/ride_status.dart';

/// Historial de viajes del cliente.
class RideHistoryScreen extends ConsumerWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(rideHistoryProvider);

    return Scaffold(
      key: const Key('ride_history_screen'),
      appBar: AppBar(
        title: const Text('Mis viajes'),
        actions: [
          IconButton(
            key: const Key('refresh_ride_history'),
            onPressed: () => ref.invalidate(rideHistoryProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: history.when(
        loading: () => const DtsLoading(message: 'Cargando viajes…'),
        error: (error, _) => DtsErrorView(
          message: parseApiErrorDetail(
            error,
            fallback: 'No pudimos cargar tu historial.',
          ),
          onRetry: () => ref.invalidate(rideHistoryProvider),
        ),
        data: (rides) {
          if (rides.isEmpty) {
            return const DtsEmptyState(
              icon: Icons.local_taxi_outlined,
              title: 'Sin viajes todavía',
              message: 'Cuando pidas tu primer viaje, aparecerá aquí.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(rideHistoryProvider);
              await ref.read(rideHistoryProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: rides.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) =>
                  _RideHistoryTile(ride: rides[index]),
            ),
          );
        },
      ),
    );
  }
}

class _RideHistoryTile extends StatelessWidget {
  const _RideHistoryTile({required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        key: Key('ride_history_item_${ride.id}'),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        onTap: () => context.push('/rides/${ride.id}/tracking'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Viaje #${ride.id}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  DtsStatusChip(
                    label: ride.status.label,
                    tone: _tone(ride),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _locationRow(
                context,
                icon: Icons.trip_origin,
                color: theme.colorScheme.primary,
                text: ride.pickup.address,
              ),
              const SizedBox(height: AppSpacing.xs),
              _locationRow(
                context,
                icon: Icons.place,
                color: theme.colorScheme.error,
                text: ride.dropoff.address,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(ride.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '\$${ride.total.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationRow(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String text,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text.isEmpty ? '—' : text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  static DtsChipTone _tone(Ride ride) {
    return switch (ride.status) {
      RideStatus.rideCompleted => DtsChipTone.success,
      RideStatus.cancelled => DtsChipTone.danger,
      RideStatus.unknown => DtsChipTone.neutral,
      _ => ride.isActive ? DtsChipTone.warning : DtsChipTone.neutral,
    };
  }
}
