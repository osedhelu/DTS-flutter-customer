import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/ride_status.dart';

/// Tarjeta con el estado actual del viaje y datos del conductor/ETA.
class RideStatusCard extends StatelessWidget {
  const RideStatusCard({
    super.key,
    required this.status,
    this.etaMinutes,
    this.driverName,
    this.driverPhone,
    this.onCallDriver,
  });

  final RideStatus status;
  final int? etaMinutes;
  final String? driverName;
  final String? driverPhone;
  final VoidCallback? onCallDriver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icon(status), color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    status.label,
                    key: const Key('ride_status_label'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DtsStatusChip(label: _toneLabel(status), tone: _tone(status)),
              ],
            ),
            if (etaMinutes != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Llega en ~$etaMinutes min',
                key: const Key('ride_eta'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if ((driverName ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 20,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if ((driverPhone ?? '').isNotEmpty)
                          Text(
                            driverPhone!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (onCallDriver != null)
                    IconButton.filledTonal(
                      onPressed: onCallDriver,
                      icon: const Icon(Icons.call),
                      tooltip: 'Llamar conductor',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static IconData _icon(RideStatus status) => switch (status) {
        RideStatus.created || RideStatus.searchingDriver => Icons.search,
        RideStatus.driverAccepted ||
        RideStatus.driverEnRouteToPickup =>
          Icons.directions_car,
        RideStatus.driverAtPickup => Icons.location_on,
        RideStatus.rideInProgress => Icons.navigation,
        RideStatus.rideCompleted => Icons.check_circle,
        RideStatus.cancelled => Icons.cancel,
        RideStatus.unknown => Icons.help_outline,
      };

  static DtsChipTone _tone(RideStatus status) => switch (status) {
        RideStatus.rideCompleted => DtsChipTone.success,
        RideStatus.cancelled => DtsChipTone.danger,
        RideStatus.searchingDriver ||
        RideStatus.driverAtPickup =>
          DtsChipTone.warning,
        _ => DtsChipTone.neutral,
      };

  static String _toneLabel(RideStatus status) => switch (status) {
        RideStatus.searchingDriver => 'Buscando',
        RideStatus.driverAccepted => 'Asignado',
        RideStatus.driverEnRouteToPickup => 'En camino',
        RideStatus.driverAtPickup => 'En el punto',
        RideStatus.rideInProgress => 'En viaje',
        RideStatus.rideCompleted => 'Completado',
        RideStatus.cancelled => 'Cancelado',
        _ => 'Pendiente',
      };
}
