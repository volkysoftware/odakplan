import 'package:flutter/material.dart';

class SessionCompleteSheet extends StatelessWidget {
  final bool isBreak;
  final int sessionMinutes;
  final int todayTotalMinutes;
  final int dailyTargetMinutes;
  final int currentStreak;
  final int bestStreak;
  final String? planName;

  const SessionCompleteSheet({
    super.key,
    required this.isBreak,
    required this.sessionMinutes,
    required this.todayTotalMinutes,
    required this.dailyTargetMinutes,
    required this.currentStreak,
    required this.bestStreak,
    required this.planName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = (dailyTargetMinutes - todayTotalMinutes).clamp(0, 999999);
    final completed = todayTotalMinutes >= dailyTargetMinutes && dailyTargetMinutes > 0;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant.withOpacity(.7),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isBreak ? Icons.spa_rounded : Icons.bolt_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBreak ? 'Mola Bitti' : 'Seans Tamamlandı',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isBreak
                            ? 'Harika! Şimdi tekrar odaklanma zamanı.'
                            : 'Eline sağlık! Küçük adımlar büyük sonuçlar.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      _StatTile(
                        label: 'Bu seans',
                        value: '$sessionMinutes dk',
                        icon: Icons.timer_rounded,
                      ),
                      const SizedBox(width: 10),
                      _StatTile(
                        label: 'Bugün toplam',
                        value: '$todayTotalMinutes dk',
                        icon: Icons.today_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatTile(
                        label: 'Hedef',
                        value: '$dailyTargetMinutes dk',
                        icon: Icons.flag_rounded,
                      ),
                      const SizedBox(width: 10),
                      _StatTile(
                        label: completed ? 'Tebrikler!' : 'Kalan',
                        value: completed ? 'Tamamlandı' : '$remaining dk',
                        icon: completed ? Icons.verified_rounded : Icons.trending_up_rounded,
                        accent: completed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Pill(
                          icon: Icons.bookmark_rounded,
                          text: planName?.isNotEmpty == true ? planName! : 'Plan seçilmedi',
                        ),
                        _Pill(
                          icon: Icons.local_fire_department_rounded,
                          text: 'Seri: $currentStreak',
                        ),
                        _Pill(
                          icon: Icons.emoji_events_rounded,
                          text: 'En iyi: $bestStreak',
                        ),
                      ],
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
                    onPressed: () => Navigator.pop(context, 'close'),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Kapat'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, 'continue'),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(isBreak ? 'Odak Başlat' : 'Bir tur daha'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool accent;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = accent ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest;
    final fg = accent ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, color: fg),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: fg,
                    ),
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

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Pill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
