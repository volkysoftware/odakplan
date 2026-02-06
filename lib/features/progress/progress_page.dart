// lib/features/progress/progress_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odakplan/app/state/history_state.dart';
import 'package:odakplan/app/state/streak_state.dart';
import 'state/progress_period_controller.dart';
import 'state/focus_score_provider.dart';

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Map<String, int>  key: 'yyyy-MM-dd'
    final minutesMap = ref.watch(dailyMinutesMapProvider);
    final streak = ref.watch(streakProvider);
    final periodState = ref.watch(progressPeriodProvider);

    final now = DateTime.now();
    final days = _getDaysForPeriod(periodState.period, periodState.anchorDate);
    final series = days.map((d) => _minutesForDay(minutesMap, d)).toList(growable: false);

    final todayMinutes = _isSameDay(now, days.isNotEmpty ? days.last : now) && series.isNotEmpty
        ? series.last
        : 0;
    final periodTotal = series.fold<int>(0, (a, b) => a + b);
    final bestDay = series.isEmpty ? 0 : series.reduce((a, b) => a > b ? a : b);

    final isWeek = periodState.period == ProgressPeriod.week;
    final periodLabel = isWeek ? 'Hafta' : 'Ay';
    final periodSubtitle = isWeek ? 'Son 7 gün performansın' : 'Bu ay performansın';

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlerleme'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        children: [
          // Period selector
          _PeriodSelector(
            selectedPeriod: periodState.period,
            onPeriodChanged: (period) {
              ref.read(progressPeriodProvider.notifier).setPeriod(period);
            },
          ),
          const SizedBox(height: 16),
          _SectionTitle(
            title: 'Özet',
            subtitle: periodSubtitle,
          ),
          const SizedBox(height: 10),

          // KPI Row 1
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  icon: Icons.today_rounded,
                  title: 'Bugün',
                  value: '$todayMinutes dk',
                  tone: _KpiTone.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiCard(
                  icon: isWeek ? Icons.calendar_view_week_rounded : Icons.calendar_month_rounded,
                  title: isWeek ? 'Bu Hafta' : 'Bu Ay',
                  value: '$periodTotal dk',
                  tone: _KpiTone.neutral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // KPI Row 2
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  icon: Icons.local_fire_department_rounded,
                  title: 'Seri',
                  value: '${streak.current} gün',
                  tone: _KpiTone.tertiary,
                  footer: 'En iyi: ${streak.best}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiCard(
                  icon: Icons.emoji_events_rounded,
                  title: 'En iyi gün',
                  value: '$bestDay dk',
                  tone: _KpiTone.neutral,
                  footer: bestDay == 0
                      ? 'Henüz kayıt yok'
                      : (isWeek ? 'Bu haftada' : 'Bu ayda'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // Focus Score Card (Week view required, Month view optional if data exists)
          if (isWeek || (periodTotal > 0)) ...[
            _FocusScoreCard(isWeek: isWeek),
            const SizedBox(height: 16),
          ],
          _SectionTitle(
            title: 'Grafik',
            subtitle: 'Odak dakikaların ($periodLabel)',
          ),
          const SizedBox(height: 10),

          // Chart Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(theme),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ChartLegend(
                  left: 'Düşük',
                  right: 'Yüksek',
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 180,
                  child: _BarChart(
                    values: series,
                    labels: days.map((d) => _getDayLabel(d, isWeek)).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _tipText(series, isWeek),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _SectionTitle(
            title: 'Gün Gün',
            subtitle: isWeek ? 'Bu hafta detay' : 'Bu ay detay',
          ),
          const SizedBox(height: 10),

          // Daily list
          ...List.generate(days.length, (i) {
            final d = days[i];
            final m = series[i];
            final isToday = _isSameDay(d, now);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: _cardDecoration(theme),
                child: ListTile(
                  leading: _DayBadge(
                    label: _dayBadgeLabelTR(d, isToday: isToday, isWeek: isWeek),
                    tone: isToday ? _BadgeTone.primary : _BadgeTone.neutral,
                  ),
                  title: Text(
                    _fullDayLabelTR(d, isToday: isToday),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: Text(
                    isToday ? 'Bugünkü toplam' : 'Günün toplamı',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: _MinuteChip(minutes: m),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/* ------------------------ DATA HELPERS ------------------------ */

List<DateTime> _getDaysForPeriod(ProgressPeriod period, DateTime anchorDate) {
  if (period == ProgressPeriod.week) {
    return _getWeekDays(anchorDate);
  } else {
    return _getMonthDays(anchorDate);
  }
}

DateTime _startOfWeek(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  final weekday = d.weekday; // 1 = Monday, 7 = Sunday
  return d.subtract(Duration(days: weekday - 1));
}

List<DateTime> _getWeekDays(DateTime anchorDate) {
  final start = _startOfWeek(anchorDate);
  return List.generate(7, (i) => start.add(Duration(days: i)));
}

DateTime _startOfMonth(DateTime date) {
  return DateTime(date.year, date.month, 1);
}

DateTime _endOfMonth(DateTime date) {
  return DateTime(date.year, date.month + 1, 0);
}

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

int _minutesForDay(Map<String, int> map, DateTime d) {
  final k = _keyDash(d); // history_state.dart artık bu formatta yazıyor
  return map[k] ?? 0;
}

String _keyDash(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/* ------------------------ UI HELPERS ------------------------ */

BoxDecoration _cardDecoration(ThemeData theme) {
  return BoxDecoration(
    color: theme.colorScheme.surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: theme.colorScheme.outlineVariant),
  );
}

String _tipText(List<int> values, bool isWeek) {
  final total = values.fold<int>(0, (a, b) => a + b);
  if (total == 0) return 'İpucu: İlk oturumunu başlat, burada grafik hemen dolacak.';
  final best = values.reduce((a, b) => a > b ? a : b);
  final periodLabel = isWeek ? 'haftalık' : 'aylık';
  return 'İpucu: Bugün 10 dk eklesen, $periodLabel toplamın ${total + 10} dk olur. En iyi günün: $best dk';
}

String _getDayLabel(DateTime d, bool isWeek) {
  if (isWeek) {
    const names = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final idx = (d.weekday - 1).clamp(0, 6);
    return names[idx];
  } else {
    // For month view, show day number
    return d.day.toString();
  }
}

String _fullDayLabelTR(DateTime d, {required bool isToday}) {
  const names = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar'
  ];
  final name = names[(d.weekday - 1).clamp(0, 6)];
  final date = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  return isToday ? 'Bugün • $date' : '$name • $date';
}

String _dayBadgeLabelTR(DateTime d, {required bool isToday, required bool isWeek}) {
  if (isToday) return 'BUGÜN';
  if (isWeek) {
    const names = ['PZT', 'SAL', 'ÇAR', 'PER', 'CUM', 'CMT', 'PAZ'];
    final idx = (d.weekday - 1).clamp(0, 6);
    return names[idx];
  } else {
    return d.day.toString();
  }
}

/* ------------------------ WIDGETS ------------------------ */

class _FocusScoreCard extends ConsumerWidget {
  final bool isWeek;

  const _FocusScoreCard({required this.isWeek});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final score = isWeek
        ? ref.watch(weeklyFocusScoreProvider)
        : ref.watch(monthlyFocusScoreProvider);
    
    final minutesMap = ref.watch(dailyMinutesMapProvider);
    final periodState = ref.watch(progressPeriodProvider);
    
    // Check if there's any data for this period
    final days = isWeek
        ? _getWeekDays(periodState.anchorDate)
        : _getMonthDays(periodState.anchorDate);
    final hasData = days.any((d) => _minutesForDay(minutesMap, d) > 0);
    
    final periodLabel = isWeek ? 'Bu hafta' : 'Bu ay';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Odak Skoru',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      periodLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasData)
                Text(
                  '$score',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    height: 1.0,
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '0',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Henüz veri yok',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final ProgressPeriod selectedPeriod;
  final ValueChanged<ProgressPeriod> onPeriodChanged;

  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWeek = selectedPeriod == ProgressPeriod.week;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PeriodButton(
              label: 'Hafta',
              isSelected: isWeek,
              onTap: () => onPeriodChanged(ProgressPeriod.week),
            ),
          ),
          Expanded(
            child: _PeriodButton(
              label: 'Ay',
              isSelected: !isWeek,
              onTap: () => onPeriodChanged(ProgressPeriod.month),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.surface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _KpiTone { primary, tertiary, neutral }

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final _KpiTone tone;
  final String? footer;

  const _KpiCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.tone,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bg;
    Color fg;
    switch (tone) {
      case _KpiTone.primary:
        bg = theme.colorScheme.primaryContainer;
        fg = theme.colorScheme.onPrimaryContainer;
        break;
      case _KpiTone.tertiary:
        bg = theme.colorScheme.tertiaryContainer;
        fg = theme.colorScheme.onTertiaryContainer;
        break;
      case _KpiTone.neutral:
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurface;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (footer != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    footer!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final String left;
  final String right;

  const _ChartLegend({
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          left,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          right,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<int> values;
  final List<String> labels;

  const _BarChart({
    required this.values,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      painter: _BarChartPainter(
        values: values,
        labels: labels,
        theme: theme,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<int> values;
  final List<String> labels;
  final ThemeData theme;

  _BarChartPainter({
    required this.values,
    required this.labels,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxV = values.reduce((a, b) => a > b ? a : b);
    final safeMax = (maxV <= 0) ? 1 : maxV;

    final paddingTop = 10.0;
    final paddingBottom = 24.0;
    final paddingSide = 6.0;

    final chartH = size.height - paddingTop - paddingBottom;
    final chartW = size.width - paddingSide * 2;

    final n = values.length;
    final gap = 10.0;
    final barW = (chartW - gap * (n - 1)) / n;

    final barPaint = Paint()..style = PaintingStyle.fill;

    final basePaint = Paint()
      ..color = theme.colorScheme.outlineVariant
      ..strokeWidth = 1;

    final baseY = paddingTop + chartH;
    canvas.drawLine(
      Offset(paddingSide, baseY),
      Offset(paddingSide + chartW, baseY),
      basePaint,
    );

    final textStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < n; i++) {
      final v = values[i];
      final ratio = (v / safeMax).clamp(0.0, 1.0);
      final barH = chartH * ratio;

      final x = paddingSide + i * (barW + gap);
      final y = paddingTop + chartH - barH;

      final isBest = v == maxV && maxV > 0;

      final topColor = isBest
          ? theme.colorScheme.primary
          : theme.colorScheme.primary.withOpacity(0.75);
      final bottomColor = isBest
          ? theme.colorScheme.primary.withOpacity(0.65)
          : theme.colorScheme.primary.withOpacity(0.45);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barW, barH),
        const Radius.circular(12),
      );

      final shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topColor, bottomColor],
      ).createShader(Rect.fromLTWH(x, y, barW, barH));

      barPaint.shader = shader;
      canvas.drawRRect(rect, barPaint);

      final label = (i < labels.length) ? labels[i] : '';
      textPainter.text = TextSpan(text: label, style: textStyle);
      textPainter.layout(maxWidth: barW + gap);
      textPainter.paint(
        canvas,
        Offset(x + (barW - textPainter.width) / 2, size.height - 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.labels != labels;
  }
}

enum _BadgeTone { primary, neutral }

class _DayBadge extends StatelessWidget {
  final String label;
  final _BadgeTone tone;

  const _DayBadge({
    required this.label,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color bg = tone == _BadgeTone.primary
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;

    final Color fg = tone == _BadgeTone.primary
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return Container(
      width: 58,
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Center(
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: fg,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _MinuteChip extends StatelessWidget {
  final int minutes;

  const _MinuteChip({required this.minutes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool zero = minutes <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: zero
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        '$minutes dk',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: zero
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
