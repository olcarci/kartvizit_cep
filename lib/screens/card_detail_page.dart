import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/archived_card.dart';
import '../models/card_data.dart';
import '../services/card_archive_service.dart';
import '../services/card_parser.dart';
import '../services/reminder_service.dart';
import 'reminder_dialog.dart';
import 'export_page.dart';
import 'batch_scan_page.dart';
import '../widgets/contact_quick_actions.dart';
import '../widgets/tech_background.dart';

class CardDetailPage extends StatefulWidget {
  final ArchivedCard card;
  final CardArchiveService service;
  final Future<void> Function(BuildContext, ArchivedCard) onEdit;
  const CardDetailPage({
    super.key,
    required this.card,
    required this.service,
    required this.onEdit,
  });

  @override
  State<CardDetailPage> createState() => _CardDetailPageState();
}

class _CardDetailPageState extends State<CardDetailPage> {
  late ArchivedCard _card;
  late final List<TextEditingController> _fields;
  bool _busy = false;
  bool _showBack = false;
  late final _reminders = ReminderService(widget.service);

  @override
  void initState() {
    super.initState();
    _card = widget.card;
    _fields = List.generate(9, (_) => TextEditingController());
    _updateFields();
  }

  void _updateFields() {
    final d = _card.data;
    String phones(PhoneKind kind) => d.phones
        .where((p) => (d.phoneKinds[p] ?? inferPhoneKind(p)) == kind)
        .join('\n');
    final values = [
      d.name,
      d.company,
      d.title,
      phones(PhoneKind.mobile),
      d.email,
      d.website,
      d.address,
      phones(PhoneKind.work),
      phones(PhoneKind.other),
    ];
    for (var i = 0; i < values.length; i++) {
      _fields[i].text = values[i];
    }
  }

  @override
  void dispose() {
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  void _error() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşlem tamamlanamadı. Tekrar deneyin.')),
      );
    }
  }

  Future<void> _favorite() async {
    setState(() => _busy = true);
    try {
      final updated = await widget.service.updateOrganization(
        _card.id,
        isFavorite: !_card.isFavorite,
      );
      if (mounted) setState(() => _card = updated);
    } catch (_) {
      _error();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _organize() async {
    final updated = await showDialog<ArchivedCard>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OrganizationDialog(card: _card, service: widget.service),
    );
    if (mounted && updated != null) setState(() => _card = updated);
  }

  Future<void> _edit() async {
    setState(() => _busy = true);
    try {
      await widget.onEdit(context, _card);
      final cards = await widget.service.loadCards();
      if (!mounted) return;
      final updated = cards.where((card) => card.id == _card.id).firstOrNull;
      if (updated != null) {
        setState(() => _card = updated);
        _updateFields();
      }
    } catch (_) {
      _error();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remind() async {
    final result = await showDialog<ReminderSaveResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReminderDialog(card: _card, service: _reminders),
    );
    if (!mounted || result == null) return;
    setState(() => _card = result.card);
    if (result.warning != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.warning!),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  Future<void> _finishReminder({bool remove = false}) async {
    setState(() => _busy = true);
    try {
      final card = await _reminders.finish(_card.id, remove: remove);
      if (mounted) setState(() => _card = card);
    } catch (_) {
      _error();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addBack() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Arka yüzü çek'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Arka yüzü fotoğraflardan seç'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2400,
        imageQuality: 95,
        requestFullMetadata: false,
      );
      if (!mounted || image == null) return;
      final updated = await Navigator.of(context).push<ArchivedCard>(
        MaterialPageRoute(
          builder: (_) => BatchScanPage(
            paths: [image.path],
            archive: widget.service,
            backFor: _card,
          ),
        ),
      );
      if (mounted && updated != null) {
        setState(() {
          _card = updated;
          _showBack = true;
        });
        _updateFields();
      }
    } catch (_) {
      _error();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeBack() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arka yüzü kaldır'),
        content: const Text(
          'Arka yüz fotoğrafı ve bu yüzden okunan ham metin kaldırılır. Kişi bilgileri korunur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final card = await widget.service.removeBack(_card.id);
      if (mounted) {
        setState(() {
          _card = card;
          _showBack = false;
        });
      }
    } catch (_) {
      _error();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _card.data;
    final title = data.name.isNotEmpty ? data.name : data.company;
    final date = _card.createdAt;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kişi profili'),
        actions: [
          IconButton(
            onPressed: _busy
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ExportPage(cards: [_card]),
                    ),
                  ),
            tooltip: 'Kartviziti paylaş',
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            onPressed: _busy ? null : _favorite,
            tooltip: _card.isFavorite
                ? 'Favorilerden çıkar'
                : 'Favorilere ekle',
            icon: Icon(
              _card.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: const Color(0xFF8A692F),
            ),
          ),
        ],
      ),
      body: TechBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TechPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.isEmpty ? 'İsimsiz kartvizit' : title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (data.company.isNotEmpty && data.name.isNotEmpty)
                          Text(data.company),
                        if (data.title.isNotEmpty) Text(data.title),
                        const SizedBox(height: 12),
                        Text(
                          'Eklenme: ${date.day}.${date.month}.${date.year}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(
                              _showBack && _card.backImagePath != null
                                  ? _card.backImagePath!
                                  : _card.imagePath,
                            ),
                            height: 190,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (_, error, stack) => const SizedBox(
                              height: 80,
                              child: Center(
                                child: Text('Kartvizit fotoğrafı bulunamadı.'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_card.backImagePath != null)
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Ön yüz'),
                                selected: !_showBack,
                                onSelected: (_) =>
                                    setState(() => _showBack = false),
                              ),
                              ChoiceChip(
                                label: const Text('Arka yüz'),
                                selected: _showBack,
                                onSelected: (_) =>
                                    setState(() => _showBack = true),
                              ),
                            ],
                          ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            TextButton.icon(
                              onPressed: _busy ? null : _addBack,
                              icon: const Icon(Icons.flip_to_back),
                              label: Text(
                                _card.backImagePath == null
                                    ? 'Arka yüz ekle'
                                    : 'Arka yüzü değiştir',
                              ),
                            ),
                            if (_card.backImagePath != null)
                              TextButton(
                                onPressed: _busy ? null : _removeBack,
                                child: const Text('Arka yüzü kaldır'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ContactQuickActions(fields: _fields),
                  const SizedBox(height: 16),
                  TechPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Takip hatırlatması',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_card.reminder == null)
                          const Text(
                            'Bu kişiyle bir sonraki iletişiminizi planlayın.',
                          )
                        else ...[
                          Text(_card.reminder!.title),
                          Text(reminderDate(_card.reminder!.dueAt)),
                          Text(
                            _card.reminder!.completed
                                ? 'Tamamlandı'
                                : _card.reminder!.dueAt.isBefore(DateTime.now())
                                ? 'Zamanı geçti · Takip bekliyor'
                                : _card.reminder!.notificationId == null
                                ? 'Bildirim kurulmadı · Yeniden kaydedin'
                                : 'Bildirim planlandı',
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _busy ? null : _remind,
                              icon: const Icon(Icons.notification_add_outlined),
                              label: Text(
                                _card.reminder == null
                                    ? 'Hatırlatma ekle'
                                    : 'Hatırlatmayı düzenle',
                              ),
                            ),
                            if (_card.reminder != null &&
                                !_card.reminder!.completed)
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => _finishReminder(),
                                child: const Text('Tamamlandı'),
                              ),
                            if (_card.reminder != null)
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => _finishReminder(remove: true),
                                child: const Text('Hatırlatmayı kaldır'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TechPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'İletişim bilgileri',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        for (final entry in <String, String>{
                          'Telefon': data.phones.join('\n'),
                          'E-posta': data.email,
                          'Web sitesi': data.website,
                          'Adres': data.address,
                        }.entries)
                          if (entry.value.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge,
                                  ),
                                  SelectableText(entry.value),
                                ],
                              ),
                            ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _edit,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text(
                            'Bilgileri düzenle / rehbere kaydet',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TechPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Etiketler ve notlar',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_card.tags.isEmpty)
                          const Text('Henüz etiket eklenmedi.')
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              for (final tag in _card.tags)
                                Chip(label: Text(tag)),
                            ],
                          ),
                        const SizedBox(height: 12),
                        SelectableText(
                          _card.notes.isEmpty
                              ? 'Nerede tanıştınız? Ne konuştunuz? Hatırlamak istediklerinizi not edin.'
                              : _card.notes,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _organize,
                          icon: const Icon(Icons.edit_note),
                          label: const Text('Etiket ve not ekle / düzenle'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrganizationDialog extends StatefulWidget {
  final ArchivedCard card;
  final CardArchiveService service;
  const _OrganizationDialog({required this.card, required this.service});
  @override
  State<_OrganizationDialog> createState() => _OrganizationDialogState();
}

class _OrganizationDialogState extends State<_OrganizationDialog> {
  late final _notes = TextEditingController(text: widget.card.notes);
  late final _tags = TextEditingController(text: widget.card.tags.join(', '));
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _notes.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final card = await widget.service.updateOrganization(
        widget.card.id,
        notes: _notes.text.trim(),
        tags: _tags.text.split(','),
      );
      if (mounted) Navigator.pop(context, card);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Kaydedilemedi. Notlarınız burada; tekrar deneyin.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text('Etiketler ve notlar'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _tags,
                enabled: !_saving,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Etiketler',
                  helperText: 'Virgülle ayırın: Müşteri, Fuar, Tedarikçi',
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notes,
                enabled: !_saving,
                minLines: 4,
                maxLines: 8,
                maxLength: 5000,
                decoration: const InputDecoration(
                  labelText: 'Notlar',
                  hintText: 'Tanışma yeri, görüşme konusu, önemli ayrıntılar…',
                ),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
        ),
      ],
    ),
  );
}

