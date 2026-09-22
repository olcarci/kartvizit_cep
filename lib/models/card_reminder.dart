class CardReminder {
  final String title;
  final DateTime dueAt;
  final bool completed;
  final int? notificationId;

  const CardReminder({
    required this.title,
    required this.dueAt,
    this.completed = false,
    this.notificationId,
  });

  factory CardReminder.fromJson(Map<String, dynamic> json) => CardReminder(
    title: json['title']?.toString() ?? '',
    dueAt:
        (DateTime.tryParse(json['dueAt']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0))
            .toLocal(),
    completed: json['completed'] == true,
    notificationId: json['notificationId'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'dueAt': dueAt.toUtc().toIso8601String(),
    'completed': completed,
    'notificationId': notificationId,
  };

  CardReminder withoutNotification({bool? completed}) => CardReminder(
    title: title,
    dueAt: dueAt,
    completed: completed ?? this.completed,
  );
}
