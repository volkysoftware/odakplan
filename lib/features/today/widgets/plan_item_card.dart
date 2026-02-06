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
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withOpacity(0.2)
                : theme.colorScheme.outlineVariant.withOpacity(0.3),
            width: 1,
          ),
          // Subtle elevation for depth
          boxShadow: [
            BoxShadow(
              color: (selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.shadow)
                  .withOpacity(isDark ? 0.15 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // Subtle side indicator for selected state
            if (selected)
              Container(
                width: 3,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            if (selected) const SizedBox(width: 16),
            
            // Icon container
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: selected
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
              ),
              child: Icon(
                selected ? Icons.check_circle_rounded : Icons.play_circle_outline_rounded,
                color: selected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Plan title
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Duration label
                  Text(
                    '$minutes dakika',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selected
                          ? theme.colorScheme.onPrimaryContainer.withOpacity(0.7)
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            // Minutes badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: selected
                    ? theme.colorScheme.primary.withOpacity(0.15)
                    : theme.colorScheme.surfaceContainerHighest,
              ),
              child: Text(
                '$minutes dk',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const [
                    FontFeature('tnum'), // Tabular figures
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
