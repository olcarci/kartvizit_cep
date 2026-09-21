import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'models/card_data.dart';
import 'models/archived_card.dart';
import 'services/card_archive_service.dart';
import 'services/contact_merge_service.dart';
import 'services/card_parser.dart';
import 'screens/crop_page.dart';
import 'widgets/tech_background.dart';
import 'widgets/vivid_button.dart';
import 'widgets/contact_quick_actions.dart';

void main() { WidgetsFlutterBinding.ensureInitialized(); runApp(const KartvizitApp()); }

class KartvizitApp extends StatelessWidget {
  const KartvizitApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Kartvizit Cep', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00D9FF), brightness: Brightness.dark,
        primary: const Color(0xFF45E9F5), secondary: const Color(0xFF9B7BFF), surface: const Color(0xFF12223A)),
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: const Color(0xFF0A1830),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF12223A), surfaceTintColor: Colors.transparent),
      cardTheme: CardThemeData(color: const Color(0xFF12223A).withValues(alpha: 0.94), surfaceTintColor: Colors.transparent),
      snackBarTheme: const SnackBarThemeData(backgroundColor: Color(0xFF15324A), contentTextStyle: TextStyle(color: Colors.white)),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFEAFBFF), surfaceTintColor: Colors.transparent, elevation: 0,
        titleTextStyle: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Color(0xFFEAFBFF), letterSpacing: 0.2)),
      textTheme: const TextTheme(bodyLarge: TextStyle(fontSize: 18, color: Color(0xFFE7F2FF)), bodyMedium: TextStyle(fontSize: 16, color: Color(0xFFB8C8DD))),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF12223A).withValues(alpha: 0.92),
        labelStyle: const TextStyle(color: Color(0xFF9FB4CC)), hintStyle: const TextStyle(color: Color(0xFF8294AA)),
        prefixIconColor: const Color(0xFF5EE7F4), suffixIconColor: const Color(0xFF9B7BFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF284768))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF45E9F5), width: 2))),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 56), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
    ), home: const HomePage());
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  final _picker = ImagePicker();
  final _archive = CardArchiveService();
  bool _busy = false;
  @override void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _recover()); }
  void _message(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }
  Future<void> _recover() async {
    if (!Platform.isAndroid) return;
    try {
      final result = await _picker.retrieveLostData();
      if (!mounted) return;
      if (result.files?.isNotEmpty == true) {
        setState(() => _busy = true);
        await _cropAndRecognize(result.files!.first);
      } else if (result.exception != null) { _message('Önceki fotoğraf alınamadı. Yeniden seçebilirsiniz.'); }
    } catch (_) { _message('Önceki fotoğraf kurtarılamadı. Yeniden tarayabilirsiniz.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _scan(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await _picker.pickImage(source: source, maxWidth: 2400, imageQuality: 95, requestFullMetadata: false);
      if (file != null && mounted) await _cropAndRecognize(file);
    } on PlatformException catch (e) {
      _message('Fotoğrafa erişilemedi. Kamera/fotoğraf izinlerini telefon ayarlarından kontrol edin. (${e.code})');
    } catch (_) { _message('Kartvizit okunamadı. Net ve iyi aydınlatılmış bir fotoğrafla tekrar deneyin.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _cropAndRecognize(XFile file) async {
    final selection = await Navigator.of(context).push<CropSelection>(
      MaterialPageRoute(builder: (_) => CropPage(imagePath: file.path)),
    );
    if (!mounted || selection == null) return;
    if (selection.bytes == null) {
      await _recognize(file);
      return;
    }
    final directory = await Directory.systemTemp.createTemp('kartvizit_crop_');
    try {
      final cropped = File('${directory.path}/card.png');
      await cropped.writeAsBytes(selection.bytes!);
      if (mounted) await _recognize(XFile(cropped.path));
    } finally {
      // Keep the preview until the edit screen closes; never delete the source.
      try { await directory.delete(recursive: true); } on FileSystemException { /* Cache cleanup can be retried by the OS. */ }
    }
  }
  Future<void> _recognize(XFile file) async {
    final reader = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await reader.processImage(InputImage.fromFilePath(file.path));
      if (!mounted) return;
      if (result.text.trim().isEmpty) { _message('Yazı bulunamadı. Fotoğrafı yakından ve net çekin.'); return; }
      final data = CardParser().parse(result.text);
      String previewPath = file.path;
      ArchivedCard? archivedCard;
      try {
        archivedCard = await _archive.saveScan(
          sourceImagePath: file.path,
          data: data,
          rawText: result.text,
        );
        previewPath = archivedCard.imagePath;
      } catch (_) {
        _message('Kartvizit okundu fakat uygulama arşivine kaydedilemedi.');
      }
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EditPage(
        data: data,
        raw: result.text,
        imagePath: previewPath,
        onDataChanged: archivedCard == null
            ? null
            : (updated) => _archive.updateCardData(archivedCard!.id, updated),
      )));
    } finally { await reader.close(); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kartvizit Cep', style: TextStyle(fontFamily: 'CaveatBrush', fontSize: 30, fontWeight: FontWeight.w400, color: Color(0xFFEAFBFF), letterSpacing: 0.3))),
    body: TechBackground(child: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560),
      child: ListView(padding: const EdgeInsets.all(24), children: [
        TechPanel(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const TechBadge(label: 'SMART CONTACT ENGINE', icon: Icons.auto_awesome_rounded),
          const SizedBox(height: 22),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF7B61FF)]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0x6600D9FF), blurRadius: 22)]),
              child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 36)),
            const Spacer(),
            const Icon(Icons.show_chart_rounded, color: Color(0xFF67F2C4), size: 42),
          ]),
          const SizedBox(height: 22),
          const Text('Yeni tanışmalar,\nhep elinin altında.', style: TextStyle(fontFamily: 'Caveat', color: Colors.white, fontSize: 44, fontWeight: FontWeight.w700, height: 1.05, fontVariations: [FontVariation('wght', 700)])),
          const SizedBox(height: 13),
          const Text('Kartviziti tara, bilgileri kontrol et ve rehberine kaydet.', style: TextStyle(color: Color(0xFFB8CDE5), fontSize: 17)),
          const SizedBox(height: 20),
          const Wrap(spacing: 9, runSpacing: 9, children: [
            TechBadge(label: 'OCR', icon: Icons.center_focus_strong_rounded),
            TechBadge(label: 'GALERİ', icon: Icons.collections_bookmark_rounded),
            TechBadge(label: 'REHBER', icon: Icons.contacts_rounded),
          ]),
        ])),
        const SizedBox(height: 28),
        VividButton(onPressed: _busy ? null : () => _scan(ImageSource.camera), icon: Icons.camera_alt_rounded, label: 'Kartvizit tara', accent: const Color(0xFF45E9F5)),
        const SizedBox(height: 12),
        VividButton(onPressed: _busy ? null : () => _scan(ImageSource.gallery), icon: Icons.photo_library_rounded, label: 'Fotoğraflardan seç', accent: const Color(0xFF9B7BFF)),
        const SizedBox(height: 12),
        VividButton(
          onPressed: _busy ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => ArchivePage(service: _archive),
          )),
          icon: Icons.collections_bookmark_rounded,
          label: 'Kartvizit Galerisi',
          accent: const Color(0xFF67F2C4),
        ),
        const SizedBox(height: 12),
        VividButton(onPressed: _busy ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EditPage(data: CardData()))), icon: Icons.edit_note_rounded, label: 'Bilgileri elle gir', accent: const Color(0xFFFFC168)),
        if (_busy) const Padding(padding: EdgeInsets.all(20), child: Column(children: [CircularProgressIndicator(), SizedBox(height: 12), Text('Kartvizit okunuyor…')])),
        const SizedBox(height: 24),
        const TechPanel(child: ListTile(contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.verified_user_rounded, color: Color(0xFF67F2C4), size: 34),
          title: Text('Veriler cihazında güvende', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEAFBFF))),
          subtitle: Text('Okunan ad, şirket ve numaraları kaydetmeden önce kontrol et.'))),
      ]))))),
  );
}

class ArchivePage extends StatefulWidget {
  final CardArchiveService service;
  const ArchivePage({super.key, required this.service});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  late Future<List<ArchivedCard>> _cards;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reload();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _reload() => _cards = widget.service.loadCards();

  String _date(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}.${two(value.month)}.${value.year}  ${two(value.hour)}:${two(value.minute)}';
  }

  String _searchKey(String value) {
    var result = value
        .replaceAll('İ', 'i')
        .replaceAll('I', 'i')
        .toLowerCase();
    const replacements = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
    };
    for (final entry in replacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result.trim();
  }

  Future<void> _open(ArchivedCard card) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EditPage(
      data: card.data,
      raw: card.rawText,
      imagePath: card.imagePath,
      onDataChanged: (updated) => widget.service.updateCardData(card.id, updated),
    )));
    if (mounted) setState(_reload);
  }

  Future<void> _delete(ArchivedCard card) async {
    final approved = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Kartviziti arşivden sil'),
      content: Text('${card.data.name.isNotEmpty ? card.data.name : card.data.company}\n\nBu işlem yalnızca uygulama arşivindeki fotoğrafı siler. Rehber kaydı etkilenmez.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Vazgeç')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Sil')),
      ],
    ));
    if (approved != true) return;
    await widget.service.deleteCard(card);
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kartvizit Galerisi')),
    body: TechBackground(child: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: FutureBuilder<List<ArchivedCard>>(
        future: _cards,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(28),
              child: Text('Kartvizit arşivi açılamadı.'),
            ));
          }
          final allCards = snapshot.data ?? const <ArchivedCard>[];
          if (allCards.isEmpty) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.collections_bookmark_outlined, size: 76, color: Color(0xFF6550C7)),
                SizedBox(height: 20),
                Text('Arşiv henüz boş', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('Taradığın kartvizitler otomatik olarak burada saklanır.', textAlign: TextAlign.center),
              ]),
            ));
          }
          final query = _searchKey(_searchController.text);
          final cards = query.isEmpty
              ? allCards
              : allCards.where((card) =>
                  _searchKey(card.data.name).contains(query) ||
                  _searchKey(card.data.company).contains(query)).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Ad soyad veya şirket ara',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Aramayı temizle',
                            onPressed: _searchController.clear,
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    query.isEmpty ? '${allCards.length} kartvizit' : '${cards.length} sonuç',
                    style: const TextStyle(color: Color(0xFF8FEAF4), fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Expanded(
                child: cards.isEmpty
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.search_off_rounded, size: 64, color: Color(0xFF777A91)),
                          SizedBox(height: 14),
                          Text('Eşleşen kartvizit bulunamadı',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                        ]),
                      ))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                        itemCount: cards.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          final title = card.data.name.isNotEmpty ? card.data.name : card.data.company;
                          final subtitle = card.data.name.isNotEmpty && card.data.company.isNotEmpty
                              ? card.data.company
                              : 'Kartvizit kaydı';
                          return Card(
                            elevation: 8,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                              side: const BorderSide(color: Color(0x553BE7F3)),
                            ),
                            child: InkWell(
                              onTap: () => _open(card),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                Container(
                                  color: const Color(0xFF0B1526),
                                  height: 180,
                                  child: Image.file(
                                    File(card.imagePath),
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.broken_image_outlined, size: 56),
                                  ),
                                ),
                                ListTile(
                                  contentPadding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
                                  title: Text(title.isEmpty ? 'İsimsiz kartvizit' : title,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  subtitle: Text('$subtitle\n${_date(card.createdAt)}'),
                                  isThreeLine: true,
                                  trailing: IconButton(
                                    tooltip: 'Arşivden sil',
                                    onPressed: () => _delete(card),
                                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF7085)),
                                  ),
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    )))),
  );
}

class EditPage extends StatefulWidget {
  final CardData data;
  final String raw;
  final String? imagePath;
  final Future<void> Function(CardData data)? onDataChanged;
  const EditPage({
    super.key,
    required this.data,
    this.raw = '',
    this.imagePath,
    this.onDataChanged,
  });
  @override State<EditPage> createState() => _EditPageState();
}
class _EditPageState extends State<EditPage> {
  final _form = GlobalKey<FormState>();
  late final List<TextEditingController> _fields;
  bool _saving = false;
  String? _savedId;
  bool _openedExisting = false;
  @override void initState() {
    super.initState(); final d = widget.data;
    String group(PhoneKind kind) => d.phones.where((p) => (d.phoneKinds[p] ?? inferPhoneKind(p)) == kind).join('\n');
    _fields = [d.name, d.company, d.title, group(PhoneKind.mobile), d.email, d.website, d.address,
      group(PhoneKind.work), group(PhoneKind.other)].map((s) => TextEditingController(text: s)).toList();
  }
  @override void dispose() { for (final c in _fields) { c.dispose(); } super.dispose(); }
  String _v(int i) => _fields[i].text.trim();
  void _message(String s) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s))); }
  CardData? _currentData({required bool requireContactDetails}) {
    if (!_form.currentState!.validate()) return null;
    if (_v(0).isEmpty && _v(1).isEmpty) { _message('Ad soyad veya şirket adı girin.'); return null; }
    final kinds = <String, PhoneKind>{};
    for (final entry in {3: PhoneKind.mobile, 7: PhoneKind.work, 8: PhoneKind.other}.entries) {
      for (final line in _v(entry.key).split('\n').where((s) => s.trim().isNotEmpty)) {
        final number = normalizePhone(line);
        if (kinds.containsKey(number)) { _message('Aynı numarayı yalnızca bir telefon alanına yazın.'); return null; }
        kinds[number] = entry.value;
      }
    }
    final phones = kinds.keys.toList();
    if (requireContactDetails && phones.isEmpty && _v(4).isEmpty) {
      _message('En az bir telefon veya e-posta girin.');
      return null;
    }
    return CardData(name: _v(0), company: _v(1), title: _v(2), phones: phones,
      phoneKinds: kinds, email: _v(4), website: _v(5), address: _v(6));
  }
  Future<void> _saveToGallery() async {
    if (_saving || widget.onDataChanged == null) return;
    final data = _currentData(requireContactDetails: false);
    if (data == null) return;
    setState(() => _saving = true);
    try {
      await widget.onDataChanged!(data);
      _message('Galeri bilgileri güncellendi.');
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
      } catch (_) {
        _message('Düzeltilen bilgiler arşive kaydedilemedi; rehber kaydına devam ediliyor.');
      }
      final permission = await FlutterContacts.permissions.request(PermissionType.readWrite);
      if (!mounted) return;
      if (permission != PermissionStatus.granted) {
        await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Rehber erişimi gerekli'),
          content: const Text('Kayıt ve mükerrer kontrolü için tam rehber erişimi verin. Sınırlı erişimde tüm numaraları kontrol edemiyoruz.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
            TextButton(onPressed: () { Navigator.pop(ctx); FlutterContacts.permissions.openSettings(); }, child: const Text('Ayarları aç'))]));
        return;
      }
      final keys = data.phones.map(phoneKey).toSet();
      final all = await FlutterContacts.getAll(properties: {ContactProperty.phone, ContactProperty.email});
      final matches = all.where((c) => c.phones.any((p) => keys.contains(phoneKey(p.number))) ||
        (_v(4).isNotEmpty && c.emails.any((e) => e.address.toLowerCase() == _v(4).toLowerCase()))).toList();
      if (!mounted) return;
      if (matches.isNotEmpty) {
        final action = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Bu kişi rehberde olabilir'), content: const Text('Aynı telefon veya e-posta bulundu. Kartvizitteki eksik bilgileri mevcut kişiye ekleyebilir, kişiyi olduğu gibi açabilir ya da ayrı kayıt oluşturabilirsiniz.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'edit'), child: const Text('Mevcut kişiyi aç')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'merge'), child: const Text('Bilgileri mevcut kişiye ekle')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'new'), child: const Text('Ayrı kayıt oluştur'))]));
        if (action == 'edit') { await _editExistingContact(matches.first.id!); return; }
        if (action == 'merge') { await _mergeIntoExistingContact(matches.first.id!, data); return; }
        if (action != 'new') return;
      }
      final contacts = FlutterContacts.vCard.import(data.toVCard());
      if (contacts.length != 1) throw StateError('Invalid contact');
      final id = await FlutterContacts.create(contacts.single);
      if (mounted) setState(() => _savedId = id);
    } catch (_) { _message('Kayıt tamamlanamadı. Rehberi kontrol edin; izinleri ve alanları gözden geçirip tekrar deneyin.'); }
    finally { if (mounted) setState(() => _saving = false); }
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
      _message('Mevcut kişi açılamadı. Rehber erişimini kontrol edip tekrar deneyin.');
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
      _message('Mevcut kişi güncellenemedi. Rehber erişimini kontrol edip tekrar deneyin.');
    }
  }
  @override Widget build(BuildContext context) => PopScope(canPop: !_saving, child: Scaffold(
    appBar: AppBar(title: Text(_savedId == null ? 'Kişi bilgilerini kontrol et' : _openedExisting ? 'Mevcut kişi' : 'Kayıt tamamlandı')),
    body: TechBackground(child: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600),
      child: _savedId != null ? ListView(padding: const EdgeInsets.all(28), children: [
        const SizedBox(height: 40), Icon(_openedExisting ? Icons.person_outline : Icons.check_circle, size: 88, color: const Color(0xFF67F2C4)),
        const SizedBox(height: 24), Text(_openedExisting ? 'Mevcut kişiyle devam edildi' : 'Rehbere kaydedildi', textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12), Text(_openedExisting ? 'Değişiklikleri rehberin düzenleme ekranında kaydettiysen işlem tamam. Rehberde göster ile kontrol edebilirsin.' : (_v(0).isEmpty ? _v(1) : _v(0)), textAlign: TextAlign.center), const SizedBox(height: 32),
        if (_openedExisting) OutlinedButton(onPressed: () => _editExistingContact(_savedId!), child: const Text('Kişiyi tekrar düzenle')),
        FilledButton(onPressed: () async { try { await FlutterContacts.native.showViewer(_savedId!); } catch (_) { _message('Rehber açılamadı. Telefonun Kişiler uygulamasından kontrol edebilirsiniz.'); } }, child: const Text('Rehberde göster')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Yeni kartvizit tara')),
      ]) : Form(key: _form, child: ListView(padding: const EdgeInsets.all(20), children: [
        ContactQuickActions(fields: _fields),
        const SizedBox(height: 16),
        if (widget.imagePath != null) TechPanel(padding: const EdgeInsets.all(10), child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(widget.imagePath!), height: 170, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Text('Fotoğraf önizlemesi açılamadı.')))),
        if (widget.onDataChanged != null) TechPanel(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(14),
          child: const Row(children: [
            Icon(Icons.collections_bookmark_rounded, color: Color(0xFF67F2C4)),
            SizedBox(width: 10),
            Expanded(child: Text(
              'Bu kart uygulama galerisinde saklanıyor. Rehbere yalnızca aşağıdaki düğmeyle eklenir.',
              style: TextStyle(color: Color(0xFFD7F7F4), fontWeight: FontWeight.w600),
            )),
          ]),
        ),
        const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('Otomatik doldurulan alanlar tahmindir. Özellikle isim ve telefonları kontrol edin.')),
        for (final i in [0, 1, 2, 3, 7, 8, 4, 5, 6]) Padding(padding: const EdgeInsets.only(bottom: 16), child: TextFormField(
          controller: _fields[i], enabled: !_saving, style: const TextStyle(fontSize: 18),
          minLines: 1, maxLines: [3, 6, 7, 8].contains(i) ? 4 : 1,
          keyboardType: [3, 7, 8].contains(i) ? TextInputType.multiline : i == 4 ? TextInputType.emailAddress : i == 5 ? TextInputType.url : TextInputType.text,
          decoration: InputDecoration(labelText: ['Ad soyad', 'Şirket', 'Unvan', 'Cep telefonu', 'E-posta', 'Web sitesi', 'Adres', 'Sabit / iş telefonu', 'Diğer telefonlar'][i]),
          validator: (s) {
            final value = (s ?? '').trim();
            if (i == 4 && value.isNotEmpty && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) return 'Geçerli bir e-posta girin.';
            if ([3, 7, 8].contains(i) && value.isNotEmpty && value.split('\n').where((p) => p.trim().isNotEmpty).any((p) => !RegExp(r'^\+?[\d\s().-]+$').hasMatch(p.trim()) || phoneKey(p).length < 10 || phoneKey(p).length > 15)) return 'Her satıra geçerli bir telefon numarası girin.';
            return null;
          })),
        if (widget.raw.isNotEmpty) ExpansionTile(title: const Text('Kartvizitte okunan tüm metin'), children: [Padding(padding: const EdgeInsets.all(16), child: SelectableText(widget.raw))]),
        const SizedBox(height: 20),
        if (widget.onDataChanged != null) ...[
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            onPressed: _saving ? null : _saveToGallery,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Galeri bilgilerini güncelle', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
        ],
        VividButton(onPressed: _saving ? null : _save, icon: Icons.person_add_alt_1, label: _saving ? 'Kaydediliyor…' : 'Rehbere kaydet'),
        const SizedBox(height: 24),
      ])),
    )))),
  ));
}
