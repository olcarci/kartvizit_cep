import 'card_data.dart';
import 'card_reminder.dart';

class ArchivedCard {
  final String id;
  final String imagePath;
  final DateTime createdAt;
  final CardData data;
  final String rawText;
  final String? backImagePath;
  final String backRawText;
  final String notes;
  final List<String> tags;
  final bool isFavorite;
  final CardReminder? reminder;

  const ArchivedCard({
    required this.id,
    required this.imagePath,
    required this.createdAt,
    required this.data,
    this.rawText = '',
    this.backImagePath,
    this.backRawText = '',
    this.notes = '',
    this.tags = const [],
    this.isFavorite = false,
    this.reminder,
  });

  factory ArchivedCard.fromJson(Map<String, dynamic> json) => ArchivedCard(
    id: json['id']?.toString() ?? '',
    imagePath: json['imagePath']?.toString() ?? '',
    createdAt:
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    data: CardData.fromJson(
      Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
    ),
    rawText: json['rawText']?.toString() ?? '',
    backImagePath: json['backImagePath']?.toString(),
    backRawText: json['backRawText']?.toString() ?? '',
    notes: json['notes']?.toString() ?? '',
    tags: (json['tags'] is List ? json['tags'] as List : const [])
        .whereType<String>()
        .toList(),
    isFavorite: json['isFavorite'] == true,
    reminder: json['reminder'] is Map
        ? CardReminder.fromJson(
            Map<String, dynamic>.from(json['reminder'] as Map),
          )
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'imagePath': imagePath,
    'createdAt': createdAt.toIso8601String(),
    'data': data.toJson(),
    'rawText': rawText,
    'backImagePath': backImagePath,
    'backRawText': backRawText,
    'notes': notes,
    'tags': tags,
    'isFavorite': isFavorite,
    'reminder': reminder?.toJson(),
  };

  ArchivedCard copyWith({
    String? imagePath,
    CardData? data,
    String? notes,
    List<String>? tags,
    bool? isFavorite,
    CardReminder? reminder,
    bool clearReminder = false,
    String? backImagePath,
    String? backRawText,
    bool clearBack = false,
  }) => ArchivedCard(
    id: id,
    imagePath: imagePath ?? this.imagePath,
    createdAt: createdAt,
    data: data ?? this.data,
    rawText: rawText,
    backImagePath: clearBack ? null : backImagePath ?? this.backImagePath,
    backRawText: clearBack ? '' : backRawText ?? this.backRawText,
    notes: notes ?? this.notes,
    tags: tags ?? this.tags,
    isFavorite: isFavorite ?? this.isFavorite,
    reminder: clearReminder ? null : reminder ?? this.reminder,
  );

  String get fullRawText => backRawText.isEmpty
      ? rawText
      : 'Ön yüz:\n$rawText\n\nArka yüz:\n$backRawText';
}
