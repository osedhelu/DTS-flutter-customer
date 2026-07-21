import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class DtsStatusChip extends StatelessWidget {
  const DtsStatusChip({super.key, required this.label, this.tone});

  final String label;
  final DtsChipTone? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = tone ?? DtsChipTone.neutral;
    final (bg, fg) = switch (resolved) {
      DtsChipTone.success => (
          AppColors.mint.withValues(alpha: 0.16),
          AppColors.mint,
        ),
      DtsChipTone.warning => (
          AppColors.amber.withValues(alpha: 0.22),
          const Color(0xFF8A5A00),
        ),
      DtsChipTone.danger => (
          theme.colorScheme.errorContainer,
          theme.colorScheme.onErrorContainer,
        ),
      DtsChipTone.neutral => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static DtsChipTone toneForStatus(String status) {
    return switch (status) {
      'delivered' || 'completed' => DtsChipTone.success,
      'cancelled' || 'rejected' => DtsChipTone.danger,
      'searching_driver' || 'ready_for_pickup' || 'pending' =>
        DtsChipTone.warning,
      _ => DtsChipTone.neutral,
    };
  }

  static String labelForStatus(String status) {
    return switch (status.toLowerCase()) {
      'pending' || 'created' => 'Pendiente',
      'accepted_by_merchant' => 'Aceptado',
      'in_preparation' => 'En preparación',
      'ready_for_pickup' => 'Listo para recoger',
      'searching_driver' => 'Buscando conductor',
      'driver_assigned' => 'Conductor asignado',
      'picked_up' => 'Recogido',
      'on_the_way' => 'En camino',
      'delivered' => 'Entregado',
      'completed' => 'Completado',
      'cancelled' => 'Cancelado',
      'rejected' => 'Rechazado',
      'scheduled' => 'Agendado',
      'provider_en_route' => 'En camino',
      'in_progress' => 'En curso',
      _ => status,
    };
  }
}

enum DtsChipTone { success, warning, danger, neutral }
