import 'dart:async';
import 'package:flutter/material.dart';

/// Full-screen ritual overlay shown before starting a focus session.
/// Displays 3 messages sequentially with subtle fade animations.
class FocusStartRitual extends StatefulWidget {
  const FocusStartRitual({
    super.key,
    required this.onComplete,
    this.onSkip,
  });

  final VoidCallback onComplete;
  final VoidCallback? onSkip;

  @override
  State<FocusStartRitual> createState() => _FocusStartRitualState();
}

class _FocusStartRitualState extends State<FocusStartRitual>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentIndex = 0;
  Timer? _sequenceTimer;
  final List<String> _messages = [
    'Derin bir nefes al',
    'Dikkatini tek hedefe ver',
    'Hazırsın',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _startSequence();
  }

  void _startSequence() {
    if (_currentIndex >= _messages.length) {
      widget.onComplete();
      return;
    }

    // Fade in current message
    _controller.forward().then((_) {
      if (!mounted) return;
      
      // Hold for ~1 second, then fade out and move to next
      _sequenceTimer?.cancel();
      _sequenceTimer = Timer(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        
        _controller.reverse().then((_) {
          if (!mounted) return;
          
          // Move to next message
          setState(() {
            _currentIndex++;
          });
          
          if (_currentIndex < _messages.length) {
            _controller.reset();
            _startSequence();
          } else {
            // All messages shown, complete
            widget.onComplete();
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _sequenceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _skip() {
    _sequenceTimer?.cancel();
    _controller.stop();
    if (widget.onSkip != null) {
      widget.onSkip!();
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFF1A1A1A),
      child: Stack(
        children: [
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _messages[_currentIndex],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: TextButton(
              onPressed: _skip,
              child: Text(
                'Geç',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
