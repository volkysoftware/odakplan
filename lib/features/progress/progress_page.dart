// lib/features/progress/progress_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odakplan/app/state/history_state.dart';
import 'package:odakplan/app/state/streak_state.dart';

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Map<String, int>  key: 'yyyy-MM-dd'
    final minutesMap = ref.watch(dailyMinutesMapProvider);
    final streak = ref.watch(streakProvider);

    final now = DateTime.now();
    final days = _lastNDays(now, 7); // eski -> yeni (7 gün)
    final series = days.map((d) => _minutesForDay(minutesMap, d)).toList(growable: false);

    final todayMinutes = series.isNotEmpty ? series.last : 0;
    final weekTotal = series.fold<int>(0, (a, b) => a + b);
    final bestDay = series.isEmpty ? 0 : series.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlerleme'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        children: [
          _SectionTitle(
            title: 'Özet',
            subtitle: 'Son 7 gün performansın',
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
                  icon: Icons.calendar_view_week_rounded,
                  title: 'Son 7 Gün',
                  value: '$weekTotal dk',
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
                  footer: bestDay == 0 ? 'Henüz kayıt yok' : 'Son 7 günde',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _SectionTitle(
            title: 'Grafik',
            subtitle: 'Odak dakikaların (7 gün)',
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
                    labels: days.map(_shortDayLabelTR).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _tipText(series),
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
            subtitle: 'Son 7 gün detay',
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
                    label: _dayBadgeLabelTR(d, isToday: isToday),
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

List<DateTime> _lastNDays(DateTime now, int n) {
  final today = DateTime(now.year, now.month, now.day);
  return List.generate(n, (i) {
    final d = today.subtract(Duration(days: (n - 1) - i));
    return d;
  });
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

String _tipText(List<int> values) {
  final total = values.fold<int>(0, (a, b) => a + b);
  if (total == 0) return 'İpucu: İlk oturumunu başlat, burada grafik hemen dolacak.';
  final best = values.reduce((a, b) => a > b ? a : b);
  return 'İpucu: Bugün 10 dk eklesen, haftalık toplamın ${total + 10} dk olur. En iyi günün: $best dk';
}

String _shortDayLabelTR(DateTime d) {
  const names = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  final idx = (d.weekday - 1).clamp(0, 6);
  return names[idx];
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

String _dayBadgeLabelTR(DateTime d, {required bool isToday}) {
  if (isToday) return 'BUGÜN';
  return _shortDayLabelTR(d).toUpperCase();
}

/* ------------------------ WIDGETS ------------------------ */

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
