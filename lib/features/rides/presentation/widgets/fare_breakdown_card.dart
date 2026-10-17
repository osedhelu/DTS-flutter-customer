import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/fare_quote.dart';

/// Tarjeta con el desglose de la tarifa cotizada antes de confirmar el viaje.
class FareBreakdownCard extends StatelessWidget {
  const FareBreakdownCard({
    super.key,
    required this.breakdown,
    this.distanceKm,
    this.durationMinutes,
    this.zoneName,
  });

  final FareBreakdown breakdown;
  final double? distanceKm;
  final int? durationMinutes;
  final String? zoneName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DtsSectionCard(
      title: 'Tu viaje',
      subtitle: _subtitle(),
      child: Column(
        key: const Key('fare_breakdown_card'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row(context, 'Tarifa base', breakdown.base),
          _row(context, 'Distancia', breakdown.distance),
          _row(context, 'Tiempo', breakdown.time),
          if (breakdown.hasSurge)
            _row(
              context,
              'Alta demanda (x${breakdown.surgeMultiplier.toStringAsFixed(2)})',
              breakdown.surge,
            ),
          const Divider(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _money(breakdown.total),
                key: const Key('fare_total'),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _subtitle() {
    final parts = <String>[];
    if (distanceKm != null) parts.add('${distanceKm!.toStringAsFixed(1)} km');
    if (durationMinutes != null) parts.add('~$durationMinutes min');
    if ((zoneName ?? '').isNotEmpty) parts.add(zoneName!);
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Widget _row(BuildContext context, String label, double amount) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(_money(amount), style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  static String _money(double value) => '\$${value.toStringAsFixed(2)}';
}
