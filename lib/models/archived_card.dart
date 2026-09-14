import 'card_data.dart';

class ArchivedCard {
  final String id;
  final String imagePath;
  final DateTime createdAt;
  final CardData data;
  final String rawText;

  const ArchivedCard({
    required this.id,
    required this.imagePath,
    required this.createdAt,
    required this.data,
    this.rawText = '',
  });

  factory ArchivedCard.fromJson(Map<String, dynamic> json) => ArchivedCard(
    id: json['id']?.toString() ?? '',
    imagePath: json['imagePath']?.toString() ?? '',
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    data: CardData.fromJson(Map<String, dynamic>.from(json['data'] as Map? ?? const {})),
    rawText: json['rawText']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'imagePath': imagePath,
    'createdAt': createdAt.toIso8601String(),
    'data': data.toJson(),
    'rawText': rawText,
  };
}
