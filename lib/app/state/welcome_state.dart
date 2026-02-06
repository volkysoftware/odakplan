import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Provider for welcome screen enabled setting
final welcomeEnabledProvider =
    StateNotifierProvider<WelcomeEnabledNotifier, bool>((ref) {
  return WelcomeEnabledNotifier();
});

class WelcomeEnabledNotifier extends StateNotifier<bool> {
  WelcomeEnabledNotifier() : super(true) {
    _load();
  }

  static const _boxName = 'op_settings';
  static const _key = 'welcome_enabled';

  void _load() {
    try {
      final box = Hive.box<dynamic>(_boxName);
      state = box.get(_key, defaultValue: true) as bool? ?? true;
    } catch (_) {
      state = true; // Default to enabled
    }
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    try {
      final box = Hive.box<dynamic>(_boxName);
      await box.put(_key, value);
    } catch (_) {
      // Silently fail if box not available
    }
  }
}

/// Provider to check if welcome screen should be shown
/// Reads directly from Hive each time (no caching) to ensure fresh values
final shouldShowWelcomeProvider = Provider<bool>((ref) {
  final enabled = ref.watch(welcomeEnabledProvider);
  if (!enabled) return false;

  try {
    final box = Hive.box<dynamic>('op_settings');
    final lastShownDate = box.get('welcome_last_shown_date') as String?;
    
    final now = DateTime.now();
    final todayKey = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    // Show if never shown before or last shown date is not today
    return lastShownDate != todayKey;
  } catch (_) {
    // If error, show welcome (safe default)
    return true;
  }
});

/// Helper to mark welcome as shown for today
Future<void> markWelcomeShown() async {
  try {
    final box = Hive.box<dynamic>('op_settings');
    final now = DateTime.now();
    final todayKey = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await box.put('welcome_last_shown_date', todayKey);
  } catch (_) {
    // Silently fail
  }
}
