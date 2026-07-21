import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'dts_section_header.dart';

class DtsHorizontalRail extends StatelessWidget {
  const DtsHorizontalRail({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.height = 220,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: padding,
          child: DtsSectionHeader(title: title, subtitle: subtitle),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: height,
          child: ListView.separated(
            padding: padding,
            scrollDirection: Axis.horizontal,
            itemCount: children.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) => SizedBox(
              width: 156,
              child: children[index],
            ),
          ),
        ),
      ],
    );
  }
}
