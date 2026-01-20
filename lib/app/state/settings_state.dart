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
