import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odakplan/app/state/selection_state.dart';
import 'package:odakplan/app/state/history_state.dart';
import 'package:odakplan/app/state/streak_state.dart';
import 'package:odakplan/app/state/settings_state.dart';

import 'state/focus_timer_controller.dart';
import 'widgets/session_complete_sheet.dart';

class FocusPage extends ConsumerStatefulWidget {
  const FocusPage({super.key});

  @override
  ConsumerState<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends ConsumerState<FocusPage> {
  late final _planMinutesSub;
  late final _timerFinishSub;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final ctrl = ref.read(focusTimerProvider.notifier);

      // ilk açılışta çalışma modunu hazırla
      await ctrl.applyMode(isBreak: false);

      // seçili plan dakikası varsa uygula
      final initial = ref.read(selectedPlanMinutesProvider);
      if (initial != null && initial > 0) {
        ctrl.setWorkMinutes(initial);
        // setWorkMinutes çalışmıyorken çalışma modunu yeniden uygular
        // (controller içinde zaten var)
      }
    });

    // Plan dakikası değişince Odak süresini güncelle
    _planMinutesSub = ref.listenManual<int?>(
      selectedPlanMinutesProvider,
      (prev, next) {
        if (next == null || next <= 0) return;

        Future.microtask(() {
          if (!mounted) return;
          ref.read(focusTimerProvider.notifier).setWorkMinutes(next);
        });
      },
    );

    // Timer 0’a düşünce (oturum bitince) sheet + dakika ekleme
    _timerFinishSub = ref.listenManual<FocusTimerState>(
      focusTimerProvider,
      (prev, next) {
        if (prev == null) return;

        final isFinishedNow =
            prev.remainingSeconds > 0 &&
            next.remainingSeconds == 0 &&
            !next.isRunning;

        if (isFinishedNow) {
          Future.microtask(() async {
            if (!mounted) return;
            await _onSessionFinished();
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _planMinutesSub?.close();
    _timerFinishSub?.close();
    super.dispose();
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

  // (1) Anlık toplam için: timer çalışırken ekranda canlı dakika ekini göster
  int _liveAddedMinutes(FocusTimerState timer) {
    if (timer.isBreak) return 0;
    if (!timer.isRunning) return 0;
    return timer.workedSeconds ~/ 60; // floor
  }

  // (2) Tamamladım: yarım da olsa bugüne ekle
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
  }

  Future<void> _onSessionFinished() async {
    final timer = ref.read(focusTimerProvider);
    final ctrl = ref.read(focusTimerProvider.notifier);

    final workedMinutes =
        timer.isBreak ? 0 : (timer.sessionTotalSeconds / 60).round();
    final dailyTarget = ref.read(dailyTargetProvider);

    final mapBefore = ref.read(dailyMinutesMapProvider);
    final todayBefore = _getTodayTotalMinutes(mapBefore);

    if (!timer.isBreak && workedMinutes > 0) {
      try {
        ref.read(dailyMinutesMapProvider.notifier).addToToday(workedMinutes);
      } catch (_) {}

      try {
        await ref.read(streakProvider.notifier).onMinutesAdded(
              workedMinutes: workedMinutes,
              todayTotalMinutes: todayBefore + workedMinutes,
              dailyTargetMinutes: dailyTarget,
            );
      } catch (_) {}
    }

    final mapAfter = ref.read(dailyMinutesMapProvider);
    final todayAfter = _getTodayTotalMinutes(mapAfter);

    final streak = ref.read(streakProvider);
    final planName = ref.read(selectedPlanNameProvider);

    if (!mounted) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SessionCompleteSheet(
          isBreak: timer.isBreak,
          sessionMinutes:
              timer.isBreak ? (timer.sessionTotalSeconds / 60).round() : workedMinutes,
          todayTotalMinutes: todayAfter,
          dailyTargetMinutes: dailyTarget,
          currentStreak: streak.current,
          bestStreak: streak.best,
          planName: planName,
        );
      },
    );

    if (!mounted) return;

    if (result == 'continue') {
      await ctrl.applyMode(isBreak: !timer.isBreak);
      await ctrl.start(); // ✅ controller ongoing + finish schedule yönetir
    } else {
      await ctrl.applyMode(isBreak: !timer.isBreak);
    }
  }

  String _format(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final timer = ref.watch(focusTimerProvider);
    final ctrl = ref.read(focusTimerProvider.notifier);

    final map = ref.watch(dailyMinutesMapProvider);
    final todayTotal = _getTodayTotalMinutes(map);

    // ✅ canlı toplam
    final todayTotalLive = todayTotal + _liveAddedMinutes(timer);

    final selectedName = ref.watch(selectedPlanNameProvider);

    final value = timer.sessionTotalSeconds <= 0
        ? 0.0
        : (1 - (timer.remainingSeconds / timer.sessionTotalSeconds)).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Odak',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 26,
              letterSpacing: -.5,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: timer.isBreak ? 'Çalışma moduna geç' : 'Mola moduna geç',
            onPressed: () async {
              await ctrl.applyMode(isBreak: !timer.isBreak);
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: Icon(
                Icons.swap_horiz_rounded,
                key: ValueKey(timer.isBreak),
                color: timer.isBreak
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              color: theme.colorScheme.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: timer.isBreak
                            ? theme.colorScheme.tertiaryContainer
                            : theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        timer.isBreak ? Icons.spa_rounded : Icons.bolt_rounded,
                        color: timer.isBreak
                            ? theme.colorScheme.onTertiaryContainer
                            : theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timer.isBreak ? 'Mola Modu' : 'Çalışma Modu',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedName?.isNotEmpty == true
                                ? 'Plan: $selectedName'
                                : 'Plan seçerek odaklanmayı güçlendir',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.today_rounded,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Text(
                        'Bugün toplam: ',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$todayTotalLive dk',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              color: theme.colorScheme.surface,
            ),
            child: Column(
              children: [
                Text(
                  timer.isBreak ? 'Mola' : 'Odak',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(value: value, strokeWidth: 14),
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: theme.colorScheme.surfaceContainerHighest,
                          border:
                              Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _format(timer.remainingSeconds),
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                timer.isBreak ? 'Mola süresi' : 'Odak süresi',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          if (timer.isRunning) {
                            await ctrl.pause();
                          } else {
                            await ctrl.start();
                          }
                        },
                        icon: Icon(timer.isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded),
                        label: Text(timer.isRunning ? 'Durdur' : 'Başlat'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          await ctrl.reset();
                        },
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('Sıfırla'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _completeEarly,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Tamamladım'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
