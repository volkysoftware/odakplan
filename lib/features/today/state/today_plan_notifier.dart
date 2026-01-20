import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/activity_plan.dart';

final todayPlanProvider =
    StateNotifierProvider<TodayPlanNotifier, List<ActivityPlan>>(
  (ref) => TodayPlanNotifier()..load(),
);

class TodayPlanNotifier extends StateNotifier<List<ActivityPlan>> {
  TodayPlanNotifier() : super(const []);

  static const _boxName = 'today_plans_box';
  static const _key = 'plans';

  Box? _box;

  Future<void> _ensureBox() async {
    _box ??= await Hive.openBox(_boxName);
  }

  Future<void> load() async {
    await _ensureBox();
    final raw = _box!.get(_key);

    if (raw is List) {
      final list = <ActivityPlan>[];
      for (final e in raw) {
        if (e is Map) list.add(ActivityPlan.fromMap(e));
      }
      state = list;
      if (state.isEmpty) {
        await seedDefaultsIfEmpty();
      }
      return;
    }

    await seedDefaultsIfEmpty();
  }

  Future<void> seedDefaultsIfEmpty() async {
    final defaults = <ActivityPlan>[
      ActivityPlan(id: const Uuid().v4(), title: 'Ders Çalışma', minutes: 40),
      ActivityPlan(id: const Uuid().v4(), title: 'Dil Çalışma', minutes: 25),
      ActivityPlan(id: const Uuid().v4(), title: 'Kitap Okuma', minutes: 20),
      ActivityPlan(id: const Uuid().v4(), title: 'Hobi / Proje', minutes: 30),
    ];
    state = defaults;
    await _persist();
  }

  Future<void> addPlan(String title, int minutes) async {
    await _ensureBox();
    final plan = ActivityPlan(
      id: const Uuid().v4(),
      title: title.trim(),
      minutes: minutes,
    );
    state = [plan, ...state];
    await _persist();
  }

  Future<void> updatePlan(String id, String title, int minutes) async {
    await _ensureBox();
    state = [
      for (final p in state)
        if (p.id == id) p.copyWith(title: title.trim(), minutes: minutes) else p
    ];
    await _persist();
  }

  Future<void> deletePlan(String id) async {
    await _ensureBox();
    state = state.where((p) => p.id != id).toList(growable: false);
    await _persist();
  }

  Future<void> _persist() async {
    await _ensureBox();
    await _box!.put(_key, state.map((e) => e.toMap()).toList());
  }
}
