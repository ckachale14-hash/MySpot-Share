import 'package:flutter/material.dart';

import 'brand_colors.dart';

/// MySpot Share theme — a blue→green brand with a coral accent, Material 3.
/// Palette and rationale: docs/brand/BRAND.md.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    // Seed from the brand blue so Material generates accessible container /
    // on-* pairs, then pin primary/secondary/tertiary/error to brand colors.
    final scheme = ColorScheme.fromSeed(
      seedColor: Brand.blue,
      brightness: brightness,
    ).copyWith(
      primary: isLight ? Brand.blue : Brand.blueOnDark,
      secondary: isLight ? Brand.green : Brand.greenOnDark,
      tertiary: isLight ? Brand.coral : Brand.coralOnDark,
      error: isLight ? Brand.error : Brand.errorOnDark,
      surface: isLight ? Colors.white : Brand.darkSurface,
      onSurface: isLight ? Brand.ink : Brand.onDark,
    );

    final background = isLight ? Brand.cloud : Brand.darkBackground;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    );
  }
}
