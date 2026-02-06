import 'package:flutter/material.dart';

ThemeData buildLightTheme() {
  // Senin mevcut light temasını bozmamak için sade ve güvenli bir light tema veriyorum.
  // İstersen sonraki adımda light tarafını da “premium” hale getiririz.
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      scrolledUnderElevation: 0,
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}

ThemeData buildDarkTheme() {
  // Premium hissi veren “true dark” (OLED’e yakın) + Material 3
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
  );

  // Tam siyaha yakın arka plan + iyi kontrast
  const bg = Color(0xFF0B0B0F);
  const surface = Color(0xFF12121A);
  const surface2 = Color(0xFF181823);

  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7C4DFF), // mor vurgu (premium hissi)
    brightness: Brightness.dark,
    surface: surface,
    background: bg,
  );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,

    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),

    cardTheme: const CardThemeData(
      color: surface2,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: surface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    dividerTheme: DividerThemeData(
      color: Colors.white.withOpacity(0.08),
      thickness: 1,
      space: 1,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary.withOpacity(0.9), width: 1.2),
      ),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.55)),
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.70)),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: surface2,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),

    // iOS/Android ripple vs daha yumuşak etkileşim
    splashFactory: InkSparkle.splashFactory,
  );
}

/// Soft theme variant: softer colors, reduced contrast, eye-friendly
ThemeData buildSoftLightTheme() {
  final baseTheme = buildLightTheme();
  final baseScheme = baseTheme.colorScheme;

  // Softer surface colors with reduced contrast
  final softScheme = baseScheme.copyWith(
    surface: baseScheme.surface.withOpacity(0.95),
    surfaceContainerHighest: baseScheme.surfaceContainerHighest.withOpacity(0.85),
    surfaceContainerHigh: baseScheme.surfaceContainerHigh.withOpacity(0.80),
    surfaceContainer: baseScheme.surfaceContainer.withOpacity(0.75),
    surfaceContainerLow: baseScheme.surfaceContainerLow.withOpacity(0.70),
    surfaceContainerLowest: baseScheme.surfaceContainerLowest.withOpacity(0.65),
    outlineVariant: baseScheme.outlineVariant.withOpacity(0.4),
    outline: baseScheme.outline.withOpacity(0.5),
  );

  return baseTheme.copyWith(
    colorScheme: softScheme,
    scaffoldBackgroundColor: baseScheme.surface.withOpacity(0.92),
    cardTheme: CardThemeData(
      color: baseScheme.surface.withOpacity(0.90),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: baseScheme.outlineVariant.withOpacity(0.3),
          width: 0.5,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: baseScheme.outlineVariant.withOpacity(0.25),
      thickness: 0.5,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: baseScheme.surfaceContainerHighest.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: baseScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: baseScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: baseScheme.primary.withOpacity(0.6),
          width: 1.0,
        ),
      ),
    ),
  );
}

/// Soft theme variant for dark mode: softer colors, reduced contrast
ThemeData buildSoftDarkTheme() {
  final baseTheme = buildDarkTheme();
  final baseScheme = baseTheme.colorScheme;

  // Softer, less harsh dark colors
  final softBg = Color.lerp(const Color(0xFF0B0B0F), const Color(0xFF1A1A24), 0.3);
  final softSurface = Color.lerp(const Color(0xFF12121A), const Color(0xFF1E1E2A), 0.3);
  final softSurface2 = Color.lerp(const Color(0xFF181823), const Color(0xFF242430), 0.3);

  final softScheme = ColorScheme.fromSeed(
    seedColor: baseScheme.primary.withOpacity(0.85),
    brightness: Brightness.dark,
    surface: softSurface!,
    background: softBg!,
  );

  return baseTheme.copyWith(
    colorScheme: softScheme,
    scaffoldBackgroundColor: softBg,
    canvasColor: softBg,
    appBarTheme: AppBarTheme(
      backgroundColor: softBg,
      foregroundColor: Colors.white.withOpacity(0.95),
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: softSurface2,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withOpacity(0.05),
          width: 0.5,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: softSurface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: softSurface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white.withOpacity(0.05),
      thickness: 0.5,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: softScheme.primary.withOpacity(0.7),
          width: 1.0,
        ),
      ),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.50)),
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.65)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: softSurface2,
      contentTextStyle: TextStyle(color: Colors.white.withOpacity(0.95)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
 