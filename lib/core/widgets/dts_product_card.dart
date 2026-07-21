import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'dts_network_image.dart';
import 'dts_price_tag.dart';

class DtsProductCard extends StatefulWidget {
  const DtsProductCard({
    super.key,
    required this.name,
    required this.price,
    this.imageUrl,
    this.badge,
    this.onTap,
    this.onAdd,
  });

  final String name;
  final double price;
  final String? imageUrl;
  final String? badge;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  @override
  State<DtsProductCard> createState() => _DtsProductCardState();
}

class _DtsProductCardState extends State<DtsProductCard> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _scale = 0.97),
          onTapCancel: () => setState(() => _scale = 1),
          onTapUp: (_) => setState(() => _scale = 1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DtsNetworkImage(
                        url: widget.imageUrl,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppSpacing.radiusCard),
                        ),
                      ),
                      if ((widget.badge ?? '').isNotEmpty)
                        Positioned(
                          left: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.amber,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusChip,
                              ),
                            ),
                            child: Text(
                              widget.badge!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: DtsPriceTag(amount: widget.price)),
                          if (widget.onAdd != null)
                            Material(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: widget.onAdd,
                                borderRadius: BorderRadius.circular(12),
                                child: const SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
