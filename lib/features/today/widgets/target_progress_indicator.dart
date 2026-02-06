import 'package:flutter/material.dart';

/// Small, elegant target-shaped progress indicator
/// Shows progress as a circular target that fills clockwise
class TargetProgressIndicator extends StatelessWidget {
  final double progress;
  final double size;

  const TargetProgressIndicator({
    super.key,
    required this.progress,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clampedProgress = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle (outline)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.25),
                width: 1.5,
              ),
            ),
          ),
          // Progress fill (circular progress)
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: clampedProgress,
              strokeWidth: 1.5,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary.withOpacity(0.4),
              ),
              strokeCap: StrokeCap.round,
            ),
          ),
        ],
      ),
    );
  }
}
