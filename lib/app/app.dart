import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'router.dart';
import 'theme.dart';

class OdakPlanApp extends ConsumerWidget {
  const OdakPlanApp({super.key});

  static const _settingsBox = 'op_settings';
  static const _kThemeMode = 'theme_mode'; // 'system' | 'light' | 'dark'

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
      valueListenable: box.listenable(keys: const [_kThemeMode]),
      builder: (context, _, __) {
        final modeStr = box.get(_kThemeMode, defaultValue: 'system');
        final mode = _decodeThemeMode(modeStr);

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'OdakPlan',
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(), // ✅ koyu tema gerçekten buradan gelecek
          themeMode: mode, // ✅ sistem/açık/koyu artık anlık uygulanır
          routerConfig: router,
        );
      },
    );
  }
}
