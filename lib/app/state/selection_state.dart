import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedPlanIdProvider = StateProvider<String?>((ref) => null);
final selectedPlanNameProvider = StateProvider<String?>((ref) => null);
final selectedPlanMinutesProvider = StateProvider<int?>((ref) => null);
