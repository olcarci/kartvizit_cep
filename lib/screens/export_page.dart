import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/archived_card.dart';
import '../services/card_export_service.dart';
import '../services/file_transfer_service.dart';
import '../widgets/tech_background.dart';

class ExportPage extends StatefulWidget {
  final List<ArchivedCard> cards;
  const ExportPage({super.key, required this.cards});
  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  late final _selected = widget.cards.map((card) => card.id).toSet();
  CardExportFormat _format = CardExportFormat.vcf;
  bool _includeNotes = false;
  bool _busy = false;
  String? _message;

  Future<void> _export(bool share) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? const Rect.fromLTWH(0, 0, 1, 1)
        : box.localToGlobal(Offset.zero) & box.size;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final cards = widget.cards
          .where((card) => _selected.contains(card.id))
          .toList();
      final bytes = CardExportService.export(
        cards,
        _format,
        includeNotes: _includeNotes,
      );
      final name = 'kartvizitler.${_format.name}';
      final mime = _format == CardExportFormat.csv ? 'text/csv' : 'text/vcard';
      String message;
      if (share) {
        final result = await FileTransferService.share(
          bytes,
          name,
          mime,
          origin,
        );
        message = result.status == ShareResultStatus.dismissed
            ? 'Paylaşım iptal edildi.'
            : 'Paylaşım menüsü açıldı.';
      } else {
        final saved = await FileTransferService.save(bytes, name, mime);
        message = saved
            ? '${cards.length} kartvizit dosyaya kaydedildi.'
            : 'Kaydetme iptal edildi.';
      }
      if (mounted) setState(() => _message = message);
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Dışa aktarılamadı. Tekrar deneyin.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Kartvizitleri dışa aktar')),
      body: TechBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'VCF rehbere aktarmak, CSV Excel ve benzeri tablolarda kullanmak içindir. Fotoğraflar bu dosyalara eklenmez.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: [
                      for (final format in CardExportFormat.values)
                        ChoiceChip(
                          label: Text(format.name.toUpperCase()),
                          selected: _format == format,
                          onSelected: _busy
                              ? null
                              : (_) => setState(() => _format = format),
                        ),
                    ],
                  ),
                  if (_format == CardExportFormat.csv)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _includeNotes,
                      title: const Text('Özel notlarımı ve etiketleri de ekle'),
                      onChanged: _busy
                          ? null
                          : (value) =>
                                setState(() => _includeNotes = value ?? false),
                    ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Tümünü seç (${_selected.length}/${widget.cards.length})',
                    ),
                    value:
                        widget.cards.isNotEmpty &&
                        _selected.length == widget.cards.length,
                    onChanged: _busy
                        ? null
                        : (value) => setState(() {
                            _selected.clear();
                            if (value == true) {
                              _selected.addAll(
                                widget.cards.map((card) => card.id),
                              );
                            }
                          }),
                  ),
                  const Divider(),
                  for (final card in widget.cards)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        card.data.name.isEmpty
                            ? card.data.company
                            : card.data.name,
                      ),
                      subtitle: Text(card.data.company),
                      value: _selected.contains(card.id),
                      onChanged: _busy
                          ? null
                          : (value) => setState(() {
                              if (value == true) {
                                _selected.add(card.id);
                              } else {
                                _selected.remove(card.id);
                              }
                            }),
                    ),
                  if (_message != null) Text(_message!),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy || _selected.isEmpty
                    ? null
                    : () => _export(false),
                icon: const Icon(Icons.save_alt),
                label: const Text('Dosyaya kaydet'),
              ),
              OutlinedButton.icon(
                onPressed: _busy || _selected.isEmpty
                    ? null
                    : () => _export(true),
                icon: const Icon(Icons.share_outlined),
                label: Text(_busy ? 'Hazırlanıyor…' : 'Paylaş'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
