import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:odakplan/app/app.dart';
import 'package:odakplan/features/today/models/activity_plan_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory _tempDir;

  setUpAll(() async {
    _tempDir = await Directory.systemTemp.createTemp('odakplan_test_');
    Hive.init(_tempDir.path);

    // Adapter (boş box'ta şart değil ama güvenli)
    try {
      Hive.registerAdapter(ActivityPlanAdapter());
    } catch (_) {}

    // ✅ Uygulamada erişilmesi muhtemel tüm box'ları açalım
    // (app.dart / state dosyalarında Hive.box('...') geçen isimler burada olmalı)
    final boxNames = <String>[
      'plans',
      'history',
      'settings',
      'stats',
      'streak',
      'badges',
      'app',
      'prefs',
      'preferences',
      'app_settings',
      'notification_settings',
    ];

    for (final name in boxNames) {
      if (!Hive.isBoxOpen(name)) {
        try {
          await Hive.openBox(name); // dynamic box
        } catch (_) {
          // ignore: test ortamında bazı kombinasyonlar sorun çıkarırsa sessiz geç
        }
      }
    }
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await _tempDir.delete(recursive: true);
    } catch (_) {}
  });

  testWidgets('OdakPlanApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: OdakPlanApp()));
    await tester.pumpAndSettle();

    expect(find.byType(OdakPlanApp), findsOneWidget);
  });
}
