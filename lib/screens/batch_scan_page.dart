import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/archived_card.dart';
import '../services/card_archive_service.dart';
import '../services/card_scan_service.dart';
import '../services/scan_queue.dart';
import '../widgets/tech_background.dart';
import 'crop_page.dart';
import 'edit_page.dart';

class BatchScanPage extends StatefulWidget {
  final List<String> paths;
  final CardArchiveService archive;
  final ArchivedCard? backFor;
  final CardTextReader? reader;
  const BatchScanPage({
    super.key,
    required this.paths,
    required this.archive,
    this.backFor,
    this.reader,
  });
  @override
  State<BatchScanPage> createState() => _BatchScanPageState();
}

class _BatchScanPageState extends State<BatchScanPage> {
  late final CardTextReader _reader = widget.reader ?? MlKitCardTextReader();
  late final ScanQueue _queue = ScanQueue(
    paths: widget.paths,
    archive: widget.archive,
    scanner: CardScanService(_reader),
    backFor: widget.backFor,
  );
  final _temporary = <Directory>[];
  bool _allowLeave = false;
  bool _asking = false;
  Future<void>? _activeScan;
  @override
  void initState() {
    super.initState();
    _queue.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _activeScan = _queue.readAll();
    });
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _queue.removeListener(_changed);
    _queue.dispose();
    unawaited(_cleanup());
    super.dispose();
  }

  Future<void> _cleanup() async {
    try {
      await _activeScan;
    } catch (_) {
      /* In-flight scan errors are surfaced elsewhere; ignore during teardown. */
    }
    try {
      await _reader.close();
    } catch (_) {
      /* App teardown. */
    }
    for (final dir in _temporary) {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException {
        /* Temporary file cleanup. */
      }
    }
  }

  Future<void> _leave() async {
    if (_queue.busy || _asking) return;
    _asking = true;
    final leave =
        !_queue.hasUnsaved ||
        await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Taramadan çıkılsın mı?'),
                content: Text(
                  '${_queue.savedCount} kayıt arşivde korunacak. Kaydetmediğiniz fotoğrafların tarama sonuçları kapanacak.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Devam et'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Çık'),
                  ),
                ],
              ),
            ) ==
            true;
    _asking = false;
    if (!mounted || !leave) return;
    setState(() => _allowLeave = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  void _message(Object error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is FormatException
                ? error.message
                : 'İşlem tamamlanamadı. Tekrar deneyin.',
          ),
        ),
      );
    }
  }

  void _finishBack(ArchivedCard? card) {
    if (widget.backFor == null || card == null || !mounted) return;
    setState(() => _allowLeave = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, card);
    });
  }

  Future<void> _save(int index) async {
    try {
      _finishBack(await _queue.save(index));
    } catch (error) {
      _message(error);
    }
  }

  Future<void> _review(int index) async {
    final item = _queue.items[index];
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditPage(
          data: _queue.reviewData(item),
          raw: widget.backFor == null
              ? item.draft!.rawText
              : 'Ön yüz:\n${widget.backFor!.rawText}\n\nArka yüz:\n${item.draft!.rawText}',
          imagePath: item.path,
          alreadyArchived: item.saved != null,
          archiveSaveLabel: widget.backFor == null
              ? 'Arşive kaydet'
              : 'Arka yüzü ve bilgileri kaydet',
          onDataChanged: (data) async {
            await _queue.save(index, reviewedData: data);
          },
        ),
      ),
    );
    _finishBack(item.saved);
  }

  Future<void> _crop(int index) async {
    try {
      final item = _queue.items[index];
      final selection = await Navigator.of(context).push<CropSelection>(
        MaterialPageRoute(builder: (_) => CropPage(imagePath: item.path)),
      );
      if (selection == null || !mounted) return;
      var path = item.path;
      if (selection.bytes != null) {
        final directory = await Directory.systemTemp.createTemp(
          'kartvizit_batch_crop_',
        );
        if (!mounted) {
          await directory.delete(recursive: true);
          return;
        }
        _temporary.add(directory);
        path = '${directory.path}/cropped.png';
        await File(path).writeAsBytes(selection.bytes!, flush: true);
      }
      if (mounted) {
        final reread = _queue.reread(index, path);
        _activeScan = reread;
        await reread;
      }
    } catch (error) {
      _message(error);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowLeave || (!_queue.busy && !_queue.hasUnsaved),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _leave();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.backFor == null ? 'Toplu tarama' : 'Arka yüzü ekle'),
      ),
      body: TechBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    widget.backFor == null
                        ? 'Her fotoğraf ayrı bir kartvizittir. Sonuçları kontrol edin, sonra kaydedin. Rehbere otomatik kayıt yapılmaz.'
                        : 'Arka yüz aynı karta eklenecek. Dolu alanlar korunur; boş alanlar ve yeni numaralar tamamlanır. Kaydetmeden önce bilgileri düzenleyebilirsiniz.',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_queue.savedCount}/${_queue.items.length} kaydedildi',
                  ),
                  if (_queue.busy) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                    Text(
                      _queue.activeIndex == null
                          ? 'Kaydediliyor…'
                          : '${_queue.activeIndex! + 1}. fotoğraf okunuyor…',
                    ),
                    if (_queue.activeIndex != null)
                      TextButton(
                        onPressed: _queue.stopRequested ? null : _queue.stop,
                        child: Text(
                          _queue.stopRequested
                              ? 'Mevcut fotoğraf bitince duracak…'
                              : 'Okumayı durdur',
                        ),
                      ),
                  ] else if (_queue.items.any(
                    (item) => item.draft == null && !item.skipped,
                  ))
                    TextButton.icon(
                      onPressed: _queue.readAll,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Kalanları oku / tekrar dene'),
                    ),
                  for (var i = 0; i < _queue.items.length; i++) _item(i),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _queue.busy ? null : _leave,
                    child: const Text('Taramayı bitir'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _item(int index) {
    final item = _queue.items[index];
    final data = item.draft == null ? null : _queue.reviewData(item);
    return TechPanel(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. fotoğraf${item.saved != null
                ? ' · Kaydedildi'
                : item.skipped
                ? ' · Atlandı'
                : ''}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Image.file(
            File(item.path),
            height: 140,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (_, error, stack) =>
                const Text('Fotoğraf önizlemesi açılamadı.'),
          ),
          if (data != null) ...[
            const SizedBox(height: 10),
            Text(
              data.name.isEmpty ? 'Ad okunamadı' : data.name,
              style: const TextStyle(fontSize: 20),
            ),
            if (data.company.isNotEmpty) Text(data.company),
            if (data.phones.isNotEmpty) Text(data.phones.join(' · ')),
            if (data.email.isNotEmpty) Text(data.email),
          ],
          if (item.error != null)
            Text(
              item.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (data != null && !item.skipped)
                OutlinedButton(
                  onPressed: _queue.busy ? null : () => _review(index),
                  child: const Text('Bilgileri kontrol et'),
                ),
              if (data != null && item.saved == null && !item.skipped)
                TextButton(
                  onPressed: _queue.busy ? null : () => _save(index),
                  child: Text(
                    widget.backFor == null
                        ? 'Arşive kaydet'
                        : 'Arka yüzü kaydet',
                  ),
                ),
              if (item.saved == null && !item.skipped)
                TextButton(
                  onPressed: _queue.busy ? null : () => _crop(index),
                  child: const Text('Kırp ve yeniden oku'),
                ),
              if (item.saved == null)
                TextButton(
                  onPressed: _queue.busy ? null : () => _queue.skip(index),
                  child: Text(item.skipped ? 'Geri al' : 'Atla'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
