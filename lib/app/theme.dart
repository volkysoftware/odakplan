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
 