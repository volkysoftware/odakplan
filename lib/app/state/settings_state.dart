import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final dailyTargetProvider =
    StateNotifierProvider<DailyTargetNotifier, int>((ref) {
  return DailyTargetNotifier();
});

class DailyTargetNotifier extends StateNotifier<int> {
  DailyTargetNotifier() : super(120) {
    _load();
  }

  final Box<int> _box = Hive.box<int>('settings');
  static const _key = 'dailyTarget';

  void _load() {
    state = _box.get(_key, defaultValue: 120) ?? 120;
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

final focusRitualEnabledProvider =
    StateNotifierProvider<FocusRitualEnabledNotifier, bool>((ref) {
  return FocusRitualEnabledNotifier();
});

class FocusRitualEnabledNotifier extends StateNotifier<bool> {
  FocusRitualEnabledNotifier() : super(true) {
    _load();
  }

  final Box<dynamic> _box = Hive.box<dynamic>('op_settings');
  static const _key = 'focus_ritual_enabled';

  void _load() {
    state = _box.get(_key, defaultValue: true) as bool? ?? true;
  }

  void setEnabled(bool value) {
    state = value;
    _box.put(_key, value);
  }
}

final postFocusSuggestionsEnabledProvider =
    StateNotifierProvider<PostFocusSuggestionsEnabledNotifier, bool>((ref) {
  return PostFocusSuggestionsEnabledNotifier();
});

class PostFocusSuggestionsEnabledNotifier extends StateNotifier<bool> {
  PostFocusSuggestionsEnabledNotifier() : super(true) {
    _load();
  }

  final Box<dynamic> _box = Hive.box<dynamic>('op_settings');
  static const _key = 'post_focus_suggestions_enabled';

  void _load() {
    state = _box.get(_key, defaultValue: true) as bool? ?? true;
  }

  void setEnabled(bool value) {
    state = value;
    _box.put(_key, value);
  }
}

final softThemeProvider =
    StateNotifierProvider<SoftThemeNotifier, bool>((ref) {
  return SoftThemeNotifier();
});

class SoftThemeNotifier extends StateNotifier<bool> {
  SoftThemeNotifier() : super(false) {
    _load();
  }

  final Box<dynamic> _box = Hive.box<dynamic>('op_settings');
  static const _key = 'soft_theme';

  void _load() {
    state = _box.get(_key, defaultValue: false) as bool? ?? false;
  }

  void setEnabled(bool value) {
    state = value;
    _box.put(_key, value);
  }
}
