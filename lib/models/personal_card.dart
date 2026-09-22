import 'dart:convert';

import 'card_data.dart';
import '../services/card_parser.dart';

class PersonalCard {
  final CardData data;
  final int theme;
  final String? avatarPath;
  PersonalCard({required this.data, this.theme = 0, this.avatarPath});
  String get qrData => data.toVCard();
  static const maxQrBytes = 1200;
  factory PersonalCard.fromJson(Map<String, dynamic> json) => PersonalCard(
    data: CardData.fromJson(
      Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
    ),
    theme:
        json['theme'] is int &&
            (json['theme'] as int) >= 0 &&
            (json['theme'] as int) < 3
        ? json['theme'] as int
        : 0,
    avatarPath: json['avatarPath'] as String?,
  );
  Map<String, dynamic> toJson() => {
    'data': data.toJson(),
    'theme': theme,
    'avatarPath': avatarPath,
  };
  void validate() {
    if (data.name.trim().isEmpty && data.company.trim().isEmpty) {
      throw const FormatException('Ad soyad veya şirket adı girin.');
    }
    if (data.email.isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(data.email)) {
      throw const FormatException('Geçerli bir e-posta adresi girin.');
    }
    for (final phone in data.phones) {
      if (!RegExp(r'^\+?[\d\s().-]+$').hasMatch(phone) ||
          phoneKey(phone).length < 10 ||
          phoneKey(phone).length > 15) {
        throw const FormatException(
          'Her satıra geçerli bir telefon numarası girin.',
        );
      }
    }
    if (data.phones.length > 3) {
      throw const FormatException('En fazla üç telefon ekleyin.');
    }
    if (utf8.encode(qrData).length > maxQrBytes) {
      throw const FormatException(
        'QR kodun rahat okunabilmesi için bilgileri biraz kısaltın.',
      );
    }
  }
}
