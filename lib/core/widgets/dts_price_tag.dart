import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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
    return Text(
      '\$${amount.toStringAsFixed(2)}',
      style: (emphasized
              ? theme.textTheme.headlineSmall
              : theme.textTheme.titleMedium)
          ?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
    );
  }
}
