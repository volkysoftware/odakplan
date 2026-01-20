import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class ReminderState {
  const ReminderState({required this.enabled, required this.hour, required this.minute});

  final bool enabled;
  final int hour;
  final int minute;

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  ReminderState copyWith({bool? enabled, int? hour, int? minute}) {
    return ReminderState(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}

final reminderProvider =
    StateNotifierProvider<ReminderNotifier, ReminderState>((ref) {
  return ReminderNotifier();
});

class ReminderNotifier extends StateNotifier<ReminderState> {
  ReminderNotifier()
      : super(const ReminderState(enabled: false, hour: 20, minute: 0)) {
    _load();
  }

  final Box<int> _box = Hive.box<int>('settings');

  static const _enabledKey = 'reminderEnabled';
  static const _hourKey = 'reminderHour';
  static const _minuteKey = 'reminderMinute';

  void _load() {
    final enabled = (_box.get(_enabledKey, defaultValue: 0) ?? 0) == 1;
    final hour = _box.get(_hourKey, defaultValue: 20) ?? 20;
    final minute = _box.get(_minuteKey, defaultValue: 0) ?? 0;

    state = ReminderState(enabled: enabled, hour: hour, minute: minute);
  }

  void setEnabled(bool enabled) {
    state = state.copyWith(enabled: enabled);
    _box.put(_enabledKey, enabled ? 1 : 0);
  }

  void setTime(TimeOfDay time) {
    state = state.copyWith(hour: time.hour, minute: time.minute);
    _box.put(_hourKey, time.hour);
    _box.put(_minuteKey, time.minute);
  }
}
