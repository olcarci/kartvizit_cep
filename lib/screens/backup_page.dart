import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/backup_codec.dart';
import '../services/card_archive_service.dart';
import '../services/file_transfer_service.dart';
import '../widgets/tech_background.dart';

class BackupPage extends StatefulWidget {
  final CardArchiveService service;
  const BackupPage({super.key, required this.service});
  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _busy = false;
  String? _status;
  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(
          () => _status = error is FormatException ? error.message : 'İşlem tamamlanamadı. Dosyayı ve kullanılabilir depolama alanını kontrol edin.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _backup() => _run(() async {
    final bundle = await widget.service.createBackup();
    if (!mounted) return;
    if (bundle.entries.isEmpty && bundle.personalCard == null) {
      setState(() => _status = 'Yedeklenecek kartvizit yok.');
      return;
    }
    if (bundle.missingImages + bundle.missingPersonalAvatar > 0) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eksik fotoğraflar'),
          content: Text(
            '${bundle.missingImages + bundle.missingPersonalAvatar} fotoğraf bulunamadı. Metin bilgileri yine yedeklenecek.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Devam et'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    final bytes = await Isolate.run(() => bundle.encode());
    final date = DateTime.now().toIso8601String().replaceAll(':', '-');
    final saved = await FileTransferService.save(
      bytes,
      'kartvizit-yedek-$date.json',
      'application/json',
    );
    if (mounted) {
      setState(
        () => _status = saved
            ? '${bundle.entries.length} arşiv kartı yedeklendi.${bundle.personalCard != null ? ' Kişisel kartvizitiniz de yedeğe eklendi.' : ''}'
            : 'Kaydetme iptal edildi.',
      );
    }
  });

  Future<void> _restore() => _run(() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Kartvizit Cep yedeğini seç',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (file == null) return;
    final size = await file.length();
    if (size != null && size > BackupBundle.maxBytes) {
      throw const FormatException('Yedek 64 MB sınırını aşıyor.');
    }
    final bytes = await file.readAsBytes();
    if (size == null && bytes.length > BackupBundle.maxBytes) {
      throw const FormatException('Yedek 64 MB sınırını aşıyor.');
    }
    final bundle = await CardArchiveService.readBackup(bytes);
    final current = (await widget.service.loadCards())
        .map((card) => card.id)
        .toSet();
    final skipped = bundle.entries
        .where((entry) => current.contains(entry.card.id))
        .length;
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yedeği geri yükle'),
        content: SingleChildScrollView(
          child: Text(
            '${bundle.entries.length - skipped} yeni kart eklenecek. $skipped mevcut kayıt korunarak atlanacak.\n\n'
            '${bundle.missingImages + bundle.missingPersonalAvatar} fotoğraf bulunamadı.\n\n'
            '${bundle.personalCard != null ? 'Kişisel kartvizit de var; cihazda zaten varsa mevcut kart korunur.\n\n' : ''}'
            'Mevcut kartlarınız silinmez veya değiştirilmez. Hatırlatma bilgileri taşınır; bildirimleri kişi profilinden yeniden kurmanız gerekir.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Geri yükle'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await widget.service.restoreBackup(bundle);
    if (mounted) {
      setState(
        () => _status =
            '${result.added} kart eklendi, ${result.skipped} mevcut kart korundu. ${result.personalStatus ?? ''}',
      );
    }
  });

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Yedekleme ve geri yükleme')),
      body: TechBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const TechPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.backup_outlined, size: 40),
                        SizedBox(height: 16),
                        Text(
                          'Kartvizitlerin yanında olsun',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Ön/arka yüz fotoğrafları, kişi bilgileri, notlar, etiketler, favoriler, hatırlatmalar ve kişisel kartvizitiniz tek dosyada saklanır.',
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Dosya şifrelenmez; kişisel bilgiler ve notlar içerir. Kendi güvenli depolama alanınıza kaydedin.',
                        ),
                        SizedBox(height: 12),
                        Text(
                          'En fazla 2000 kart, fotoğraf başına 12 MB ve toplam 64 MB yedek desteklenir.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _busy ? null : _backup,
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Yedek oluştur ve kaydet'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _restore,
                    icon: const Icon(Icons.restore),
                    label: const Text('Dosyadan geri yükle'),
                  ),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (_status != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(_status!, semanticsLabel: _status),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
