import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class DtsSkeleton extends StatelessWidget {
  const DtsSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.7),
        borderRadius: borderRadius ??
            BorderRadius.circular(AppSpacing.radiusInput),
      ),
    );
  }
}

class DtsStoreCardSkeleton extends StatelessWidget {
  const DtsStoreCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            DtsSkeleton(width: 72, height: 72),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DtsSkeleton(width: 140, height: 16),
                  SizedBox(height: 8),
                  DtsSkeleton(width: 100, height: 12),
                  SizedBox(height: 10),
                  DtsSkeleton(width: 64, height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
