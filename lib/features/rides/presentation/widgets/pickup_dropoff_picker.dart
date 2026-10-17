import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Selector de origen y destino del viaje.
///
/// Tarjeta blanca flotante con sombra suave y campos redondeados estilizados.
/// Mantiene las direcciones en [pickupController]/[dropoffController]; el padre
/// es dueño de las coordenadas (mapa o ubicación actual).
///
/// Keys de test preservadas: `pickup_dropoff_picker`, `pickup_field`,
/// `dropoff_field`, `pickup_current_location`, `dropoff_current_location`,
/// `swap_locations`.
class PickupDropoffPicker extends StatelessWidget {
  const PickupDropoffPicker({
    super.key,
    required this.pickupController,
    required this.dropoffController,
    this.onUseCurrentPickup,
    this.onUseCurrentDropoff,
    this.onSwap,
  });

  final TextEditingController pickupController;
  final TextEditingController dropoffController;
  final VoidCallback? onUseCurrentPickup;
  final VoidCallback? onUseCurrentDropoff;
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const Key('pickup_dropoff_picker'),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            _FieldRow(
              fieldKey: const Key('pickup_field'),
              controller: pickupController,
              label: 'Origen',
              hint: '¿Desde dónde salimos?',
              icon: Icons.trip_origin,
              iconColor: AppColors.mint,
              textInputAction: TextInputAction.next,
              onUseCurrent: onUseCurrentPickup,
              currentKey: onUseCurrentPickup == null
                  ? null
                  : const Key('pickup_current_location'),
            ),
            const SizedBox(height: AppSpacing.md),
            _FieldRow(
              fieldKey: const Key('dropoff_field'),
              controller: dropoffController,
              label: 'Destino',
              hint: '¿A dónde vamos?',
              icon: Icons.flag_outlined,
              iconColor: theme.colorScheme.error,
              textInputAction: TextInputAction.done,
              onUseCurrent: onUseCurrentDropoff,
              currentKey: onUseCurrentDropoff == null
                  ? null
                  : const Key('dropoff_current_location'),
            ),
            if (onSwap != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const Key('swap_locations'),
                  onPressed: onSwap,
                  icon: const Icon(Icons.swap_vert, size: 18),
                  label: const Text('Invertir'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fila de campo con icono + input redondeado relleno, bien separados.
class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.textInputAction,
    this.onUseCurrent,
    this.currentKey,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final TextInputAction textInputAction;
  final VoidCallback? onUseCurrent;
  final Key? currentKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: TextField(
            key: fieldKey,
            controller: controller,
            textInputAction: textInputAction,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                borderSide: BorderSide(
                  color: iconColor,
                  width: 1.6,
                ),
              ),
            ),
          ),
        ),
        if (onUseCurrent != null) ...[
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            key: currentKey,
            onPressed: onUseCurrent,
            icon: const Icon(Icons.my_location, size: 22),
            tooltip: 'Usar mi ubicación',
          ),
        ],
      ],
    );
  }
}
