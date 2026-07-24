import 'package:flutter/material.dart';

class DtsPriceTag extends StatelessWidget {
  const DtsPriceTag({
    super.key,
    required this.amount,
    this.emphasized = false,
  });

  final double amount;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Text(
      '\$${amount.toStringAsFixed(2)}',
      style: (emphasized
              ? theme.textTheme.headlineSmall
              : theme.textTheme.titleMedium)
          ?.copyWith(
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
    );
  }
}
