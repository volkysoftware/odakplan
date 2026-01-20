import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:odakplan/app/notifications/notification_service.dart';

import 'app/app.dart';
import 'features/today/models/activity_plan.dart';
import 'features/today/models/activity_plan_adapter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermissions(); // ✅ ekle

  // Adapter
  Hive.registerAdapter(ActivityPlanAdapter());

  // Boxes
  await Hive.openBox<ActivityPlan>('plans');
  await Hive.openBox<int>('history'); // key: 'YYYY-MM-DD'  value: minutes
  await Hive.openBox<int>('settings'); // key: 'dailyTarget' value: int
  await Hive.openBox('op_settings'); // ✅ theme_mode burada

  // Notifications
  await NotificationService.instance.init();

  // ✅ Android 13+ için izin ister. Android 8’de genelde true döner.
  await NotificationService.instance.requestPermissions();

  // ✅ DEBUG: Bildirim sistemi çalışıyor mu diye test
  // Not: İstersen bunu sonra kaldırırız. Şu an sorunu kökten teşhis etmek için ekliyoruz.
  //await NotificationService.instance.showTestNotification();
  //await NotificationService.instance.scheduleTestIn10Seconds();

  runApp(const ProviderScope(child: OdakPlanApp()));
}
