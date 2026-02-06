import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odakplan/app/state/history_state.dart';
import 'package:odakplan/app/state/settings_state.dart';
import 'package:odakplan/app/state/streak_state.dart';
import 'package:odakplan/app/state/selection_state.dart';

import 'state/focus_timer_controller.dart';
import 'focus_page.dart';
import 'widgets/focus_start_ritual.dart';
import 'widgets/post_focus_suggestion_sheet.dart';

class FocusFullscreenPage extends ConsumerStatefulWidget {
  const FocusFullscreenPage({super.key});

  @override
  ConsumerState<FocusFullscreenPage> createState() => _FocusFullscreenPageState();
}

class _FocusFullscreenPageState extends ConsumerState<FocusFullscreenPage> {
  String _format(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  int _getTodayTotalMinutes(Map<String, int> map) {
    if (map.containsKey('today')) return map['today'] ?? 0;

    final now = DateTime.now();
    final dash =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final compact =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    if (map.containsKey(dash)) return map[dash] ?? 0;
    if (map.containsKey(compact)) return map[compact] ?? 0;

    return 0;
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

  Future<void> _completeEarly() async {
    final timer = ref.read(focusTimerProvider);
    final ctrl = ref.read(focusTimerProvider.notifier);

    if (timer.isBreak) {
      await ctrl.pause();
      return;
    }

    final addedMinutes = await ctrl.completeEarlyMinutes(ceil: true);
    if (addedMinutes <= 0) return;

    final mapBefore = ref.read(dailyMinutesMapProvider);
    final todayBefore = _getTodayTotalMinutes(mapBefore);

    try {
      ref.read(dailyMinutesMapProvider.notifier).addToToday(addedMinutes);
    } catch (_) {}

    try {
      await ref.read(streakProvider.notifier).onMinutesAdded(
            workedMinutes: addedMinutes,
            todayTotalMinutes: todayBefore + addedMinutes,
            dailyTargetMinutes: ref.watch(dailyTargetProvider),
          );
    } catch (_) {}

    // timer reset
    await ctrl.reset();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Eklendi: $addedMinutes dk ✅')),
    );

    // Show post-focus suggestion if enabled
    await _showPostFocusSuggestionIfEnabled(context, ref);
  }

  Future<void> _showPostFocusSuggestionIfEnabled(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final suggestionsEnabled = ref.read(postFocusSuggestionsEnabledProvider);
    if (!suggestionsEnabled || !mounted) return;

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const PostFocusSuggestionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.size.width > mediaQuery.size.height;

    final timer = ref.watch(focusTimerProvider);
    final ctrl = ref.read(focusTimerProvider.notifier);

    final map = ref.watch(dailyMinutesMapProvider);
    final todayTotal = _getTodayTotalMinutes(map);

    final dailyTarget = ref.watch(dailyTargetProvider);

    final isBreak = timer.isBreak;
    final accentColor = isBreak ? theme.colorScheme.tertiary : theme.colorScheme.primary;

    // Calculate responsive font size for horizontal desk clock style
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final baseFontSize = isLandscape
        ? (screenWidth * 0.15).clamp(80.0, 150.0)
        : (screenWidth * 0.25).clamp(100.0, 180.0);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with mode label and exit button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isBreak ? 'Mola' : 'Odak',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tam ekrandan çık',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.fullscreen_exit_rounded,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            // Main horizontal desk clock display
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return isLandscape
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Large digital timer
                              Text(
                                _format(timer.remainingSeconds),
                                style: TextStyle(
                                  fontSize: baseFontSize,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 4,
                                  height: 1.0,
                                  color: accentColor,
                                  fontFeatures: const [
                                    FontFeature('tnum'), // Tabular figures
                                  ],
                                ),
                              ),
                              const SizedBox(width: 32),
                              // Today's progress (subtle)
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$todayTotal / $dailyTarget dk',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Large digital timer
                              Text(
                                _format(timer.remainingSeconds),
                                style: TextStyle(
                                  fontSize: baseFontSize,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 4,
                                  height: 1.0,
                                  color: accentColor,
                                  fontFeatures: const [
                                    FontFeature('tnum'), // Tabular figures
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Today's progress (subtle)
                              Text(
                                '$todayTotal / $dailyTarget dk',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                  },
                ),
              ),
            ),
            // Controls at bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                          onPressed: _completeEarly,
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
    );
  }
}
