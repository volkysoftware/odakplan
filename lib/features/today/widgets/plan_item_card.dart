import 'package:flutter/material.dart';

class PlanItemCard extends StatelessWidget {
  final String title;
  final int minutes;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const PlanItemCard({
    super.key,
    required this.title,
    required this.minutes,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bg = selected
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surface;

    final border = selected
        ? theme.colorScheme.primary.withOpacity(0.35)
        : theme.colorScheme.outlineVariant;

    final fg = selected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: selected
                    ? theme.colorScheme.primary.withOpacity(0.18)
                    : theme.colorScheme.surfaceContainerHighest,
              ),
              child: Icon(
                selected ? Icons.check_circle_rounded : Icons.play_circle,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hedef: $minutes dk',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: selected
                          ? theme.colorScheme.onPrimaryContainer
                              .withOpacity(0.75)
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: selected
                    ? theme.colorScheme.primary.withOpacity(0.12)
                    : theme.colorScheme.surfaceContainerHighest,
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Text(
                '$minutes dk',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
