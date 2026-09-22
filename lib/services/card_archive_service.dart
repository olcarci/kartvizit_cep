import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../models/archived_card.dart';
import '../models/card_data.dart';
import '../models/card_reminder.dart';
import 'backup_codec.dart';
import 'card_scan_service.dart';
import 'personal_card_service.dart';

class CardArchiveService {
  final Future<Directory> Function() _directoryProvider;
  static Future<void> _writes = Future.value();
  CardArchiveService({Future<Directory> Function()? directoryProvider})
    : _directoryProvider =
          directoryProvider ?? getApplicationDocumentsDirectory;

  Future<T> _exclusive<T>(Future<T> Function() operation) {
    final result = _writes.then((_) => operation());
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  String _join(String first, String second) =>
      '$first${Platform.pathSeparator}$second';
  String _basename(String path) => path.replaceAll('\\', '/').split('/').last;
  Future<Directory> _archiveDirectory() async {
    final root = await _directoryProvider();
    return Directory(_join(root.path, 'kartvizit_arsivi'))
        .create(recursive: true);
  }

  Future<File> _indexFile() async =>
      File(_join((await _archiveDirectory()).path, 'kartvizitler.json'));

  Future<List<ArchivedCard>> loadCards() async {
    final file = await _indexFile();
    if (!await file.exists()) return [];
    // Do not silently replace a damaged archive with an empty collection.
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! List) {
      throw const FormatException('Kartvizit arşivi okunamadı.');
    }
    final directory = await _archiveDirectory();
    final cards = <ArchivedCard>[];
    final ids = <String>{};
    for (final value in decoded) {
      if (value is! Map) throw const FormatException('Geçersiz arşiv kaydı.');
      final card = ArchivedCard.fromJson(Map<String, dynamic>.from(value));
      final filename = _basename(card.imagePath);
      if (card.id.isEmpty ||
          filename.isEmpty ||
          filename == '.' ||
          filename == '..' ||
          !ids.add(card.id)) {
        throw const FormatException('Geçersiz arşiv kaydı.');
      }
      final back = card.backImagePath == null
          ? null
          : _basename(card.backImagePath!);
      if (back != null && (back.isEmpty || back == '.' || back == '..')) {
        throw const FormatException('Geçersiz arka yüz kaydı.');
      }
      cards.add(
        card.copyWith(
          imagePath: _join(directory.path, filename),
          backImagePath: back == null ? null : _join(directory.path, back),
        ),
      );
    }
    cards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return cards;
  }

  Future<ArchivedCard> saveScan({
    required String sourceImagePath,
    required CardData data,
    String rawText = '',
  }) => _exclusive(() async {
    final cards = await loadCards();
    final source = File(sourceImagePath);
    if (!await source.exists()) {
      throw FileSystemException(
        'Kartvizit görüntüsü bulunamadı.',
        sourceImagePath,
      );
    }
    final now = DateTime.now();
    var id = now.microsecondsSinceEpoch.toString();
    while (cards.any((card) => card.id == id)) {
      id = '${id}_1';
    }
    final lower = sourceImagePath.toLowerCase();
    final extension = lower.endsWith('.png')
        ? 'png'
        : lower.endsWith('.heic')
        ? 'heic'
        : 'jpg';
    final directory = await _archiveDirectory();
    final image = await source.copy(
      _join(directory.path, 'kartvizit_$id.$extension'),
    );
    final card = ArchivedCard(
      id: id,
      imagePath: image.path,
      createdAt: now,
      data: data,
      rawText: rawText,
    );
    try {
      await _writeCards([card, ...cards]);
    } catch (_) {
      await image.delete();
      rethrow;
    }
    return card;
  });

  Future<void> deleteCard(ArchivedCard card) => _exclusive(() async {
    final cards = await loadCards();
    final current = cards.where((item) => item.id == card.id).firstOrNull;
    if (current == null) return;
    cards.removeWhere((item) => item.id == card.id);
    await _writeCards(cards);
    for (final path in [
      current.imagePath,
      if (current.backImagePath != null) current.backImagePath!,
    ]) {
      final image = File(path);
      try {
        if (await image.exists()) await image.delete();
      } on FileSystemException {
        /* Best effort. */
      }
    }
  });

  Future<ArchivedCard> attachBack(
    String id,
    ScanDraft draft, {
    CardData? reviewedData,
  }) => _exclusive(() async {
    final cards = await loadCards();
    final index = cards.indexWhere((card) => card.id == id);
    if (index < 0) throw StateError('Kartvizit bulunamadı.');
    final current = cards[index];
    final directory = await _archiveDirectory();
    final source = File(draft.imagePath);
    final image = await source.copy(
      _join(
        directory.path,
        'back_${DateTime.now().microsecondsSinceEpoch}.jpg',
      ),
    );
    final updated = current.copyWith(
      backImagePath: image.path,
      backRawText: draft.rawText,
      data:
          reviewedData ?? CardScanService.supplement(current.data, draft.data),
    );
    cards[index] = updated;
    try {
      await _writeCards(cards);
    } catch (_) {
      await image.delete();
      rethrow;
    }
    if (current.backImagePath != null) {
      try {
        await File(current.backImagePath!).delete();
      } on FileSystemException {
        /* Missing image. */
      }
    }
    return updated;
  });

  Future<ArchivedCard> removeBack(String id) => _exclusive(() async {
    final cards = await loadCards();
    final index = cards.indexWhere((card) => card.id == id);
    if (index < 0) throw StateError('Kartvizit bulunamadı.');
    final path = cards[index].backImagePath;
    cards[index] = cards[index].copyWith(clearBack: true);
    await _writeCards(cards);
    if (path != null) {
      try {
        await File(path).delete();
      } on FileSystemException {
        /* Missing image. */
      }
    }
    return cards[index];
  });

  Future<void> updateCardData(String id, CardData data) async {
    await _update(id, (card) => card.copyWith(data: data));
  }

  Future<ArchivedCard> updateOrganization(
    String id, {
    String? notes,
    List<String>? tags,
    bool? isFavorite,
  }) => _update(
    id,
    (card) => card.copyWith(
      notes: notes,
      tags: tags
          ?.map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .toList(),
      isFavorite: isFavorite,
    ),
  );

  Future<ArchivedCard> updateReminder(String id, CardReminder? reminder) =>
      _update(
        id,
        (card) =>
            card.copyWith(reminder: reminder, clearReminder: reminder == null),
      );

  Future<ArchivedCard> _update(
    String id,
    ArchivedCard Function(ArchivedCard) change,
  ) => _exclusive(() async {
    final cards = await loadCards();
    final index = cards.indexWhere((card) => card.id == id);
    if (index < 0) throw StateError('Kartvizit bulunamadı.');
    cards[index] = change(cards[index]);
    await _writeCards(cards);
    return cards[index];
  });

  Future<BackupBundle> createBackup() => _exclusive(() async {
    final cards = await loadCards();
    if (cards.length > BackupBundle.maxCards) {
      throw const FormatException('Bir yedekte en fazla 2000 kart olabilir.');
    }
    final entries = <BackupEntry>[];
    var estimatedSize = 1024;
    for (final card in cards) {
      final file = File(card.imagePath);
      Uint8List? image;
      if (await file.exists()) {
        final size = await file.length();
        if (size > BackupBundle.maxImageBytes) {
          throw const FormatException('Kart fotoğrafı 12 MB sınırını aşıyor.');
        }
        estimatedSize += ((size + 2) ~/ 3) * 4;
        if (estimatedSize > BackupBundle.maxBytes) {
          throw const FormatException('Yedek 64 MB sınırını aşıyor.');
        }
        image = await file.readAsBytes();
      }
      estimatedSize += utf8.encode(jsonEncode(card.toJson())).length + 100;
      if (estimatedSize > BackupBundle.maxBytes) {
        throw const FormatException('Yedek 64 MB sınırını aşıyor.');
      }
      Uint8List? backImage;
      if (card.backImagePath != null &&
          await File(card.backImagePath!).exists()) {
        final backFile = File(card.backImagePath!);
        final size = await backFile.length();
        if (size > BackupBundle.maxImageBytes) {
          throw const FormatException(
            'Arka yüz fotoğrafı 12 MB sınırını aşıyor.',
          );
        }
        estimatedSize += ((size + 2) ~/ 3) * 4;
        if (estimatedSize > BackupBundle.maxBytes) {
          throw const FormatException('Yedek 64 MB sınırını aşıyor.');
        }
        backImage = await backFile.readAsBytes();
      }
      entries.add(BackupEntry(card, image, backImage: backImage));
    }
    final personal = await PersonalCardService(
      directoryProvider: _directoryProvider,
    ).load();
    Uint8List? avatar;
    if (personal?.avatarPath != null &&
        await File(personal!.avatarPath!).exists()) {
      final file = File(personal.avatarPath!);
      final size = await file.length();
      if (size > BackupBundle.maxImageBytes) {
        throw const FormatException(
          'Kişisel kart fotoğrafı 12 MB sınırını aşıyor.',
        );
      }
      estimatedSize += ((size + 2) ~/ 3) * 4;
      if (estimatedSize > BackupBundle.maxBytes) {
        throw const FormatException('Yedek 64 MB sınırını aşıyor.');
      }
      avatar = await file.readAsBytes();
    }
    return BackupBundle(
      entries,
      personalCard: personal,
      personalAvatar: avatar,
    );
  });

  static Future<BackupBundle> readBackup(Uint8List bytes) =>
      Isolate.run(() => BackupBundle.decode(bytes));

  Future<RestoreResult> restoreBackup(BackupBundle bundle) =>
      _exclusive(() async {
        final cards = await loadCards();
        final existing = cards.map((card) => card.id).toSet();
        final directory = await _archiveDirectory();
        final created = <File>[];
        var skipped = 0;
        var added = 0;
        final stamp = DateTime.now().microsecondsSinceEpoch;
        try {
          for (final entry in bundle.entries) {
            if (!existing.add(entry.card.id)) {
              skipped++;
              continue;
            }
            // Imported paths and IDs never become local filesystem paths.
            var file = File(
              _join(directory.path, 'restored_${stamp}_$added.jpg'),
            );
            var suffix = 0;
            while (await file.exists()) {
              suffix++;
              file = File(
                _join(directory.path, 'restored_${stamp}_${added}_$suffix.jpg'),
              );
            }
            if (entry.image != null) {
              created.add(file);
              await file.writeAsBytes(entry.image!, flush: true);
            }
            File? backFile;
            if (entry.card.backImagePath != null) {
              backFile = File('${file.path}.back.jpg');
              if (entry.backImage != null) {
                created.add(backFile);
                await backFile.writeAsBytes(entry.backImage!, flush: true);
              }
            }
            cards.add(
              ArchivedCard(
                id: entry.card.id,
                imagePath: entry.image != null ? file.path : '',
                createdAt: entry.card.createdAt,
                data: entry.card.data,
                rawText: entry.card.rawText,
                backImagePath: entry.backImage != null ? backFile?.path : null,
                backRawText: entry.card.backRawText,
                notes: entry.card.notes,
                tags: entry.card.tags,
                isFavorite: entry.card.isFavorite,
                reminder: entry.card.reminder?.withoutNotification(),
              ),
            );
            added++;
          }
          if (added > 0) await _writeCards(cards);
        } catch (_) {
          for (final file in created) {
            try {
              if (await file.exists()) await file.delete();
            } on FileSystemException {
              /* Best effort. */
            }
          }
          rethrow;
        }
        String? personalStatus;
        if (bundle.personalCard != null) {
          try {
            final restored = await PersonalCardService(
              directoryProvider: _directoryProvider,
            ).restoreIfAbsent(bundle.personalCard!, bundle.personalAvatar);
            personalStatus = restored
                ? 'Kişisel kartvizitiniz de yüklendi.'
                : 'Mevcut kişisel kartvizitiniz korundu.';
          } catch (_) {
            personalStatus = 'Arşiv kartları işlendi; kişisel kartvizit yüklenemedi. Yedeği tekrar yüklemeyi deneyin.';
          }
        }
        return RestoreResult(added, skipped, personalStatus: personalStatus);
      });

  Future<void> _writeCards(List<ArchivedCard> cards) async {
    final file = await _indexFile();
    final serializable = cards
        .map(
          (card) => {
            ...card.toJson(),
            'imagePath': _basename(card.imagePath),
            'backImagePath': card.backImagePath == null
                ? null
                : _basename(card.backImagePath!),
          },
        )
        .toList();
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(serializable), flush: true);
    await temporary.rename(file.path);
  }
}
