import 'dart:math';
import 'package:flutter/material.dart';

class PostFocusSuggestionSheet extends StatelessWidget {
  const PostFocusSuggestionSheet({super.key});

  static const _suggestions = [
    'Kısa bir mola ver ve ayağa kalk',
    'Bir bardak su iç',
    'Gözlerini 20 saniye dinlendir',
    'Bir sonraki odak için hedefini netleştir',
    'Telefonuna bakmadan 2 dk mola ver',
  ];

  static String _getRandomSuggestion() {
    final random = Random();
    return _suggestions[random.nextInt(_suggestions.length)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestion = _getRandomSuggestion();

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
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.0),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: value,
                    child: child,
                  ),
                );
              },
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.lightbulb_outline_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Öneri',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          suggestion,
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
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Tamam'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
