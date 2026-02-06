import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odakplan/app/state/history_state.dart';
import 'package:odakplan/app/state/settings_state.dart';
import 'package:odakplan/app/state/streak_state.dart';
import 'package:odakplan/app/state/selection_state.dart';

import 'state/focus_timer_controller.dart';
import 'focus_page.dart';
import 'widgets/focus_start_ritual.dart';

class FocusFullscreenPage extends ConsumerWidget {
  const FocusFullscreenPage({super.key});

  String _format(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  Future<void> _handleStart(
    BuildContext context,
    WidgetRef ref,
    FocusTimerState timer,
    FocusTimerController ctrl,
  ) async {
    // Only show ritual for work sessions (not breaks) and if enabled
    final ritualEnabled = ref.read(focusRitualEnabledProvider);
    final shouldShowRitual = ritualEnabled && !timer.isBreak;

    if (shouldShowRitual) {
      // Show ritual overlay
      await showDialog(
        context: context,
        barrierColor: Colors.black,
        barrierDismissible: false,
        useSafeArea: false,
        builder: (context) => FocusStartRitual(
          onComplete: () {
            Navigator.of(context).pop();
            // Start timer after ritual completes
            ctrl.start();
          },
          onSkip: () {
            Navigator.of(context).pop();
            // Start timer immediately when skipped
            ctrl.start();
          },
        ),
      );
    } else {
      // Start immediately without ritual
      await ctrl.start();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    final timer = ref.watch(focusTimerProvider);
    final ctrl = ref.read(focusTimerProvider.notifier);

    final map = ref.watch(dailyMinutesMapProvider);
    final todayTotal = getTodayTotalMinutesFromMap(map);

    final dailyTarget = ref.watch(dailyTargetProvider);
    final streak = ref.watch(streakProvider);

    final isBreak = timer.isBreak;
    final accentColor = isBreak ? theme.colorScheme.tertiary : theme.colorScheme.primary;

    // Calculate responsive font size (120-200 based on screen size)
    final baseFontSize = (screenWidth * 0.25).clamp(120.0, 200.0);

    // Premium dark background with subtle gradient
    final bgColor = theme.colorScheme.surface;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    bgColor,
                    bgColor.withOpacity(0.95),
                    bgColor,
                  ]
                : [
                    bgColor,
                    bgColor.withOpacity(0.98),
                    bgColor,
                  ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Subtle vignette effect
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(isDark ? 0.15 : 0.05),
                      ],
                    ),
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top bar with close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Tam ekrandan çık',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    // Main clock display area
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Mode label (subtle, above clock)
                            Text(
                              isBreak ? 'Mola' : 'Odak',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: accentColor.withOpacity(0.7),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Large digital time display
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _format(timer.remainingSeconds),
                                style: TextStyle(
                                  fontSize: baseFontSize,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 8,
                                  height: 1.0, // Tight vertical alignment
                                  color: accentColor.withOpacity(0.95),
                                  fontFeatures: const [
                                    FontFeature('tnum'), // Tabular figures for stable digits
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Optional: Today's total and target (very subtle)
                            Text(
                              '$todayTotal / $dailyTarget dk',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.4),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Controls at bottom
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () async {
                                    if (timer.isRunning) {
                                      await ctrl.pause();
                                    } else {
                                      await _handleStart(context, ref, timer, ctrl);
                                    }
                                  },
                                  icon: Icon(
                                    timer.isRunning
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                  ),
                                  label: Text(timer.isRunning ? 'Durdur' : 'Başlat'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: accentColor,
                                    foregroundColor: theme.colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => completeFocusSessionEarly(
                                    context: context,
                                    ref: ref,
                                  ),
                                  icon: const Icon(Icons.check_rounded),
                                  label: const Text('Tamamladım'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.colorScheme.onSurface,
                                    side: BorderSide(
                                      color: theme.colorScheme.outline.withOpacity(0.5),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

