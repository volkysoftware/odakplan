import 'dart:math';
import 'package:flutter/material.dart';

/// Simple bottom sheet showing a random post-focus suggestion
class PostFocusSuggestionSheet extends StatelessWidget {
  const PostFocusSuggestionSheet({super.key});

  static final List<String> _suggestions = [
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
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suggestion,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tamam'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
