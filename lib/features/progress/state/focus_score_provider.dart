// lib/features/progress/state/focus_score_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odakplan/app/state/history_state.dart';
import 'package:odakplan/app/state/streak_state.dart';
import 'package:odakplan/app/state/settings_state.dart';
import 'package:odakplan/features/progress/state/progress_period_controller.dart';

/// Computed provider for weekly focus score (0-100)
final weeklyFocusScoreProvider = Provider.autoDispose<int>((ref) {
  final minutesMap = ref.watch(dailyMinutesMapProvider);
  final streak = ref.watch(streakProvider);
  final dailyTarget = ref.watch(dailyTargetProvider);
  final periodState = ref.watch(progressPeriodProvider);

  // Use anchorDate from periodState to compute score for the selected week
  final anchorDate = periodState.period == ProgressPeriod.week
      ? periodState.anchorDate
      : DateTime.now(); // For month view, use current week

  return _computeWeeklyScore(
    minutesMap: minutesMap,
    anchorDate: anchorDate,
    streakDays: streak.current,
    dailyTarget: dailyTarget,
  );
});

/// Computed provider for monthly focus score (0-100)
final monthlyFocusScoreProvider = Provider.autoDispose<int>((ref) {
  final minutesMap = ref.watch(dailyMinutesMapProvider);
  final streak = ref.watch(streakProvider);
  final dailyTarget = ref.watch(dailyTargetProvider);
  final periodState = ref.watch(progressPeriodProvider);

  // Use anchorDate from periodState to compute score for the selected month
  final anchorDate = periodState.period == ProgressPeriod.month
      ? periodState.anchorDate
      : DateTime.now(); // For week view, use current month

  return _computeMonthlyScore(
    minutesMap: minutesMap,
    anchorDate: anchorDate,
    streakDays: streak.current,
    dailyTarget: dailyTarget,
  );
});

/// Helper function to get minutes for a day from the map
int _minutesForDay(Map<String, int> map, DateTime d) {
  final k = _keyDash(d);
  return map[k] ?? 0;
}

String _keyDash(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Get start of week (Monday) for a given date
DateTime _startOfWeek(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  final weekday = d.weekday; // 1 = Monday, 7 = Sunday
  return d.subtract(Duration(days: weekday - 1));
}

/// Get all days in a week (Monday to Sunday)
List<DateTime> _getWeekDays(DateTime anchorDate) {
  final start = _startOfWeek(anchorDate);
  return List.generate(7, (i) => start.add(Duration(days: i)));
}

/// Get start of month
DateTime _startOfMonth(DateTime date) {
  return DateTime(date.year, date.month, 1);
}

/// Get end of month
DateTime _endOfMonth(DateTime date) {
  return DateTime(date.year, date.month + 1, 0);
}

/// Get all days in a month
List<DateTime> _getMonthDays(DateTime anchorDate) {
  final start = _startOfMonth(anchorDate);
  final end = _endOfMonth(anchorDate);
  final days = <DateTime>[];
  var current = start;
  while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
    days.add(current);
    current = current.add(const Duration(days: 1));
  }
  return days;
}

/// Compute weekly focus score (0-100)
int _computeWeeklyScore({
  required Map<String, int> minutesMap,
  required DateTime anchorDate,
  required int streakDays,
  required int dailyTarget,
}) {
  final target = dailyTarget > 0 ? dailyTarget : 120; // Fallback to 120
  final weekDays = _getWeekDays(anchorDate);
  
  // Calculate weekly minutes
  final weeklyMinutes = weekDays.fold<int>(
    0,
    (sum, d) => sum + _minutesForDay(minutesMap, d),
  );
  
  // Count active days (days with > 0 minutes)
  final activeDaysInWeek = weekDays.where((d) => _minutesForDay(minutesMap, d) > 0).length;
  
  // Calculate components
  // minutesScore: up to 60 points based on weekly minutes vs target
  final minutesScore = ((weeklyMinutes / (target * 7)) * 60).clamp(0.0, 60.0);
  
  // consistencyScore: up to 25 points based on active days
  final consistencyScore = ((activeDaysInWeek / 7) * 25).clamp(0.0, 25.0);
  
  // streakBonus: up to 15 points based on streak (capped at 7 days for week)
  final streakBonus = ((streakDays.clamp(0, 7) / 7) * 15).clamp(0.0, 15.0);
  
  // Total score
  final totalScore = (minutesScore + consistencyScore + streakBonus).round();
  
  return totalScore.clamp(0, 100);
}

/// Compute monthly focus score (0-100)
int _computeMonthlyScore({
  required Map<String, int> minutesMap,
  required DateTime anchorDate,
  required int streakDays,
  required int dailyTarget,
}) {
  final target = dailyTarget > 0 ? dailyTarget : 120; // Fallback to 120
  final monthDays = _getMonthDays(anchorDate);
  final daysInMonth = monthDays.length;
  
  // Calculate monthly minutes
  final monthlyMinutes = monthDays.fold<int>(
    0,
    (sum, d) => sum + _minutesForDay(minutesMap, d),
  );
  
  // Count active days (days with > 0 minutes)
  final activeDaysInMonth = monthDays.where((d) => _minutesForDay(minutesMap, d) > 0).length;
  
  // Calculate components
  // minutesScore: up to 60 points based on monthly minutes vs target
  final minutesScore = ((monthlyMinutes / (target * daysInMonth)) * 60).clamp(0.0, 60.0);
  
  // consistencyScore: up to 25 points based on active days
  final consistencyScore = ((activeDaysInMonth / daysInMonth) * 25).clamp(0.0, 25.0);
  
  // streakBonus: up to 15 points based on streak (capped at 7 days for consistency)
  final streakBonus = ((streakDays.clamp(0, 7) / 7) * 15).clamp(0.0, 15.0);
  
  // Total score
  final totalScore = (minutesScore + consistencyScore + streakBonus).round();
  
  return totalScore.clamp(0, 100);
}
