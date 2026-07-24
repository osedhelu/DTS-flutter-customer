import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Tema Material 3 — Fresh Appetite (coral + cream + Manrope).
abstract final class AppTheme {
  static const Color seed = AppColors.coral;
  static const Color accent = AppColors.amber;
  static const Color surface = AppColors.cream;
  static const String fontFamily = 'Manrope';

  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final baseScheme = ColorScheme.fromSeed(
      seedColor: AppColors.coral,
      brightness: brightness,
    );
    final colorScheme = baseScheme.copyWith(
      primary: isDark ? const Color(0xFFFF6B52) : AppColors.coral,
      onPrimary: Colors.white,
      primaryContainer: isDark
          ? AppColors.coral.withValues(alpha: 0.28)
          : AppColors.creamDeep,
      onPrimaryContainer: isDark ? Colors.white : AppColors.ink,
      secondary: isDark ? const Color(0xFFFFC14D) : AppColors.amber,
      onSecondary: isDark ? const Color(0xFF2A1C00) : AppColors.ink,
      secondaryContainer:
          AppColors.amber.withValues(alpha: isDark ? 0.22 : 0.22),
      onSecondaryContainer:
          isDark ? const Color(0xFFFFE2A8) : const Color(0xFF3D2900),
      tertiary: AppColors.mint,
      onTertiary: Colors.white,
      error: AppColors.danger,
      surface: isDark ? const Color(0xFF141210) : AppColors.cream,
      surfaceContainerHighest:
          isDark ? const Color(0xFF24201C) : AppColors.paper,
      surfaceContainerHigh:
          isDark ? const Color(0xFF1E1A17) : AppColors.paper,
      surfaceContainer:
          isDark ? const Color(0xFF1A1714) : AppColors.paper,
      onSurface: isDark ? const Color(0xFFF7F1EC) : AppColors.ink,
      onSurfaceVariant: isDark ? const Color(0xFFC4BBB2) : AppColors.inkMuted,
      outline: isDark ? const Color(0xFF5A524A) : baseScheme.outline,
      outlineVariant:
          isDark ? const Color(0xFF3A342E) : baseScheme.outlineVariant,
    );

    final baseText = ThemeData(brightness: brightness).textTheme.apply(
          fontFamily: fontFamily,
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        );
    final textTheme = baseText.copyWith(
      displayLarge: baseText.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      displayMedium: baseText.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineLarge: baseText.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium:
          baseText.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: baseText.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: baseText.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: baseText.bodyLarge?.copyWith(height: 1.35),
      bodyMedium: baseText.bodyMedium?.copyWith(height: 1.35),
      labelLarge: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );

    final cardColor =
        isDark ? colorScheme.surfaceContainerHighest : AppColors.paper;
    final inputFill =
        isDark ? colorScheme.surfaceContainerHigh : AppColors.paper;
    final navColor = isDark ? colorScheme.surfaceContainer : AppColors.paper;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.35),
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.secondaryContainer,
        selectedColor: colorScheme.primary.withValues(alpha: 0.14),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navColor,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.14),
        elevation: isDark ? 0 : 1,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      progressIndicatorTheme:
          ProgressIndicatorThemeData(color: colorScheme.primary),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: colorScheme.onInverseSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
