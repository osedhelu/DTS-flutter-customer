import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class DtsQtyStepper extends StatelessWidget {
  const DtsQtyStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.min = 0,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final int min;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: quantity > min ? () => onChanged(quantity - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$quantity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(quantity + 1),
            icon: Icon(Icons.add_rounded, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
