import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Selector de origen y destino del viaje.
///
/// Mantiene las direcciones en [pickupController]/[dropoffController]; el padre
/// es dueño de las coordenadas (mapa o ubicación actual).
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.trip_origin,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextField(
                    key: const Key('pickup_field'),
                    controller: pickupController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Origen',
                      hintText: '¿Desde dónde salimos?',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (onUseCurrentPickup != null)
                  IconButton(
                    key: const Key('pickup_current_location'),
                    onPressed: onUseCurrentPickup,
                    icon: const Icon(Icons.my_location),
                    tooltip: 'Usar mi ubicación',
                  ),
              ],
            ),
            const Divider(height: 1),
            Row(
              children: [
                Icon(Icons.place, size: 18, color: theme.colorScheme.error),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextField(
                    key: const Key('dropoff_field'),
                    controller: dropoffController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Destino',
                      hintText: '¿A dónde vamos?',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (onUseCurrentDropoff != null)
                  IconButton(
                    key: const Key('dropoff_current_location'),
                    onPressed: onUseCurrentDropoff,
                    icon: const Icon(Icons.my_location),
                    tooltip: 'Usar mi ubicación',
                  ),
              ],
            ),
            if (onSwap != null)
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
        ),
      ),
    );
  }
}
