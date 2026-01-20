import 'package:flutter_riverpod/flutter_riverpod.dart';

class TodayPlanItem {
  final String id;
  final String name;
  final int minutes;

  const TodayPlanItem({
    required this.id,
    required this.name,
    required this.minutes,
  });
}

final todayPlanProvider =
    StateNotifierProvider<TodayPlanNotifier, List<TodayPlanItem>>((ref) {
  return TodayPlanNotifier();
});

class TodayPlanNotifier extends StateNotifier<List<TodayPlanItem>> {
  TodayPlanNotifier()
      : super(const [
          TodayPlanItem(id: 'm1', name: 'Matematik', minutes: 40),
          TodayPlanItem(id: 'f1', name: 'Fen', minutes: 30),
          TodayPlanItem(id: 'k1', name: 'Kitap', minutes: 20),
        ]);
    void update(String id, {String? name, int? minutes}) {
    state = [
      for (final item in state)
        if (item.id == id)
          TodayPlanItem(
            id: item.id,
            name: name ?? item.name,
            minutes: minutes ?? item.minutes,
          )
        else
          item
    ];
  }

  void add(String name, int minutes) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    state = [...state, TodayPlanItem(id: id, name: name, minutes: minutes)];
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
  }
}
