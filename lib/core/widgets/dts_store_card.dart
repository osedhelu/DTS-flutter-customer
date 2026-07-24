import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'dts_network_image.dart';
import 'dts_status_chip.dart';

class DtsStoreCard extends StatelessWidget {
  const DtsStoreCard({
    super.key,
    required this.name,
    this.logoUrl,
    this.address,
    this.isOpen = true,
    this.onTap,
  });

  final String name;
  final String? logoUrl;
  final String? address;
  final bool isOpen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      child: InkWell(
        onTap: isOpen ? onTap : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                DtsNetworkImage(
                  url: logoUrl,
                  width: 72,
                  height: 72,
                  borderRadius: BorderRadius.circular(16),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((address ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          address!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      DtsStatusChip(
                        label: isOpen ? 'Abierto' : 'Cerrado',
                        tone: isOpen ? DtsChipTone.success : DtsChipTone.neutral,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isOpen
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
