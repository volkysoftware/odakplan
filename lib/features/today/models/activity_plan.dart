class ActivityPlan {
  final String id;
  final String title;
  final int minutes;

  const ActivityPlan({
    required this.id,
    required this.title,
    required this.minutes,
  });

  ActivityPlan copyWith({
    String? id,
    String? title,
    int? minutes,
  }) {
    return ActivityPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      minutes: minutes ?? this.minutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'minutes': minutes,
    };
  }

  factory ActivityPlan.fromMap(Map<dynamic, dynamic> map) {
    return ActivityPlan(
      id: (map['id'] ?? '') as String,
      title: (map['title'] ?? map['name'] ?? '') as String, // eski kayıtlar için name desteği
      minutes: (map['minutes'] ?? 0) as int,
    );
  }
}
