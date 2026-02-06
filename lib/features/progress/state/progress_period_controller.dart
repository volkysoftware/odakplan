// lib/features/progress/state/progress_period_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ProgressPeriod { week, month }

class ProgressPeriodState {
  final ProgressPeriod period;
  final DateTime anchorDate; // Week: any day in the week, Month: any day in the month

  const ProgressPeriodState({
    required this.period,
    required this.anchorDate,
  });

  ProgressPeriodState copyWith({
    ProgressPeriod? period,
    DateTime? anchorDate,
  }) {
    return ProgressPeriodState(
      period: period ?? this.period,
      anchorDate: anchorDate ?? this.anchorDate,
    );
  }
}

class ProgressPeriodNotifier extends StateNotifier<ProgressPeriodState> {
  ProgressPeriodNotifier()
      : super(ProgressPeriodState(
          period: ProgressPeriod.week,
          anchorDate: DateTime.now(),
        ));

  void setPeriod(ProgressPeriod period) {
    state = state.copyWith(period: period);
  }

  void setAnchorDate(DateTime date) {
    state = state.copyWith(anchorDate: date);
  }

  void goToPrevious() {
    if (state.period == ProgressPeriod.week) {
      state = state.copyWith(anchorDate: state.anchorDate.subtract(const Duration(days: 7)));
    } else {
      // Previous month
      final prevMonth = DateTime(state.anchorDate.year, state.anchorDate.month - 1, 1);
      state = state.copyWith(anchorDate: prevMonth);
    }
  }

  void goToNext() {
    if (state.period == ProgressPeriod.week) {
      state = state.copyWith(anchorDate: state.anchorDate.add(const Duration(days: 7)));
    } else {
      // Next month
      final nextMonth = DateTime(state.anchorDate.year, state.anchorDate.month + 1, 1);
      state = state.copyWith(anchorDate: nextMonth);
    }
  }

  void goToCurrent() {
    state = state.copyWith(anchorDate: DateTime.now());
  }
}

final progressPeriodProvider =
    StateNotifierProvider<ProgressPeriodNotifier, ProgressPeriodState>(
  (ref) => ProgressPeriodNotifier(),
);
