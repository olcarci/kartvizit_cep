import 'dart:convert';
import 'dart:typed_data';

import '../models/archived_card.dart';
import '../models/personal_card.dart';

class BackupEntry {
  final ArchivedCard card;
  final Uint8List? image;
  final Uint8List? backImage;
  BackupEntry(this.card, this.image, {this.backImage});
}

class BackupBundle {
  static const maxBytes = 64 * 1024 * 1024;
  static const maxImageBytes = 12 * 1024 * 1024;
  static const maxCards = 2000;
  final List<BackupEntry> entries;
  final PersonalCard? personalCard;
  final Uint8List? personalAvatar;
  BackupBundle(this.entries, {this.personalCard, this.personalAvatar});
  int get missingImages => entries.fold<int>(
    0,
    (count, entry) =>
        count +
        (entry.image == null ? 1 : 0) +
        (entry.card.backImagePath != null && entry.backImage == null ? 1 : 0),
  );
  int get missingPersonalAvatar =>
      personalCard?.avatarPath != null && personalAvatar == null ? 1 : 0;

  Uint8List encode() {
    final bytes = utf8.encode(
      jsonEncode({
        'format': 'kartvizit_cep_backup',
        'version': 2,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'personalCard': personalCard == null
            ? null
            : {
                ...personalCard!.toJson(),
                'avatarPath': personalCard!.avatarPath == null
                    ? null
                    : 'avatar.jpg',
              },
        'personalAvatar': personalAvatar == null
            ? null
            : base64Encode(personalAvatar!),
        'cards': entries
            .map(
              (entry) => {
                'card': {
                  ...entry.card.toJson(),
                  'imagePath': 'card.jpg',
                  'backImagePath': entry.card.backImagePath == null
                      ? null
                      : 'back.jpg',
                  'reminder': entry.card.reminder
                      ?.withoutNotification()
                      .toJson(),
                },
                'image': entry.image == null
                    ? null
                    : base64Encode(entry.image!),
                'backImage': entry.backImage == null
                    ? null
                    : base64Encode(entry.backImage!),
              },
            )
            .toList(),
      }),
    );
    if (bytes.length > maxBytes) {
      throw const FormatException('Yedek 64 MB sınırını aşıyor.');
    }
    return Uint8List.fromList(bytes);
  }

  static BackupBundle decode(Uint8List bytes) {
    if (bytes.length > maxBytes) {
      throw const FormatException('Yedek 64 MB sınırını aşıyor.');
    }
    try {
      final root = jsonDecode(utf8.decode(bytes));
      if (root is! Map ||
          root['format'] != 'kartvizit_cep_backup' ||
          ![1, 2].contains(root['version'])) {
        throw const FormatException(
          'Bu dosya desteklenen bir Kartvizit Cep yedeği değil.',
        );
      }
      final rows = root['cards'];
      if (rows is! List || rows.length > maxCards) {
        throw const FormatException('Geçersiz kart listesi.');
      }
      final ids = <String>{};
      final entries = <BackupEntry>[];
      for (final row in rows) {
        if (row is! Map || row['card'] is! Map) {
          throw const FormatException('Geçersiz kart.');
        }
        final json = Map<String, dynamic>.from(row['card'] as Map);
        if (json['id'] is! String ||
            (json['id'] as String).isEmpty ||
            !ids.add(json['id'] as String) ||
            json['createdAt'] is! String ||
            DateTime.tryParse(json['createdAt'] as String) == null ||
            json['data'] is! Map) {
          throw const FormatException('Kart kimliği veya tarihi geçersiz.');
        }
        for (final key in [
          'rawText',
          'notes',
          'backRawText',
          'backImagePath',
        ]) {
          if (json[key] != null && json[key] is! String) {
            throw const FormatException('Geçersiz metin alanı.');
          }
        }
        if (json['isFavorite'] != null && json['isFavorite'] is! bool) {
          throw const FormatException('Geçersiz favori alanı.');
        }
        if (json['tags'] != null &&
            (json['tags'] is! List ||
                (json['tags'] as List).any((tag) => tag is! String))) {
          throw const FormatException('Geçersiz etiketler.');
        }
        final data = json['data'] as Map;
        for (final key in [
          'name',
          'company',
          'title',
          'email',
          'website',
          'address',
        ]) {
          if (data[key] != null && data[key] is! String) {
            throw const FormatException('Geçersiz kişi bilgileri.');
          }
        }
        if (data['phones'] != null &&
            (data['phones'] is! List ||
                (data['phones'] as List).any((phone) => phone is! String))) {
          throw const FormatException('Geçersiz telefonlar.');
        }
        final card = ArchivedCard.fromJson(json);
        final encoded = row['image'];
        if (encoded != null && encoded is! String) {
          throw const FormatException('Geçersiz fotoğraf.');
        }
        if (encoded is String && encoded.length > maxImageBytes * 4 ~/ 3 + 4) {
          throw const FormatException('Kart fotoğrafı 12 MB sınırını aşıyor.');
        }
        final image = encoded == null ? null : base64Decode(encoded as String);
        if (image != null && (image.isEmpty || image.length > maxImageBytes)) {
          throw const FormatException('Geçersiz fotoğraf boyutu.');
        }
        final backEncoded = row['backImage'];
        if (backEncoded != null &&
            (backEncoded is! String ||
                backEncoded.length > maxImageBytes * 4 ~/ 3 + 4)) {
          throw const FormatException('Geçersiz arka yüz fotoğrafı.');
        }
        final backImage = backEncoded == null
            ? null
            : base64Decode(backEncoded as String);
        if (backImage != null &&
            (backImage.isEmpty ||
                backImage.length > maxImageBytes ||
                card.backImagePath == null)) {
          throw const FormatException('Geçersiz arka yüz fotoğrafı.');
        }
        entries.add(
          BackupEntry(
            card.copyWith(reminder: card.reminder?.withoutNotification()),
            image,
            backImage: backImage,
          ),
        );
      }
      PersonalCard? personal;
      if (root['personalCard'] != null) {
        personal = PersonalCard.fromJson(
          Map<String, dynamic>.from(root['personalCard'] as Map),
        );
        personal.validate();
      }
      final avatarEncoded = root['personalAvatar'];
      if (avatarEncoded != null &&
          (avatarEncoded is! String ||
              avatarEncoded.length > maxImageBytes * 4 ~/ 3 + 4)) {
        throw const FormatException('Geçersiz kişisel kart fotoğrafı.');
      }
      final avatar = avatarEncoded == null
          ? null
          : base64Decode(avatarEncoded as String);
      if (avatar != null &&
          (avatar.isEmpty ||
              avatar.length > maxImageBytes ||
              personal?.avatarPath == null)) {
        throw const FormatException('Geçersiz kişisel kart fotoğrafı.');
      }
      return BackupBundle(
        entries,
        personalCard: personal,
        personalAvatar: avatar,
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Yedek dosyasının içeriği geçersiz.');
    }
  }
}

class RestoreResult {
  final int added;
  final int skipped;
  final String? personalStatus;
  const RestoreResult(this.added, this.skipped, {this.personalStatus});
}
