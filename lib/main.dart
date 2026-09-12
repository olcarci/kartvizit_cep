import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'models/card_data.dart';
import 'services/card_parser.dart';

void main() { WidgetsFlutterBinding.ensureInitialized(); runApp(const KartvizitApp()); }

class KartvizitApp extends StatelessWidget {
  const KartvizitApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Kartvizit Cep', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF126B62)),
      scaffoldBackgroundColor: const Color(0xFFF3F6F5),
      textTheme: const TextTheme(bodyLarge: TextStyle(fontSize: 18), bodyMedium: TextStyle(fontSize: 16)),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
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
        await _recognize(result.files!.first);
      } else if (result.exception != null) { _message('Önceki fotoğraf alınamadı. Yeniden seçebilirsiniz.'); }
    } catch (_) { _message('Önceki fotoğraf kurtarılamadı. Yeniden tarayabilirsiniz.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _scan(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await _picker.pickImage(source: source, maxWidth: 2400, imageQuality: 95, requestFullMetadata: false);
      if (file != null && mounted) await _recognize(file);
    } on PlatformException catch (e) {
      _message('Fotoğrafa erişilemedi. Kamera/fotoğraf izinlerini telefon ayarlarından kontrol edin. (${e.code})');
    } catch (_) { _message('Kartvizit okunamadı. Net ve iyi aydınlatılmış bir fotoğrafla tekrar deneyin.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _recognize(XFile file) async {
    final reader = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await reader.processImage(InputImage.fromFilePath(file.path));
      if (!mounted) return;
      if (result.text.trim().isEmpty) { _message('Yazı bulunamadı. Fotoğrafı yakından ve net çekin.'); return; }
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EditPage(
        data: CardParser().parse(result.text), raw: result.text, imagePath: file.path)));
    } finally { await reader.close(); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kartvizit Cep')),
    body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560),
      child: ListView(padding: const EdgeInsets.all(24), children: [
        Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: const Color(0xFF123D38), borderRadius: BorderRadius.circular(28)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.document_scanner_outlined, color: Color(0xFFA9EBCB), size: 56), SizedBox(height: 24),
            Text('Yeni tanışmalar,\nhep elinin altında.', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, height: 1.15)),
            SizedBox(height: 16), Text('Kartviziti tara, bilgileri kontrol et ve rehberine kaydet.', style: TextStyle(color: Color(0xFFD3E8E0), fontSize: 18)),
          ])),
        const SizedBox(height: 28),
        FilledButton.icon(onPressed: _busy ? null : () => _scan(ImageSource.camera), icon: const Icon(Icons.camera_alt_outlined), label: const Text('Kartvizit tara')),
        const SizedBox(height: 12),
        OutlinedButton.icon(style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
          onPressed: _busy ? null : () => _scan(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text('Galeriden seç', style: TextStyle(fontSize: 18))),
        const SizedBox(height: 12),
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EditPage(data: CardData()))), child: const Text('Bilgileri elle gir')),
        if (_busy) const Padding(padding: EdgeInsets.all(20), child: Column(children: [CircularProgressIndicator(), SizedBox(height: 12), Text('Kartvizit okunuyor…')])),
        const SizedBox(height: 24),
        const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.fact_check_outlined), title: Text('Son kontrol sende'), subtitle: Text('Okunan ad, şirket ve numaraları kaydetmeden önce kontrol et.')),
      ])))),
  );
}

class EditPage extends StatefulWidget {
  final CardData data;
  final String raw;
  final String? imagePath;
  const EditPage({super.key, required this.data, this.raw = '', this.imagePath});
  @override State<EditPage> createState() => _EditPageState();
}
class _EditPageState extends State<EditPage> {
  final _form = GlobalKey<FormState>();
  late final List<TextEditingController> _fields;
  bool _saving = false;
  String? _savedId;
  @override void initState() {
    super.initState(); final d = widget.data;
    String group(PhoneKind kind) => d.phones.where((p) => (d.phoneKinds[p] ?? inferPhoneKind(p)) == kind).join('\n');
    _fields = [d.name, d.company, d.title, group(PhoneKind.mobile), d.email, d.website, d.address,
      group(PhoneKind.work), group(PhoneKind.other)].map((s) => TextEditingController(text: s)).toList();
  }
  @override void dispose() { for (final c in _fields) { c.dispose(); } super.dispose(); }
  String _v(int i) => _fields[i].text.trim();
  void _message(String s) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s))); }
  Future<void> _save() async {
    if (_saving || _savedId != null || !_form.currentState!.validate()) return;
    if (_v(0).isEmpty && _v(1).isEmpty) { _message('Ad soyad veya şirket adı girin.'); return; }
    final kinds = <String, PhoneKind>{};
    for (final entry in {3: PhoneKind.mobile, 7: PhoneKind.work, 8: PhoneKind.other}.entries) {
      for (final line in _v(entry.key).split('\n').where((s) => s.trim().isNotEmpty)) {
        final number = normalizePhone(line);
        if (kinds.containsKey(number)) { _message('Aynı numarayı yalnızca bir telefon alanına yazın.'); return; }
        kinds[number] = entry.value;
      }
    }
    final phones = kinds.keys.toList();
    if (phones.isEmpty && _v(4).isEmpty) { _message('En az bir telefon veya e-posta girin.'); return; }
    setState(() => _saving = true);
    try {
      final permission = await FlutterContacts.permissions.request(PermissionType.readWrite);
      if (!mounted) return;
      if (permission != PermissionStatus.granted) {
        await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Rehber erişimi gerekli'),
          content: const Text('Kayıt ve mükerrer kontrolü için tam rehber erişimi verin. Sınırlı erişimde tüm numaraları kontrol edemiyoruz.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
            TextButton(onPressed: () { Navigator.pop(ctx); FlutterContacts.permissions.openSettings(); }, child: const Text('Ayarları aç'))]));
        return;
      }
      final keys = phones.map(phoneKey).toSet();
      final all = await FlutterContacts.getAll(properties: {ContactProperty.phone, ContactProperty.email});
      final matches = all.where((c) => c.phones.any((p) => keys.contains(phoneKey(p.number))) ||
        (_v(4).isNotEmpty && c.emails.any((e) => e.address.toLowerCase() == _v(4).toLowerCase()))).toList();
      if (!mounted) return;
      if (matches.isNotEmpty) {
        final action = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Bu kişi rehberde olabilir'), content: const Text('Aynı telefon veya e-posta bulundu. Mevcut kişiyi açıp düzenleyebilir ya da ayrı kayıt oluşturabilirsiniz.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'edit'), child: const Text('Mevcut kişiyi aç')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'new'), child: const Text('Ayrı kayıt oluştur'))]));
        if (action == 'edit') { await FlutterContacts.native.showEditor(matches.first.id!); return; }
        if (action != 'new') return;
      }
      final data = CardData(name: _v(0), company: _v(1), title: _v(2), phones: phones, phoneKinds: kinds, email: _v(4), website: _v(5), address: _v(6));
      final contacts = FlutterContacts.vCard.import(data.toVCard());
      if (contacts.length != 1) throw StateError('Invalid contact');
      final id = await FlutterContacts.create(contacts.single);
      if (mounted) setState(() => _savedId = id);
    } catch (_) { _message('Kayıt tamamlanamadı. Rehberi kontrol edin; izinleri ve alanları gözden geçirip tekrar deneyin.'); }
    finally { if (mounted) setState(() => _saving = false); }
  }
  @override Widget build(BuildContext context) => PopScope(canPop: !_saving, child: Scaffold(
    appBar: AppBar(title: Text(_savedId == null ? 'Kişi bilgilerini kontrol et' : 'Kayıt tamamlandı')),
    body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600),
      child: _savedId != null ? ListView(padding: const EdgeInsets.all(28), children: [
        const SizedBox(height: 40), const Icon(Icons.check_circle, size: 88, color: Color(0xFF126B62)),
        const SizedBox(height: 24), const Text('Rehbere kaydedildi', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12), Text(_v(0).isEmpty ? _v(1) : _v(0), textAlign: TextAlign.center), const SizedBox(height: 32),
        FilledButton(onPressed: () async { try { await FlutterContacts.native.showViewer(_savedId!); } catch (_) { _message('Rehber açılamadı. Telefonun Kişiler uygulamasından kontrol edebilirsiniz.'); } }, child: const Text('Rehberde göster')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Yeni kartvizit tara')),
      ]) : Form(key: _form, child: ListView(padding: const EdgeInsets.all(20), children: [
        if (widget.imagePath != null) ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(File(widget.imagePath!), height: 170, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Text('Fotoğraf önizlemesi açılamadı.'))),
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
        const SizedBox(height: 20), FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.person_add_alt_1), label: Text(_saving ? 'Kaydediliyor…' : 'Rehbere kaydet')),
        const SizedBox(height: 24),
      ])),
    ))),
  ));
}
