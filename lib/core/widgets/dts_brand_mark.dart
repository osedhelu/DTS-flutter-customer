import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Wordmark DTS para AppBars / auth.
class DtsBrandMark extends StatelessWidget {
  const DtsBrandMark({super.key, this.size = 40, this.showWordmark = true});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.coral, AppColors.coralDark],
            ),
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          alignment: Alignment.center,
          child: Text(
            'D',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.48,
              height: 1,
            ),
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 10),
          Text(
            'DTS',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}
