import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/archived_card.dart';
import '../models/card_data.dart';

class CardArchiveService {
  final Future<Directory> Function() _directoryProvider;

  CardArchiveService({Future<Directory> Function()? directoryProvider})
      : _directoryProvider = directoryProvider ?? getApplicationDocumentsDirectory;

  String _join(String first, String second) =>
      '$first${Platform.pathSeparator}$second';

  Future<Directory> _archiveDirectory() async {
    final root = await _directoryProvider();
    final directory = Directory(_join(root.path, 'kartvizit_arsivi'));
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<File> _indexFile() async =>
      File(_join((await _archiveDirectory()).path, 'kartvizitler.json'));

  Future<List<ArchivedCard>> loadCards() async {
    final file = await _indexFile();
    if (!await file.exists()) return [];
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return [];
      final cards = decoded
          .whereType<Map>()
          .map((value) => ArchivedCard.fromJson(Map<String, dynamic>.from(value)))
          .where((card) => card.id.isNotEmpty && card.imagePath.isNotEmpty)
          .toList();
      cards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return cards;
    } catch (_) {
      return [];
    }
  }

  Future<ArchivedCard> saveScan({
    required String sourceImagePath,
    required CardData data,
    String rawText = '',
  }) async {
    final source = File(sourceImagePath);
    if (!await source.exists()) throw FileSystemException('Kartvizit görüntüsü bulunamadı.', sourceImagePath);
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final lower = sourceImagePath.toLowerCase();
    final extension = lower.endsWith('.png') ? 'png' : lower.endsWith('.heic') ? 'heic' : 'jpg';
    final directory = await _archiveDirectory();
    final savedImage = await source.copy(_join(directory.path, 'kartvizit_$id.$extension'));
    final card = ArchivedCard(
      id: id,
      imagePath: savedImage.path,
      createdAt: now,
      data: data,
      rawText: rawText,
    );
    final cards = await loadCards();
    cards.insert(0, card);
    await _writeCards(cards);
    return card;
  }

  Future<void> deleteCard(ArchivedCard card) async {
    final cards = await loadCards();
    cards.removeWhere((item) => item.id == card.id);
    await _writeCards(cards);
    final image = File(card.imagePath);
    if (await image.exists()) await image.delete();
  }

  Future<void> updateCardData(String id, CardData data) async {
    final cards = await loadCards();
    final index = cards.indexWhere((card) => card.id == id);
    if (index < 0) return;
    final current = cards[index];
    cards[index] = ArchivedCard(
      id: current.id,
      imagePath: current.imagePath,
      createdAt: current.createdAt,
      data: data,
      rawText: current.rawText,
    );
    await _writeCards(cards);
  }

  Future<void> _writeCards(List<ArchivedCard> cards) async {
    final file = await _indexFile();
    await file.writeAsString(jsonEncode(cards.map((card) => card.toJson()).toList()), flush: true);
  }
}
