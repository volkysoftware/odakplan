import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class TodayPlan {
  final String id;
  final String title;
  final int minutes;

  const TodayPlan({
    required this.id,
    required this.title,
    required this.minutes,
  });

  TodayPlan copyWith({String? title, int? minutes}) => TodayPlan(
        id: id,
        title: title ?? this.title,
        minutes: minutes ?? this.minutes,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'minutes': minutes,
      };

  static TodayPlan fromMap(Map<dynamic, dynamic> m) {
    return TodayPlan(
      id: (m['id'] ?? '').toString(),
      title: (m['title'] ?? '').toString(),
      minutes: (m['minutes'] ?? 0) is int
          ? (m['minutes'] as int)
          : int.tryParse((m['minutes'] ?? '0').toString()) ?? 0,
    );
  }
}

final todayPlanProvider =
    StateNotifierProvider<TodayPlanNotifier, List<TodayPlan>>(
  (ref) => TodayPlanNotifier()..load(),
);

class TodayPlanNotifier extends StateNotifier<List<TodayPlan>> {
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
      state = raw
          .whereType<Map>()
          .map((e) => TodayPlan.fromMap(e))
          .toList(growable: false);
      if (state.isEmpty) {
        await seedDefaultsIfEmpty();
      }
    } else {
      await seedDefaultsIfEmpty();
    }
  }

  Future<void> seedDefaultsIfEmpty() async {
    // Premium hissi veren, genele hitap eden hazır kartlar:
    final defaults = <TodayPlan>[
      TodayPlan(id: const Uuid().v4(), title: 'Ders Çalışma', minutes: 40),
      TodayPlan(id: const Uuid().v4(), title: 'Dil Çalışma', minutes: 25),
      TodayPlan(id: const Uuid().v4(), title: 'Kitap Okuma', minutes: 20),
      TodayPlan(id: const Uuid().v4(), title: 'Hobi / Proje', minutes: 30),
    ];
    state = defaults;
    await _persist();
  }

  Future<void> addPlan(String title, int minutes) async {
    final plan = TodayPlan(
      id: const Uuid().v4(),
      title: title.trim(),
      minutes: minutes,
    );
    state = [plan, ...state];
    await _persist();
  }

  Future<void> updatePlan(String id, String title, int minutes) async {
    state = [
      for (final p in state)
        if (p.id == id) p.copyWith(title: title.trim(), minutes: minutes) else p
    ];
    await _persist();
  }

  Future<void> deletePlan(String id) async {
    state = state.where((p) => p.id != id).toList(growable: false);
    await _persist();
  }

  Future<void> _persist() async {
    await _ensureBox();
    await _box!.put(_key, state.map((e) => e.toMap()).toList());
  }
}
