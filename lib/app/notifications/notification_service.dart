import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Tek günlük (her gün) hatırlatıcı için ID
  static const int _dailyReminderId = 1001;

  // Haftanın günlerine göre (1..7) ayrı ID üretelim
  // 2001..2007
  static int _weeklyId(int weekday) => 2000 + weekday;

  // ✅ Odak sayacı (ongoing) bildirimi için ID
  static const int _focusOngoingId = 3001;

  // ✅ Seans bitti (scheduled) bildirimi için ID
  static const int _focusFinishedId = 3002;

  static const String _channelId = 'daily_reminder';
  static const String _channelName = 'Günlük Hatırlatıcı';
  static const String _channelDesc = 'OdakPlan günlük hatırlatma bildirimleri';

  // ✅ Ongoing timer bildirimi için ayrı channel
  static const String _focusChannelId = 'focus_timer';
  static const String _focusChannelName = 'Odak Sayacı';
  static const String _focusChannelDesc =
      'OdakPlan odak sayacı devam ederken kalan süreyi gösterir';

  // ✅ Seans bitti bildirimi için channel
  static const String _focusFinishChannelId = 'focus_finish';
  static const String _focusFinishChannelName = 'Oturum Bildirimi';
  static const String _focusFinishChannelDesc =
      'OdakPlan seans bittiğinde bildirim gönderir';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Timezone init
    tz.initializeTimeZones();

    // flutter_timezone 5.x -> TimezoneInfo döndürebilir
    final tzInfo = await FlutterTimezone.getLocalTimezone();

    // flutter_timezone bazı sürümlerde String, bazı sürümlerde TimezoneInfo döndürüyor.
    // Bu yüzden her iki durumda da kesin String'e çeviriyoruz.
    final String localName = (tzInfo is String)
        ? tzInfo.toString()
        : (tzInfo as dynamic).identifier.toString();

    tz.setLocalLocation(tz.getLocation(localName));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    );

    _initialized = true;
  }

  /// İzin iste (Android 13+ için notifications permission, iOS/macOS için standart izin)
  Future<bool> requestPermissions() async {
    await init();

    bool granted = true;

    // iOS/macOS
    if (Platform.isIOS || Platform.isMacOS) {
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final macImpl = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();

      final iosGranted = await iosImpl?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          true;

      final macGranted = await macImpl?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          true;

      granted = iosGranted && macGranted;
    }

    // Android
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final androidGranted =
        await androidImpl?.requestNotificationsPermission() ?? true;
    granted = granted && androidGranted;

    // (opsiyonel) exact alarms izni
    try {
      await androidImpl?.requestExactAlarmsPermission();
    } catch (_) {}

    return granted;
  }

  /// Eski ismi kullanan yerler kırılmasın diye alias:
  Future<bool> requestPermission() => requestPermissions();

  NotificationDetails _details() {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails();

    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  // ✅ Odak sayacı ongoing bildirimi detayları
  NotificationDetails _focusOngoingDetails() {
    const androidDetails = AndroidNotificationDetails(
      _focusChannelId,
      _focusChannelName,
      channelDescription: _focusChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      onlyAlertOnce: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  // ✅ Seans bitti (scheduled) bildirimi detayları
  NotificationDetails _focusFinishedDetails() {
    const androidDetails = AndroidNotificationDetails(
      _focusFinishChannelId,
      _focusFinishChannelName,
      channelDescription: _focusFinishChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      ongoing: false,
      autoCancel: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  /// ✅ Odak sayacı çalışırken bildirimde kalan süreyi göster (aynı ID ile update edilir)
  Future<void> showFocusOngoing({
    required String title,
    required String body,
  }) async {
    await init();

    await _plugin.show(
      _focusOngoingId,
      title,
      body,
      _focusOngoingDetails(),
    );
  }

  /// ✅ Odak sayacı durunca/sıfırlanınca/tamamlanınca bildirimi kapat
  Future<void> cancelFocusOngoing() async {
    await init();
    await _plugin.cancel(_focusOngoingId);
  }

  /// ✅ Seans bitiş bildirimini planla (uygulama kapalı olsa da gelsin)
  Future<void> scheduleFocusFinishedAt({
    required DateTime endAt,
    required String title,
    required String body,
  }) async {
    await init();

    // Önce varsa eskisini iptal (çakışmasın)
    await _plugin.cancel(_focusFinishedId);

    final when = tz.TZDateTime.from(endAt, tz.local);

    await _plugin.zonedSchedule(
      _focusFinishedId,
      title,
      body,
      when,
      _focusFinishedDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Tek seferlik => matchDateTimeComponents vermiyoruz
    );
  }

  /// ✅ Planlanmış "seans bitti" bildirimini iptal et
  Future<void> cancelFocusFinishedSchedule() async {
    await init();
    await _plugin.cancel(_focusFinishedId);
  }

  /// Anında test bildirimi
  Future<void> showTestNotification() async {
    await init();
    await _plugin.show(
      9999,
      'Test Bildirimi',
      'Bildirim sistemi çalışıyor ✅',
      _details(),
    );
  }

  /// (Uyumluluk) Bazı yerlerde çağrılıyor olabilir. 10 sn sonra tek seferlik bildirim.
  Future<void> scheduleTestIn10Seconds() async {
    await init();
    final scheduled =
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));

    await _plugin.zonedSchedule(
      9998,
      '10 sn Test',
      '10 saniye sonra geldim ✅',
      scheduled,
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Her gün aynı saatte (gün seçimi yok)
  Future<void> scheduleDailyReminder(
    TimeOfDay time, {
    required String title,
    required String body,
  }) async {
    await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyReminderId,
      title,
      body,
      scheduled,
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// ✅ Gün seçimi destekli (1..7) haftalık program
  /// days: {1..7}  (1=Pzt ... 7=Paz)
  Future<void> scheduleReminder(
    TimeOfDay time, {
    required Set<int> days,
    required String title,
    required String body,
  }) async {
    await init();

    // Önce eski programları temizle (çakışmayı engeller)
    await cancelReminderSchedules();

    // Eğer days boş gelirse: her gün kabul edelim
    final effectiveDays = days.isEmpty ? {1, 2, 3, 4, 5, 6, 7} : days;

    final now = tz.TZDateTime.now(tz.local);

    for (final weekday in effectiveDays) {
      if (weekday < 1 || weekday > 7) continue;

      int addDays = weekday - now.weekday;
      if (addDays < 0) addDays += 7;

      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      ).add(Duration(days: addDays));

      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 7));
      }

      await _plugin.zonedSchedule(
        _weeklyId(weekday), // ✅ FIX: id yerine doğru weekly id
        title,
        body,
        scheduled,
        _details(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents:
            DateTimeComponents.dayOfWeekAndTime, // ✅ FIX: haftalık doğru eşleşme
      );
    }
  }

  /// Tüm hatırlatıcı programlarını temizle (günlük + haftalık)
  Future<void> cancelReminderSchedules() async {
    await init();

    await _plugin.cancel(_dailyReminderId);

    for (var d = 1; d <= 7; d++) {
      await _plugin.cancel(_weeklyId(d));
    }
  }

  /// Eski ismi kullanan yerler kırılmasın diye alias:
  Future<void> cancelDailyReminder() => cancelReminderSchedules();
}
