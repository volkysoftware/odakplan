import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'router.dart';
import 'theme.dart';

class OdakPlanApp extends ConsumerWidget {
  const OdakPlanApp({super.key});

  static const _settingsBox = 'op_settings';
  static const _kThemeMode = 'theme_mode'; // 'system' | 'light' | 'dark'
  static const _kSoftTheme = 'soft_theme'; // bool

  ThemeMode _decodeThemeMode(dynamic v) {
    if (v == 'dark') return ThemeMode.dark;
    if (v == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    final box = Hive.box(_settingsBox);

    return ValueListenableBuilder(
      valueListenable: box.listenable(keys: const [_kThemeMode, _kSoftTheme]),
      builder: (context, _, __) {
        final modeStr = box.get(_kThemeMode, defaultValue: 'system');
        final mode = _decodeThemeMode(modeStr);
        final isSoftTheme = box.get(_kSoftTheme, defaultValue: false) as bool? ?? false;

        // Select theme based on soft theme toggle
        final lightTheme = isSoftTheme ? buildSoftLightTheme() : buildLightTheme();
        final darkTheme = isSoftTheme ? buildSoftDarkTheme() : buildDarkTheme();

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'OdakPlan',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: mode,
          routerConfig: router,
        );
      },
    );
  }
}
