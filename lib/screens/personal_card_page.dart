import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/card_data.dart';
import '../models/personal_card.dart';
import '../services/card_parser.dart';
import '../services/file_transfer_service.dart';
import '../services/personal_card_service.dart';
import '../widgets/personal_card_view.dart';
import '../widgets/tech_background.dart';

class PersonalCardPage extends StatefulWidget {
  final PersonalCardService? service;
  const PersonalCardPage({super.key, this.service});
  @override
  State<PersonalCardPage> createState() => _PersonalCardPageState();
}

class _PersonalCardPageState extends State<PersonalCardPage> {
  late final _service = widget.service ?? PersonalCardService();
  final _preview = GlobalKey();
  final _scroll = ScrollController();
  PersonalCard? _card;
  bool _loading = true, _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final card = await _service.load();
      if (mounted) {
        setState(() {
          _card = card;
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Kişisel kartınız açılamadı. Tekrar deneyin.';
        });
      }
    }
  }

  Future<void> _edit() async {
    final card = await Navigator.of(context).push<PersonalCard>(
      MaterialPageRoute(
        builder: (_) => _PersonalCardEditor(card: _card, service: _service),
      ),
    );
    if (mounted && card != null) setState(() => _card = card);
  }

  Future<void> _share({required bool image, bool save = false}) async {
    if (_card == null || _busy) return;
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? const Rect.fromLTWH(0, 0, 1, 1)
        : box.localToGlobal(Offset.zero) & box.size;
    setState(() => _busy = true);
    try {
      Uint8List bytes;
      if (image) {
        if (_scroll.hasClients) _scroll.jumpTo(0);
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
        final boundary =
            _preview.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final picture = await boundary.toImage(pixelRatio: 3);
        try {
          bytes = (await picture.toByteData(format: ui.ImageByteFormat.png))!
              .buffer
              .asUint8List();
        } finally {
          picture.dispose();
        }
      } else {
        bytes = Uint8List.fromList(utf8.encode(_card!.qrData));
      }
      final name = image ? 'kartvizitim.png' : 'kartvizitim.vcf';
      final mime = image ? 'image/png' : 'text/vcard';
      if (save) {
        final saved = await FileTransferService.save(bytes, name, mime);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                saved
                    ? 'Kartvizit dosyaya kaydedildi.'
                    : 'Kaydetme iptal edildi.',
              ),
            ),
          );
        }
      } else {
        await FileTransferService.share(bytes, name, mime, origin);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kartvizit paylaşılamadı. Tekrar deneyin.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showQr() => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: _card!.qrData,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              padding: const EdgeInsets.all(24),
              backgroundColor: Colors.white,
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Kartvizitim'),
        actions: [
          if (!_loading && _error == null)
            IconButton(
              onPressed: _busy ? null : _edit,
              tooltip: 'Kartvizitimi düzenle',
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: TechBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Tekrar dene'),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          if (_card == null)
                            TechPanel(
                              child: Column(
                                children: [
                                  const Icon(Icons.badge_outlined, size: 64),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Kendi dijital kartvizitini oluştur',
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Bilgilerin, fotoğrafın veya logon ve QR kodun tek kartta. İnternet bağlantısı olmadan paylaş.',
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton(
                                    onPressed: _edit,
                                    child: const Text('Kartvizitimi oluştur'),
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            RepaintBoundary(
                              key: _preview,
                              child: PersonalCardView(card: _card!),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'QR kod, ekranda gördüğünüz iletişim bilgilerini içerir. Fotoğraf/logonuz görsel paylaşımda yer alır; QR ve VCF dosyasında yer almaz.',
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _busy ? null : _showQr,
                                  icon: const Icon(Icons.qr_code_2),
                                  label: const Text('QR kodu büyüt'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => _share(image: true),
                                  icon: const Icon(Icons.image_outlined),
                                  label: const Text('Görseli paylaş'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => _share(image: false),
                                  icon: const Icon(Icons.contact_page_outlined),
                                  label: const Text('VCF paylaş'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => _share(image: true, save: true),
                                  icon: const Icon(Icons.save_alt),
                                  label: const Text('Görseli kaydet'),
                                ),
                              ],
                            ),
                            if (_busy)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                          ],
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _PersonalCardEditor extends StatefulWidget {
  final PersonalCard? card;
  final PersonalCardService service;
  const _PersonalCardEditor({this.card, required this.service});
  @override
  State<_PersonalCardEditor> createState() => _PersonalCardEditorState();
}

class _PersonalCardEditorState extends State<_PersonalCardEditor> {
  final _form = GlobalKey<FormState>();
  late final List<TextEditingController> _fields;
  late int _theme = widget.card?.theme ?? 0;
  late String? _avatar = widget.card?.avatarPath;
  bool _busy = false, _dirty = false, _allowLeave = false, _asking = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final d = widget.card?.data ?? CardData();
    _fields =
        [
              d.name,
              d.company,
              d.title,
              d.phones.join('\n'),
              d.email,
              d.website,
              d.address,
            ]
            .map((s) => TextEditingController(text: s)..addListener(_changed))
            .toList();
  }

  void _changed() {
    if (mounted) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _leave() async {
    if (_busy || _asking) return;
    _asking = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Değişiklikler kaydedilmedi'),
        content: const Text('Kaydetmeden çıkılsın mı?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Düzenlemeye devam et'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çık'),
          ),
        ],
      ),
    );
    _asking = false;
    if (mounted && discard == true) {
      setState(() => _allowLeave = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Future<void> _photo() async {
    setState(() => _busy = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 90,
        requestFullMetadata: false,
      );
      if (mounted && file != null) {
        setState(() {
          _avatar = file.path;
          _dirty = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Fotoğraf seçilemedi. İzinleri kontrol edin.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      String value(int i) => _fields[i].text.trim();
      final phones = value(3)
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      final profile = PersonalCard(
        theme: _theme,
        data: CardData(
          name: value(0),
          company: value(1),
          title: value(2),
          phones: phones,
          phoneKinds: {for (final p in phones) p: inferPhoneKind(p)},
          email: value(4),
          website: value(5),
          address: value(6),
        ),
      );
      profile.validate();
      final saved = await widget.service.save(
        profile,
        sourceAvatar: _avatar,
        removeAvatar: _avatar == null,
      );
      if (mounted) {
        setState(() {
          _allowLeave = true;
          _busy = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context, saved);
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error is FormatException
              ? error.message
              : 'Kartvizit kaydedilemedi. Tekrar deneyin.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowLeave || (!_busy && !_dirty),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _leave();
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Kartvizitimi düzenle')),
      body: TechBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_avatar != null)
                      Image.file(
                        File(_avatar!),
                        height: 100,
                        fit: BoxFit.contain,
                        errorBuilder: (_, error, stack) =>
                            const Text('Fotoğraf açılamadı.'),
                      ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: _busy ? null : _photo,
                          icon: const Icon(Icons.photo_outlined),
                          label: const Text('Fotoğraf / logo seç'),
                        ),
                        if (_avatar != null)
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                    _avatar = null;
                                    _dirty = true;
                                  }),
                            child: const Text('Fotoğrafı kaldır'),
                          ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (var i = 0; i < 3; i++)
                          ChoiceChip(
                            label: Text(['Lacivert', 'Mor', 'Yeşil'][i]),
                            selected: _theme == i,
                            onSelected: _busy
                                ? null
                                : (_) => setState(() {
                                    _theme = i;
                                    _dirty = true;
                                  }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    for (var i = 0; i < _fields.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _fields[i],
                          enabled: !_busy,
                          maxLength: [80, 100, 80, 80, 120, 180, 250][i],
                          minLines: 1,
                          maxLines: i == 3 || i == 6 ? 3 : 1,
                          keyboardType: i == 3 || i == 6
                              ? TextInputType.multiline
                              : i == 4
                              ? TextInputType.emailAddress
                              : i == 5
                              ? TextInputType.url
                              : TextInputType.text,
                          decoration: InputDecoration(
                            labelText: [
                              'Ad soyad',
                              'Şirket',
                              'Unvan',
                              'Telefonlar (her satıra bir numara)',
                              'E-posta',
                              'Web sitesi',
                              'Adres',
                            ][i],
                          ),
                        ),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    FilledButton(
                      onPressed: _busy ? null : _save,
                      child: Text(
                        _busy ? 'Kaydediliyor…' : 'Kartvizitimi kaydet',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
