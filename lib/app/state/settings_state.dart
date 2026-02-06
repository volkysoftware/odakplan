import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final dailyTargetProvider =
    StateNotifierProvider<DailyTargetNotifier, int>((ref) {
  return DailyTargetNotifier();
});

class DailyTargetNotifier extends StateNotifier<int> {
  DailyTargetNotifier() : super(60) {
    _load();
  }

  final Box<int> _box = Hive.box<int>('settings');
  static const _key = 'dailyTarget';

  void _load() {
    state = _box.get(_key, defaultValue: 60) ?? 60;
  }

  void setTarget(int value) {
    state = value;
    _box.put(_key, value);
  }
}

final breakMinutesProvider =
    StateNotifierProvider<BreakMinutesNotifier, int>((ref) {
  return BreakMinutesNotifier();
});

class BreakMinutesNotifier extends StateNotifier<int> {
  BreakMinutesNotifier() : super(5) {
    _load();
  }

  final Box<int> _box = Hive.box<int>('settings');
  static const _key = 'breakMinutes';

  void _load() {
    final value = _box.get(_key, defaultValue: 5) ?? 5;
    state = value.clamp(1, 30);
  }

  void setBreakMinutes(int value) {
    state = value.clamp(1, 30);
    _box.put(_key, state);
  }
}
