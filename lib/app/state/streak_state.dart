import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'stats_store.dart';

class StreakState {
  final int current;
  final int best;
  final String lastCompletedDayKey; // yyyy-MM-dd
  final String rescueUsedWeekKey; // yyyy-Www

  const StreakState({
    required this.current,
    required this.best,
    required this.lastCompletedDayKey,
    required this.rescueUsedWeekKey,
  });

  StreakState copyWith({
    int? current,
    int? best,
    String? lastCompletedDayKey,
    String? rescueUsedWeekKey,
  }) {
    return StreakState(
      current: current ?? this.current,
      best: best ?? this.best,
      lastCompletedDayKey: lastCompletedDayKey ?? this.lastCompletedDayKey,
      rescueUsedWeekKey: rescueUsedWeekKey ?? this.rescueUsedWeekKey,
    );
  }
}

final streakProvider =
    NotifierProvider<StreakNotifier, StreakState>(StreakNotifier.new);

class StreakNotifier extends Notifier<StreakState> {
  @override
  StreakState build() {
    // İlk build synchronous; değerleri yüklemek için defaults dönüyoruz,
    // hemen ardından async load ile state’i güncelliyoruz.
    _load();
    return const StreakState(
      current: 0,
      best: 0,
      lastCompletedDayKey: '',
      rescueUsedWeekKey: '',
    );
  }

  Future<void> _load() async {
    final current = await StatsStore.getCurrentStreak();
    final best = await StatsStore.getBestStreak();
    final last = await StatsStore.getLastCompletedDayKey();
    final rescue = await StatsStore.getRescueUsedWeekKey();

    state = StreakState(
      current: current,
      best: best,
      lastCompletedDayKey: last,
      rescueUsedWeekKey: rescue,
    );
  }

  // yyyy-MM-dd
  String dayKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime? parseDayKey(String key) {
    if (key.trim().isEmpty) return null;
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool isYesterday(DateTime last, DateTime today) {
    final y = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 1));
    return isSameDay(last, y);
  }

  bool isDayBeforeYesterday(DateTime last, DateTime today) {
    final dby = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 2));
    return isSameDay(last, dby);
  }

  // ISO-ish week key: yyyy-Www (yaklaşık, yeterince güvenli)
  String weekKey(DateTime dt) {
    // Basit week no: yılın kaçıncı haftası (Pazartesi başlangıç)
    final date = DateTime(dt.year, dt.month, dt.day);
    final weekday = (date.weekday + 6) % 7; // Mon=0..Sun=6
    final thursday = date.subtract(Duration(days: weekday - 3));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final firstWeekThursday = firstThursday.subtract(
      Duration(days: ((firstThursday.weekday + 6) % 7) - 3),
    );
    final diffDays = thursday.difference(firstWeekThursday).inDays;
    final week = 1 + (diffDays ~/ 7);
    final w = week.toString().padLeft(2, '0');
    return '${thursday.year}-W$w';
  }

  /// Dakika eklendiğinde (özellikle hedef tamamlandığında) çağırıyoruz.
  /// dailyTarget tamamlandıysa günü "completed" sayıyoruz ve seriyi güncelliyoruz.
  Future<void> onMinutesAdded({
    required int workedMinutes,
    required int todayTotalMinutes,
    required int dailyTargetMinutes,
  }) async {
    // toplam dakika
    await StatsStore.addMinutes(workedMinutes);

    final now = DateTime.now();
    final todayKey = dayKey(now);

    // hedefe ulaşmadıysa streak’i elleme
    if (todayTotalMinutes < dailyTargetMinutes) return;

    // gün tamamlandı
    await StatsStore.markDayCompleted(todayKey);

    final last = parseDayKey(state.lastCompletedDayKey);
    final today = DateTime(now.year, now.month, now.day);

    int newCurrent = state.current;
    int newBest = state.best;

    if (last == null) {
      newCurrent = 1;
    } else {
      if (isSameDay(last, today)) {
        // zaten bugün tamamlandı -> değişme
      } else if (isYesterday(last, today)) {
        // ardışık gün
        newCurrent = state.current + 1;
      } else {
        // arada gün kaçtı -> seri sıfırlanır
        newCurrent = 1;
      }
    }

    if (newCurrent > newBest) newBest = newCurrent;

    await StatsStore.setStreak(
      current: newCurrent,
      best: newBest,
      lastCompletedDayKey: todayKey,
    );

    state = state.copyWith(
      current: newCurrent,
      best: newBest,
      lastCompletedDayKey: todayKey,
    );
  }

  /// Seri kurtarma teklif edilsin mi?
  /// Şart: (1) seri > 0, (2) son tamamlanan gün = evvelsi gün (dün kaçırılmış),
  /// (3) bu hafta daha önce kurtarma kullanılmamış, (4) bugün tamamlanmamış
  bool shouldOfferRescue() {
    if (state.current <= 0) return false;

    final now = DateTime.now();
    final todayKey = dayKey(now);
    if (state.lastCompletedDayKey == todayKey) return false;

    final last = parseDayKey(state.lastCompletedDayKey);
    if (last == null) return false;

    final wk = weekKey(now);
    if (state.rescueUsedWeekKey == wk) return false;

    final today = DateTime(now.year, now.month, now.day);

    // evvelsi gün tamamlanmışsa, dün kaçırılmış demektir
    if (!isDayBeforeYesterday(last, today)) return false;

    return true;
  }

  /// Seri kurtarma uygula (haftada 1)
  /// Etki: Bugünü tamamlanmış sayar, seri düşmez.
  Future<bool> useRescue() async {
    if (!shouldOfferRescue()) return false;

    final now = DateTime.now();
    final todayKey = dayKey(now);
    final wk = weekKey(now);

    await StatsStore.markDayCompleted(todayKey);
    await StatsStore.setRescueUsedWeekKey(wk);

    // Streak sayısını değiştirmiyoruz (kurtarma mantığı)
    // Sadece "son tamamlanan gün" ve "kurtarma haftası" güncelleniyor.
    await StatsStore.setStreak(
      current: state.current,
      best: state.best,
      lastCompletedDayKey: todayKey,
    );

    state = state.copyWith(
      lastCompletedDayKey: todayKey,
      rescueUsedWeekKey: wk,
    );

    return true;
  }
}
