import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/ride_status.dart';

/// Tarjeta con el estado actual del viaje, ETA y resumen de la ruta.
///
/// Organizada en dos secciones claras:
///   a) Estado actual + ETA (con animación de pulso mientras se busca
///      conductor, p. ej. "Buscando conductor cercano… ~2 min").
///   b) Resumen del viaje: origen → destino, distancia y total con tipografía
///      destacada.
///
/// Keys de test preservadas: `ride_status_label`, `ride_eta`.
class RideStatusCard extends StatefulWidget {
  const RideStatusCard({
    super.key,
    required this.status,
    this.etaMinutes,
    this.driverName,
    this.driverPhone,
    this.onCallDriver,
    this.pickupAddress,
    this.dropoffAddress,
    this.distanceKm,
    this.total,
  });

  final RideStatus status;
  final int? etaMinutes;
  final String? driverName;
  final String? driverPhone;
  final VoidCallback? onCallDriver;
  final String? pickupAddress;
  final String? dropoffAddress;
  final double? distanceKm;
  final double? total;

  /// Estados que mantienen la animación de búsqueda activa.
  bool get isSearching =>
      status == RideStatus.created || status == RideStatus.searchingDriver;

  @override
  State<RideStatusCard> createState() => _RideStatusCardState();
}

class _RideStatusCardState extends State<RideStatusCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);
    _syncPulse();
  }

  @override
  void didUpdateWidget(RideStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    if (widget.isSearching) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = widget.status;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusIndicator(
                  isSearching: widget.isSearching,
                  icon: _icon(status),
                  color: _statusColor(theme, status),
                  animation: _pulseAnim,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              status.label,
                              key: const Key('ride_status_label'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          DtsStatusChip(
                            label: _toneLabel(status),
                            tone: _tone(status),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (widget.isSearching)
                        _SearchCaption(
                          etaMinutes: widget.etaMinutes,
                          pulse: _pulseAnim,
                        )
                      else if (widget.etaMinutes != null)
                        Text(
                          'Llega en ~${widget.etaMinutes} min',
                          key: const Key('ride_eta'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if ((widget.driverName ?? '').isNotEmpty) ...[
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
                          widget.driverName!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if ((widget.driverPhone ?? '').isNotEmpty)
                          Text(
                            widget.driverPhone!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.onCallDriver != null)
                    IconButton.filledTonal(
                      onPressed: widget.onCallDriver,
                      icon: const Icon(Icons.call),
                      tooltip: 'Llamar conductor',
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.lg),
            _TripSummary(
              pickupAddress: widget.pickupAddress,
              dropoffAddress: widget.dropoffAddress,
              distanceKm: widget.distanceKm,
              total: widget.total,
            ),
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

  static Color _statusColor(ThemeData theme, RideStatus status) =>
      switch (status) {
        RideStatus.rideCompleted => AppColors.mint,
        RideStatus.cancelled => theme.colorScheme.error,
        RideStatus.searchingDriver || RideStatus.created => AppColors.amber,
        _ => theme.colorScheme.primary,
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

/// Indicador circular: halo expandiéndose (pulso) mientras se busca conductor.
class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({
    required this.isSearching,
    required this.icon,
    required this.color,
    required this.animation,
  });

  final bool isSearching;
  final IconData icon;
  final Color color;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final base = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, size: 24, color: color),
    );

    if (!isSearching) return base;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        // Halo de búsqueda que se expande y difumina en loop.
        return SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 34 + 18 * t,
                height: 34 + 18 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: (1 - t) * 0.35),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Subtítulo de búsqueda: "Buscando conductor cercano… ~2 min" con ETA.
class _SearchCaption extends StatelessWidget {
  const _SearchCaption({required this.etaMinutes, required this.pulse});

  final int? etaMinutes;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final etaText = etaMinutes != null ? ' ~$etaMinutes min' : '';
    return Row(
      children: [
        AnimatedBuilder(
          animation: pulse,
          builder: (context, child) => Opacity(
            opacity: 0.45 + 0.55 * pulse.value,
            child: child,
          ),
          child: Icon(
            Icons.radar,
            size: 15,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            'Buscando conductor cercano…$etaText',
            key: const Key('ride_search_caption'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Resumen del viaje: origen → destino, distancia y total destacado.
class _TripSummary extends StatelessWidget {
  const _TripSummary({
    this.pickupAddress,
    this.dropoffAddress,
    this.distanceKm,
    this.total,
  });

  final String? pickupAddress;
  final String? dropoffAddress;
  final double? distanceKm;
  final double? total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summaryRows = <Widget>[
      _summaryRoute(
        context,
        icon: Icons.trip_origin,
        color: AppColors.mint,
        label: 'Origen',
        text: pickupAddress ?? '',
      ),
      const SizedBox(height: AppSpacing.sm),
      _summaryRoute(
        context,
        icon: Icons.flag_outlined,
        color: theme.colorScheme.error,
        label: 'Destino',
        text: dropoffAddress ?? '',
      ),
    ];

    if (distanceKm != null) {
      summaryRows.addAll([
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Icon(
              Icons.route_outlined,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${distanceKm!.toStringAsFixed(1)} km aproximados',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...summaryRows,
        if (total != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Total a pagar',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '\$${total!.toStringAsFixed(2)}',
                  key: const Key('ride_total'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _summaryRoute(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String text,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                text.isEmpty ? 'Sin dirección' : text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
