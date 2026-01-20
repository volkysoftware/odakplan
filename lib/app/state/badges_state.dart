import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class Badge {
  final String id;
  final String title;
  final String description;
  final bool unlocked;

  const Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
  });
}

final badgesProvider = Provider<List<Badge>>((ref) {
  // history box: key 'YYYY-MM-DD' value minutes
  final box = Hive.box<int>('history');

  int totalMinutes = 0;
  int completedDays = 0;

  for (final k in box.keys) {
    final v = box.get(k) ?? 0;
    if (v > 0) completedDays += 1;
    totalMinutes += v;
  }

  final totalHours = totalMinutes / 60.0;

  bool hasMinutes(int m) => totalMinutes >= m;
  bool hasDays(int d) => completedDays >= d;

  return <Badge>[
    Badge(
      id: 'b1',
      title: 'İlk Adım',
      description: 'Toplam 10 dakika odaklan.',
      unlocked: hasMinutes(10),
    ),
    Badge(
      id: 'b2',
      title: 'Isındın',
      description: 'Toplam 60 dakika odaklan (1 saat).',
      unlocked: hasMinutes(60),
    ),
    Badge(
      id: 'b3',
      title: 'Rutin Başladı',
      description: '3 farklı günde çalış.',
      unlocked: hasDays(3),
    ),
    Badge(
      id: 'b4',
      title: 'Disiplinli',
      description: '7 farklı günde çalış.',
      unlocked: hasDays(7),
    ),
    Badge(
      id: 'b5',
      title: 'Maratoncu',
      description: 'Toplam 10 saat odaklan.',
      unlocked: totalHours >= 10,
    ),
    Badge(
      id: 'b6',
      title: 'Usta',
      description: 'Toplam 50 saat odaklan.',
      unlocked: totalHours >= 50,
    ),
  ];
});
