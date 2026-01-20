// lib/app/state/history_state.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Günlük dakika geçmişi: "YYYY-MM-DD" -> dakika
final dailyMinutesMapProvider =
    StateNotifierProvider<DailyMinutesNotifier, Map<String, int>>(
  (ref) => DailyMinutesNotifier(ref),
);

/// Bugünün toplam dakikası (okunur)
final todayMinutesProvider = Provider<int>((ref) {
  final map = ref.watch(dailyMinutesMapProvider);
  final now = DateTime.now();
  final k =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return map[k] ?? 0;
});

class DailyMinutesNotifier extends StateNotifier<Map<String, int>> {
  DailyMinutesNotifier(this._ref) : super(const {}) {
    _loadFromHive();
  }

  final Ref _ref;

  // main.dart içinde açtığın box adıyla aynı olmalı:
  // await Hive.openBox<int>('history');
  static const String _boxName = 'history';

  Box<int> get _box => Hive.box<int>(_boxName);

  String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _loadFromHive() {
    // Hive box zaten main.dart'ta açıldığı için burada sync okuyabiliriz.
    try {
      final map = <String, int>{};
      for (final k in _box.keys) {
        final key = k.toString();
        final v = _box.get(key);
        if (v == null) continue;
        // sadece doğru formatlı key'leri alalım (basit kontrol)
        if (key.length == 10 && key[4] == '-' && key[7] == '-') {
          map[key] = v;
        }
      }
      state = map;
    } catch (_) {
      // sessiz geç
      state = const {};
    }
  }

  /// Bugünün toplamını döndürür
  int getToday() {
    final k = _key(DateTime.now());
    return state[k] ?? 0;
  }

  /// Bugüne dakika ekler (Hem state hem Hive)
  void addToToday(int minutes) {
    if (minutes <= 0) return;

    final k = _key(DateTime.now());
    final current = state[k] ?? 0;
    final next = (current + minutes).clamp(0, 24 * 60);

    state = {...state, k: next};

    // ✅ kalıcılık
    try {
      _box.put(k, next);
    } catch (_) {}
  }

  /// Belirli güne dakika ekler (Hem state hem Hive)
  void addToDate(DateTime date, int minutes) {
    if (minutes <= 0) return;

    final k = _key(date);
    final current = state[k] ?? 0;
    final next = (current + minutes).clamp(0, 24 * 60);

    state = {...state, k: next};

    try {
      _box.put(k, next);
    } catch (_) {}
  }

  /// Belirli günün dakikasını set eder (Hem state hem Hive)
  void setForDate(DateTime date, int minutes) {
    final k = _key(date);
    final next = minutes.clamp(0, 24 * 60);

    state = {...state, k: next};

    try {
      _box.put(k, next);
    } catch (_) {}
  }

  /// Tüm geçmişi siler (Hem state hem Hive)
  void clearAll() {
    state = const {};
    try {
      _box.clear();
    } catch (_) {}
  }

  /// (İstersen) belirli günü silmek için
  void removeDate(DateTime date) {
    final k = _key(date);
    if (!state.containsKey(k)) return;

    final copy = {...state}..remove(k);
    state = copy;

    try {
      _box.delete(k);
    } catch (_) {}
  }
}
