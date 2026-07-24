import 'package:flutter/material.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Layout compartido para login / registro / forgot: fondo theme-aware,
/// scroll y form centrado con [AppBreakpoints.authFormMaxWidth].
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.body,
    this.header,
    this.footer,
    this.appBar,
    this.padding = const EdgeInsets.fromLTRB(24, 32, 24, 24),
  });

  final Widget? header;
  final Widget body;
  final Widget? footer;
  final PreferredSizeWidget? appBar;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: appBar,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    Color.alphaBlend(
                      scheme.primary.withValues(alpha: 0.14),
                      scheme.surface,
                    ),
                    scheme.surface,
                  ]
                : [
                    AppColors.creamDeep,
                    AppColors.cream,
                  ],
            stops: const [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: padding,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.authFormMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (header != null) ...[
                      header!,
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                    body,
                    if (footer != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
