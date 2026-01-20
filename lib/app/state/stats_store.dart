import 'package:hive/hive.dart';

class StatsStore {
  static const String _boxName = 'stats_box';

  static const String kTotalMinutes = 'totalMinutes';
  static const String kCurrentStreak = 'currentStreak';
  static const String kBestStreak = 'bestStreak';
  static const String kLastCompletedDay = 'lastCompletedDay'; // yyyy-MM-dd
  static const String kCompletedDays = 'completedDays'; // List<String> yyyy-MM-dd
  static const String kRescueUsedWeek = 'rescueUsedWeek'; // yyyy-Www

  static Box<dynamic>? _box;

  static Future<Box<dynamic>> _ensureBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<dynamic>(_boxName);

    // defaults
    if (!_box!.containsKey(kTotalMinutes)) await _box!.put(kTotalMinutes, 0);
    if (!_box!.containsKey(kCurrentStreak)) await _box!.put(kCurrentStreak, 0);
    if (!_box!.containsKey(kBestStreak)) await _box!.put(kBestStreak, 0);
    if (!_box!.containsKey(kLastCompletedDay)) {
      await _box!.put(kLastCompletedDay, '');
    }
    if (!_box!.containsKey(kCompletedDays)) {
      await _box!.put(kCompletedDays, <String>[]);
    }
    if (!_box!.containsKey(kRescueUsedWeek)) {
      await _box!.put(kRescueUsedWeek, '');
    }
    return _box!;
  }

  static Future<int> getTotalMinutes() async {
    final b = await _ensureBox();
    return (b.get(kTotalMinutes) as int?) ?? 0;
  }

  static Future<int> getCurrentStreak() async {
    final b = await _ensureBox();
    return (b.get(kCurrentStreak) as int?) ?? 0;
  }

  static Future<int> getBestStreak() async {
    final b = await _ensureBox();
    return (b.get(kBestStreak) as int?) ?? 0;
  }

  static Future<String> getLastCompletedDayKey() async {
    final b = await _ensureBox();
    return (b.get(kLastCompletedDay) as String?) ?? '';
  }

  static Future<List<String>> getCompletedDays() async {
    final b = await _ensureBox();
    final raw = b.get(kCompletedDays);
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return <String>[];
  }

  static Future<String> getRescueUsedWeekKey() async {
    final b = await _ensureBox();
    return (b.get(kRescueUsedWeek) as String?) ?? '';
  }

  static Future<void> setRescueUsedWeekKey(String weekKey) async {
    final b = await _ensureBox();
    await b.put(kRescueUsedWeek, weekKey);
  }

  static Future<void> addMinutes(int minutes) async {
    final b = await _ensureBox();
    final cur = (b.get(kTotalMinutes) as int?) ?? 0;
    await b.put(kTotalMinutes, cur + minutes);
  }

  static Future<void> setStreak({
    required int current,
    required int best,
    required String lastCompletedDayKey,
  }) async {
    final b = await _ensureBox();
    await b.put(kCurrentStreak, current);
    await b.put(kBestStreak, best);
    await b.put(kLastCompletedDay, lastCompletedDayKey);
  }

  static Future<void> markDayCompleted(String dayKey) async {
    final b = await _ensureBox();
    final list = await getCompletedDays();
    if (!list.contains(dayKey)) {
      list.add(dayKey);
      await b.put(kCompletedDays, list);
    }
    await b.put(kLastCompletedDay, dayKey);
  }
}
