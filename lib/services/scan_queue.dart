import 'package:flutter/foundation.dart';

import '../models/archived_card.dart';
import '../models/card_data.dart';
import 'card_archive_service.dart';
import 'card_scan_service.dart';

class ScanQueueItem {
  String path;
  ScanDraft? draft;
  ArchivedCard? saved;
  String? error;
  bool skipped = false;
  ScanQueueItem(this.path);
}

class ScanQueue extends ChangeNotifier {
  static const limit = 20;
  final CardArchiveService archive;
  final CardScanService scanner;
  final ArchivedCard? backFor;
  final List<ScanQueueItem> items;
  bool busy = false;
  bool stopRequested = false;
  int? activeIndex;
  bool _disposed = false;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stopRequested = true;
    super.dispose();
  }

  ScanQueue({
    required List<String> paths,
    required this.archive,
    required this.scanner,
    this.backFor,
  }) : items = paths.map(ScanQueueItem.new).toList() {
    if (paths.isEmpty ||
        paths.length > limit ||
        backFor != null && paths.length != 1) {
      throw ArgumentError('Bir seferde 1–20 fotoğraf seçin.');
    }
  }
  bool get hasUnsaved =>
      items.any((item) => item.saved == null && !item.skipped);
  int get savedCount => items.where((item) => item.saved != null).length;
  void stop() {
    stopRequested = true;
    notifyListeners();
  }

  Future<void> readAll() async {
    if (busy) return;
    busy = true;
    stopRequested = false;
    notifyListeners();
    try {
      for (var i = 0; i < items.length; i++) {
        if (stopRequested) break;
        if (items[i].draft != null ||
            items[i].saved != null ||
            items[i].skipped) {
          continue;
        }
        activeIndex = i;
        notifyListeners();
        await _read(items[i]);
        notifyListeners();
      }
    } finally {
      busy = false;
      activeIndex = null;
      notifyListeners();
    }
  }

  Future<void> _read(ScanQueueItem item) async {
    item.error = null;
    try {
      item.draft = await scanner.scan(item.path, allowEmpty: backFor != null);
    } catch (error) {
      item.error = error is FormatException
          ? error.message
          : 'Fotoğraf okunamadı. Kırpıp yeniden deneyin veya atlayın.';
    }
  }

  Future<void> reread(int index, String path) async {
    if (busy || items[index].saved != null) return;
    busy = true;
    activeIndex = index;
    notifyListeners();
    try {
      final item = items[index];
      item.path = path;
      item.draft = null;
      item.skipped = false;
      await _read(item);
    } finally {
      busy = false;
      activeIndex = null;
      notifyListeners();
    }
  }

  CardData reviewData(ScanQueueItem item) =>
      item.saved?.data ??
      (backFor == null
          ? item.draft!.data
          : CardScanService.supplement(backFor!.data, item.draft!.data));

  Future<ArchivedCard> save(int index, {CardData? reviewedData}) async {
    if (busy) throw StateError('Diğer işlem devam ediyor.');
    final item = items[index];
    if (item.draft == null || item.skipped) {
      throw StateError('Önce fotoğrafı okuyun.');
    }
    final data = reviewedData ?? reviewData(item);
    if (data.name.trim().isEmpty && data.company.trim().isEmpty) {
      throw const FormatException(
        'Bilgileri kontrol edip ad veya şirket girin.',
      );
    }
    busy = true;
    item.error = null;
    notifyListeners();
    try {
      if (item.saved != null) {
        await archive.updateCardData(item.saved!.id, data);
        item.saved = item.saved!.copyWith(data: data);
      } else if (backFor != null) {
        item.saved = await archive.attachBack(
          backFor!.id,
          item.draft!,
          reviewedData: reviewedData,
        );
      } else {
        item.saved = await archive.saveScan(
          sourceImagePath: item.path,
          data: data,
          rawText: item.draft!.rawText,
        );
      }
      return item.saved!;
    } catch (_) {
      item.error = 'Arşive kaydedilemedi. Yeniden deneyin.';
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void skip(int index) {
    if (busy || items[index].saved != null) return;
    items[index].skipped = !items[index].skipped;
    notifyListeners();
  }
}
