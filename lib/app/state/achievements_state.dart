// lib/app/state/achievements_state.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odakplan/app/state/history_state.dart';
import 'package:odakplan/app/state/streak_state.dart';
import 'package:odakplan/app/state/settings_state.dart';
import 'package:odakplan/app/state/stats_store.dart';

/// Achievement model
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final DateTime? unlockedDate;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    this.unlockedDate,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    bool? isUnlocked,
    DateTime? unlockedDate,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
    );
  }
}

/// All achievements list provider
final achievementsProvider = Provider<List<Achievement>>((ref) {
  final minutesMap = ref.watch(dailyMinutesMapProvider);
  final streak = ref.watch(streakProvider);
  final dailyTarget = ref.watch(dailyTargetProvider);

  // Compute total minutes from history map
  final totalMinutes = minutesMap.values.fold<int>(0, (sum, minutes) => sum + minutes);

  // Get all completed days (days with > 0 minutes)
  final completedDays = minutesMap.entries
      .where((e) => e.value > 0)
      .map((e) => e.key)
      .toList();

  // Find first completed session date
  DateTime? firstSessionDate;
  if (completedDays.isNotEmpty) {
    final sortedDays = [...completedDays]..sort();
    firstSessionDate = _parseDateKey(sortedDays.first);
  }

  // Check if daily target reached (any day)
  bool dailyTargetReached = false;
  DateTime? dailyTargetDate;
  for (final entry in minutesMap.entries) {
    if (entry.value >= dailyTarget) {
      dailyTargetReached = true;
      dailyTargetDate = _parseDateKey(entry.key);
      break;
    }
  }

  // Check for 5 days in a week
  bool weekly5Days = false;
  DateTime? weekly5DaysDate;
  final weekGroups = <String, List<String>>{};
  for (final dayKey in completedDays) {
    final date = _parseDateKey(dayKey);
    if (date == null) continue;
    final weekKey = _getWeekKey(date);
    weekGroups.putIfAbsent(weekKey, () => []).add(dayKey);
  }
  for (final entry in weekGroups.entries) {
    if (entry.value.length >= 5) {
      weekly5Days = true;
      // Use the first day of that week as unlock date
      final sortedWeekDays = [...entry.value]..sort();
      weekly5DaysDate = _parseDateKey(sortedWeekDays.first);
      break;
    }
  }

  return [
    // 1. İlk Seans - First completed focus session
    Achievement(
      id: 'first_session',
      title: 'İlk Seans',
      description: 'İlk odak seansını tamamladın',
      icon: Icons.star_rounded,
      isUnlocked: firstSessionDate != null,
      unlockedDate: firstSessionDate,
    ),

    // 2. 3 Gün Seri - Streak >= 3 (check best streak)
    Achievement(
      id: 'streak_3',
      title: '3 Gün Seri',
      description: '3 gün üst üste hedefe ulaştın',
      icon: Icons.local_fire_department_rounded,
      isUnlocked: streak.best >= 3,
      unlockedDate: streak.best >= 3 ? _findStreakUnlockDate(minutesMap, dailyTarget, 3) : null,
    ),

    // 3. 7 Gün Seri - Streak >= 7 (check best streak)
    Achievement(
      id: 'streak_7',
      title: '7 Gün Seri',
      description: '7 gün üst üste hedefe ulaştın',
      icon: Icons.whatshot_rounded,
      isUnlocked: streak.best >= 7,
      unlockedDate: streak.best >= 7 ? _findStreakUnlockDate(minutesMap, dailyTarget, 7) : null,
    ),

    // 4. Günlük Hedef - Reach dailyTarget minutes in a day
    Achievement(
      id: 'daily_target',
      title: 'Günlük Hedef',
      description: 'Günlük hedefe ulaştın ($dailyTarget dk)',
      icon: Icons.flag_rounded,
      isUnlocked: dailyTargetReached,
      unlockedDate: dailyTargetDate,
    ),

    // 5. Haftalık 5 Gün - Focus on 5 different days within a selected week
    Achievement(
      id: 'weekly_5_days',
      title: 'Haftalık 5 Gün',
      description: 'Bir haftada 5 farklı günde odaklandın',
      icon: Icons.calendar_view_week_rounded,
      isUnlocked: weekly5Days,
      unlockedDate: weekly5DaysDate,
    ),

    // 6. Toplam 10 Saat - Total focused time >= 600 minutes
    Achievement(
      id: 'total_10_hours',
      title: 'Toplam 10 Saat',
      description: 'Toplam 600 dakika odaklandın',
      icon: Icons.timer_rounded,
      isUnlocked: totalMinutes >= 600,
      unlockedDate: totalMinutes >= 600 ? _findTotalMinutesUnlockDate(minutesMap, 600) : null,
    ),
  ];
});

/// Parse date key "YYYY-MM-DD" to DateTime
DateTime? _parseDateKey(String key) {
  try {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    return DateTime(year, month, day);
  } catch (_) {
    return null;
  }
}

/// Get week key in format "YYYY-Www" (ISO week)
String _getWeekKey(DateTime date) {
  final thursday = date.add(Duration(days: 4 - date.weekday));
  final week = ((thursday.difference(DateTime(thursday.year, 1, 1)).inDays) / 7).floor() + 1;
  return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
}

/// Find when streak milestone was reached (based on days that reached daily target)
DateTime? _findStreakUnlockDate(Map<String, int> minutesMap, int dailyTarget, int targetStreak) {
  // Get all days that reached daily target, sorted chronologically
  final targetDays = minutesMap.entries
      .where((e) => e.value >= dailyTarget)
      .map((e) => _parseDateKey(e.key))
      .whereType<DateTime>()
      .toList()
    ..sort();

  if (targetDays.length < targetStreak) return null;

  // Find consecutive days ending at targetStreak
  int consecutive = 0;
  DateTime? lastDate;
  
  for (int i = targetDays.length - 1; i >= 0; i--) {
    final current = targetDays[i];
    if (lastDate == null) {
      consecutive = 1;
      lastDate = current;
    } else {
      final diff = lastDate.difference(current).inDays;
      if (diff == 1) {
        consecutive++;
      } else {
        consecutive = 1;
      }
      lastDate = current;
    }
    
    if (consecutive >= targetStreak) {
      return current;
    }
  }

  return null;
}

/// Find when total minutes milestone was reached
DateTime? _findTotalMinutesUnlockDate(Map<String, int> minutesMap, int targetMinutes) {
  // Sort days chronologically
  final sortedEntries = minutesMap.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  int runningTotal = 0;
  for (final entry in sortedEntries) {
    runningTotal += entry.value;
    if (runningTotal >= targetMinutes) {
      return _parseDateKey(entry.key);
    }
  }

  return null;
}
