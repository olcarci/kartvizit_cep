import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../models/card_data.dart';
import '../services/card_parser.dart';
import '../services/contact_merge_service.dart';
import '../widgets/contact_quick_actions.dart';
import '../widgets/tech_background.dart';
import '../widgets/vivid_button.dart';

class EditPage extends StatefulWidget {
  final CardData data;
  final String raw;
  final String? imagePath;
  final Future<void> Function(CardData data)? onDataChanged;
  final String archiveSaveLabel;
  final bool alreadyArchived;
  const EditPage({
    super.key,
    required this.data,
    this.raw = '',
    this.imagePath,
    this.onDataChanged,
    this.archiveSaveLabel = 'Galeri bilgilerini güncelle',
    this.alreadyArchived = true,
  });
  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final _form = GlobalKey<FormState>();
  late final List<TextEditingController> _fields;
  bool _saving = false;
  String? _savedId;
  bool _openedExisting = false;
  late bool _archiveSaved = widget.alreadyArchived;
  @override
  void initState() {
    super.initState();
    final d = widget.data;
    String group(PhoneKind kind) => d.phones
        .where((p) => (d.phoneKinds[p] ?? inferPhoneKind(p)) == kind)
        .join('\n');
    _fields = [
      d.name,
      d.company,
      d.title,
      group(PhoneKind.mobile),
      d.email,
      d.website,
      d.address,
      group(PhoneKind.work),
      group(PhoneKind.other),
    ].map((s) => TextEditingController(text: s)).toList();
  }

  @override
  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
    super.dispose();
  }

  String _v(int i) => _fields[i].text.trim();
  void _message(String s) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
    }
  }

  CardData? _currentData({required bool requireContactDetails}) {
    if (!_form.currentState!.validate()) return null;
    if (_v(0).isEmpty && _v(1).isEmpty) {
      _message('Ad soyad veya şirket adı girin.');
      return null;
    }
    final kinds = <String, PhoneKind>{};
    for (final entry in {
      3: PhoneKind.mobile,
      7: PhoneKind.work,
      8: PhoneKind.other,
    }.entries) {
      for (final line in _v(
        entry.key,
      ).split('\n').where((s) => s.trim().isNotEmpty)) {
        final number = normalizePhone(line);
        if (kinds.containsKey(number)) {
          _message('Aynı numarayı yalnızca bir telefon alanına yazın.');
          return null;
        }
        kinds[number] = entry.value;
      }
    }
    final phones = kinds.keys.toList();
    if (requireContactDetails && phones.isEmpty && _v(4).isEmpty) {
      _message('En az bir telefon veya e-posta girin.');
      return null;
    }
    return CardData(
      name: _v(0),
      company: _v(1),
      title: _v(2),
      phones: phones,
      phoneKinds: kinds,
      email: _v(4),
      website: _v(5),
      address: _v(6),
    );
  }

  Future<void> _saveToGallery() async {
    if (_saving || widget.onDataChanged == null) return;
    final data = _currentData(requireContactDetails: false);
    if (data == null) return;
    setState(() => _saving = true);
    try {
      await widget.onDataChanged!(data);
      _message(
        _archiveSaved
            ? 'Galeri bilgileri güncellendi.'
            : 'Kartvizit arşive kaydedildi.',
      );
      if (mounted) setState(() => _archiveSaved = true);
    } catch (_) {
      _message('Galeri bilgileri güncellenemedi. Tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (_saving || _savedId != null) return;
    final data = _currentData(requireContactDetails: true);
    if (data == null) return;
    setState(() => _saving = true);
    try {
      try {
        await widget.onDataChanged?.call(data);
        if (mounted && widget.onDataChanged != null) {
          setState(() => _archiveSaved = true);
        }
      } catch (_) {
        _message(
          'Düzeltilen bilgiler arşive kaydedilemedi; rehber kaydına devam ediliyor.',
        );
      }
      final permission = await FlutterContacts.permissions.request(
        PermissionType.readWrite,
      );
      if (!mounted) return;
      if (permission != PermissionStatus.granted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Rehber erişimi gerekli'),
            content: const Text(
              'Kayıt ve mükerrer kontrolü için tam rehber erişimi verin. Sınırlı erişimde tüm numaraları kontrol edemiyoruz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Vazgeç'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  FlutterContacts.permissions.openSettings();
                },
                child: const Text('Ayarları aç'),
              ),
            ],
          ),
        );
        return;
      }
      final keys = data.phones.map(phoneKey).toSet();
      final all = await FlutterContacts.getAll(
        properties: {ContactProperty.phone, ContactProperty.email},
      );
      final matches = all
          .where(
            (c) =>
                c.phones.any((p) => keys.contains(phoneKey(p.number))) ||
                (_v(4).isNotEmpty &&
                    c.emails.any(
                      (e) => e.address.toLowerCase() == _v(4).toLowerCase(),
                    )),
          )
          .toList();
      if (!mounted) return;
      if (matches.isNotEmpty) {
        final action = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Bu kişi rehberde olabilir'),
            content: const Text(
              'Aynı telefon veya e-posta bulundu. Kartvizitteki eksik bilgileri mevcut kişiye ekleyebilir, kişiyi olduğu gibi açabilir ya da ayrı kayıt oluşturabilirsiniz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Vazgeç'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'edit'),
                child: const Text('Mevcut kişiyi aç'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'merge'),
                child: const Text('Bilgileri mevcut kişiye ekle'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'new'),
                child: const Text('Ayrı kayıt oluştur'),
              ),
            ],
          ),
        );
        if (action == 'edit') {
          await _editExistingContact(matches.first.id!);
          return;
        }
        if (action == 'merge') {
          await _mergeIntoExistingContact(matches.first.id!, data);
          return;
        }
        if (action != 'new') return;
      }
      final contacts = FlutterContacts.vCard.import(data.toVCard());
      if (contacts.length != 1) throw StateError('Invalid contact');
      final id = await FlutterContacts.create(contacts.single);
      if (mounted) setState(() => _savedId = id);
    } catch (_) {
      _message(
        'Kayıt tamamlanamadı. Rehberi kontrol edin; izinleri ve alanları gözden geçirip tekrar deneyin.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editExistingContact(String id) async {
    try {
      final editedId = await FlutterContacts.native.showEditor(id);
      if (!mounted) return;
      // A null result does not reliably confirm saving on every platform.
      // End the create flow without claiming the existing contact was changed.
      setState(() {
        _savedId = editedId ?? id;
        _openedExisting = true;
      });
    } catch (_) {
      _message(
        'Mevcut kişi açılamadı. Rehber erişimini kontrol edip tekrar deneyin.',
      );
    }
  }

  Future<void> _mergeIntoExistingContact(String id, CardData data) async {
    try {
      final existing = await FlutterContacts.get(
        id,
        properties: const {
          ContactProperty.name,
          ContactProperty.phone,
          ContactProperty.email,
          ContactProperty.address,
          ContactProperty.organization,
          ContactProperty.website,
        },
      );
      if (existing == null) throw StateError('Contact not found');
      final imported = FlutterContacts.vCard.import(data.toVCard());
      if (imported.length != 1) throw StateError('Invalid contact');

      final merged = mergeContactKeepingExisting(existing, imported.single);
      await FlutterContacts.update(merged);
      final editedId = await FlutterContacts.native.showEditor(id);
      if (!mounted) return;
      setState(() {
        _savedId = editedId ?? id;
        _openedExisting = true;
      });
      _message('Kartvizit bilgileri mevcut kişiye eklendi.');
    } catch (_) {
      _message(
        'Mevcut kişi güncellenemedi. Rehber erişimini kontrol edip tekrar deneyin.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          _savedId == null
              ? 'Kişi bilgilerini kontrol et'
              : _openedExisting
              ? 'Mevcut kişi'
              : 'Kayıt tamamlandı',
        ),
      ),
      body: TechBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _savedId != null
                  ? ListView(
                      padding: const EdgeInsets.all(28),
                      children: [
                        const SizedBox(height: 40),
                        Icon(
                          _openedExisting
                              ? Icons.person_outline
                              : Icons.check_circle,
                          size: 88,
                          color: const Color(0xFF174B40),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _openedExisting
                              ? 'Mevcut kişiyle devam edildi'
                              : 'Rehbere kaydedildi',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _openedExisting
                              ? 'Değişiklikleri rehberin düzenleme ekranında kaydettiysen işlem tamam. Rehberde göster ile kontrol edebilirsin.'
                              : (_v(0).isEmpty ? _v(1) : _v(0)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        if (_openedExisting)
                          OutlinedButton(
                            onPressed: () => _editExistingContact(_savedId!),
                            child: const Text('Kişiyi tekrar düzenle'),
                          ),
                        FilledButton(
                          onPressed: () async {
                            try {
                              await FlutterContacts.native.showViewer(
                                _savedId!,
                              );
                            } catch (_) {
                              _message(
                                'Rehber açılamadı. Telefonun Kişiler uygulamasından kontrol edebilirsiniz.',
                              );
                            }
                          },
                          child: const Text('Rehberde göster'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Yeni kartvizit tara'),
                        ),
                      ],
                    )
                  : Form(
                      key: _form,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          ContactQuickActions(fields: _fields),
                          const SizedBox(height: 16),
                          if (widget.imagePath != null)
                            TechPanel(
                              padding: const EdgeInsets.all(10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  File(widget.imagePath!),
                                  height: 170,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Text(
                                        'Fotoğraf önizlemesi açılamadı.',
                                      ),
                                ),
                              ),
                            ),
                          if (widget.onDataChanged != null)
                            TechPanel(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.collections_bookmark_rounded,
                                    color: Color(0xFF174B40),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _archiveSaved
                                          ? 'Bu kart uygulama galerisinde saklanıyor. Rehbere yalnızca aşağıdaki düğmeyle eklenir.'
                                          : 'Bu kart henüz kaydedilmedi. Bilgileri kontrol edip arşive kaydedin.',
                                      style: TextStyle(
                                        color: Color(0xFF10382F),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'Otomatik doldurulan alanlar tahmindir. Özellikle isim ve telefonları kontrol edin.',
                            ),
                          ),
                          for (final i in [0, 1, 2, 3, 7, 8, 4, 5, 6])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TextFormField(
                                controller: _fields[i],
                                enabled: !_saving,
                                style: const TextStyle(fontSize: 18),
                                minLines: 1,
                                maxLines: [3, 6, 7, 8].contains(i) ? 4 : 1,
                                keyboardType: [3, 7, 8].contains(i)
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
                                    'Cep telefonu',
                                    'E-posta',
                                    'Web sitesi',
                                    'Adres',
                                    'Sabit / iş telefonu',
                                    'Diğer telefonlar',
                                  ][i],
                                ),
                                validator: (s) {
                                  final value = (s ?? '').trim();
                                  if (i == 4 &&
                                      value.isNotEmpty &&
                                      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                          .hasMatch(value)) {
                                    return 'Geçerli bir e-posta girin.';
                                  }
                                  if ([3, 7, 8].contains(i) &&
                                      value.isNotEmpty &&
                                      value
                                          .split('\n')
                                          .where((p) => p.trim().isNotEmpty)
                                          .any(
                                            (p) =>
                                                !RegExp(r'^\+?[\d\s().-]+$')
                                                    .hasMatch(p.trim()) ||
                                                phoneKey(p).length < 10 ||
                                                phoneKey(p).length > 15,
                                          )) {
                                    return 'Her satıra geçerli bir telefon numarası girin.';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          if (widget.raw.isNotEmpty)
                            ExpansionTile(
                              title: const Text('Kartvizitte okunan tüm metin'),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: SelectableText(widget.raw),
                                ),
                              ],
                            ),
                          const SizedBox(height: 20),
                          if (widget.onDataChanged != null) ...[
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                              ),
                              onPressed: _saving ? null : _saveToGallery,
                              icon: const Icon(Icons.save_rounded),
                              label: Text(
                                widget.archiveSaveLabel,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          VividButton(
                            onPressed: _saving ? null : _save,
                            icon: Icons.person_add_alt_1,
                            label: _saving ? 'Kaydediliyor…' : 'Rehbere kaydet',
                          ),
                          const SizedBox(height: 24),
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
