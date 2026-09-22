import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/edit_page.dart';
export 'screens/edit_page.dart';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'models/card_data.dart';
import 'models/archived_card.dart';
import 'services/card_archive_service.dart';

import 'services/card_parser.dart';
import 'screens/crop_page.dart';
import 'screens/card_detail_page.dart';
import 'screens/batch_scan_page.dart';
import 'screens/personal_card_page.dart';
import 'services/scan_queue.dart';
import 'screens/backup_page.dart';
import 'screens/export_page.dart';
import 'screens/archive_filter_dialog.dart';
import 'screens/reminder_dialog.dart';
import 'screens/reminders_page.dart';
import 'screens/settings_help_page.dart';
import 'services/archive_query.dart';
import 'services/reminder_service.dart';
import 'widgets/archive_overview.dart';
import 'widgets/tech_background.dart';
import 'widgets/ivory_button.dart';
import 'widgets/ivory_decoration.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KartvizitApp());
}

class KartvizitApp extends StatelessWidget {
  final CardArchiveService? archiveService;
  const KartvizitApp({super.key, this.archiveService});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Kartvizit Cep',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Manrope',
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF174B40),
        brightness: Brightness.light,
        primary: const Color(0xFF174B40),
        secondary: const Color(0xFF8A692F),
        surface: const Color(0xFFFFFDF8),
      ),
      scaffoldBackgroundColor: const Color(0xFFF6F5F0),
      canvasColor: const Color(0xFFFFFDF8),
      dividerColor: const Color(0xFFE4D9C7),
      iconTheme: const IconThemeData(color: Color(0xFF8A692F)),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFFFFDF8),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE4D9C7)),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Lora',
          fontSize: 23,
          fontWeight: FontWeight.w600,
          color: Color(0xFF10382F),
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 15,
          height: 1.5,
          color: Color(0xFF2F4039),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFFFFFDF8),
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFFFFFDF8),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE4D9C7)),
        ),
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: Color(0xFFFFFDF8),
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: Color(0xFF174B40),
        headerForegroundColor: Colors.white,
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: Color(0xFFFFFDF8),
        dialBackgroundColor: Color(0xFFF0EBDF),
        dialHandColor: Color(0xFF174B40),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF174B40),
        contentTextStyle: TextStyle(fontFamily: 'Manrope', color: Colors.white),
        actionTextColor: Color(0xFFF0DDB2),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF0EBDF),
        selectedColor: const Color(0xFFDCE9DF),
        side: const BorderSide(color: Color(0xFFD6C6A7)),
        labelStyle: const TextStyle(
          fontFamily: 'Manrope',
          color: Color(0xFF10382F),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Color(0xFF8A692F),
        textColor: Color(0xFF10382F),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: Color(0xFF8A692F),
        collapsedIconColor: Color(0xFF8A692F),
        textColor: Color(0xFF10382F),
        collapsedTextColor: Color(0xFF10382F),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF6F5F0),
        foregroundColor: Color(0xFF10382F),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Lora',
          color: Color(0xFF10382F),
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFDF8),
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: const Color(0x33655333),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE4D9C7)),
        ),
      ),
      textTheme: const TextTheme(
        bodySmall: TextStyle(color: Color(0xFF3F4938)),
        titleLarge: TextStyle(color: Color(0xFF10382F)),
        titleMedium: TextStyle(color: Color(0xFF10382F)),
        titleSmall: TextStyle(color: Color(0xFF10382F)),
        labelLarge: TextStyle(color: Color(0xFF10382F)),
        labelMedium: TextStyle(color: Color(0xFF2F4039)),
        labelSmall: TextStyle(color: Color(0xFF2F4039)),
        bodyLarge: TextStyle(fontSize: 17, color: Color(0xFF1B2D27)),
        bodyMedium: TextStyle(fontSize: 15, color: Color(0xFF2F4039)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Color(0xFF2F4039)),
        hintStyle: const TextStyle(color: Color(0xFF505C52)),
        prefixIconColor: const Color(0xFF8A692F),
        suffixIconColor: const Color(0xFF8A692F),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD6C6A7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF174B40), width: 2),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          backgroundColor: const Color(0xFF174B40),
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: const Color(0x55655333),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: const Color(0xFFFFFDF8),
          foregroundColor: const Color(0xFF10382F),
          side: const BorderSide(color: Color(0xFFB99760)),
          elevation: 2,
          shadowColor: const Color(0x33655333),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF10382F),
          minimumSize: const Size(48, 48),
        ),
      ),
    ),
    home: HomePage(service: archiveService),
  );
}

class HomePage extends StatefulWidget {
  final CardArchiveService? service;
  const HomePage({super.key, this.service});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final _picker = ImagePicker();
  late final _archive = widget.service ?? CardArchiveService();
  int _archiveRevision = 0;
  bool _busy = false;
  int _section = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LocalReminderNotifications.instance.openedCard.addListener(
      _notificationOpened,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recover();
      _initializeNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LocalReminderNotifications.instance.openedCard.removeListener(
      _notificationOpened,
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() => _archiveRevision++);
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      await LocalReminderNotifications.instance.initialize();
      if (LocalReminderNotifications.instance.supported) {
        await ReminderService(_archive).reconcile();
      }
    } catch (_) {
      _message(
        'Bildirim sistemi başlatılamadı. Hatırlatmalarınızı uygulamadan kontrol edebilirsiniz.',
      );
    }
  }

  Future<void> _notificationOpened() async {
    final id = LocalReminderNotifications.instance.openedCard.value;
    if (id == null || id.isEmpty) return;
    LocalReminderNotifications.instance.openedCard.value = null;
    try {
      final card = (await _archive.loadCards())
          .where((card) => card.id == id)
          .firstOrNull;
      if (!mounted) return;
      if (card == null) {
        _message('Bu hatırlatmanın kartviziti artık arşivde yok.');
        return;
      }
      await _openCard(card);
    } catch (_) {
      _message('Hatırlatmaya ait kartvizit açılamadı.');
    }
  }

  Future<void> _backups() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BackupPage(service: _archive)),
    );
    if (mounted) setState(() => _archiveRevision++);
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _recover() async {
    if (!Platform.isAndroid) return;
    try {
      final result = await _picker.retrieveLostData();
      if (!mounted) return;
      if (result.files?.isNotEmpty == true) {
        setState(() => _busy = true);
        final files = result.files!;
        if (files.length > ScanQueue.limit) {
          _message(
            'Önceki seçimde 20’den fazla fotoğraf var. Toplu taramadan yeniden seçin.',
          );
          return;
        }
        final review = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Önceki fotoğraf seçimi bulundu'),
            content: Text(
              '${files.length} fotoğraf kurtarıldı. Bunları kartvizit olarak incelemek ister misiniz? Arka yüz veya logo seçiyorduysanız ilgili ekrandan yeniden seçebilirsiniz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Vazgeç'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('İncele'),
              ),
            ],
          ),
        );
        if (mounted && review == true) {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => BatchScanPage(
                paths: files.map((file) => file.path).toList(),
                archive: _archive,
              ),
            ),
          );
        }
      } else if (result.exception != null) {
        _message('Önceki fotoğraf alınamadı. Yeniden seçebilirsiniz.');
      }
    } catch (_) {
      _message('Önceki fotoğraf kurtarılamadı. Yeniden tarayabilirsiniz.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scan(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final XFile? file;
      try {
        file = await _picker.pickImage(
          source: source,
          maxWidth: 2400,
          imageQuality: 95,
          requestFullMetadata: false,
        );
      } on PlatformException catch (e) {
        _message(
          'Fotoğrafa erişilemedi. Kamera/fotoğraf izinlerini telefon ayarlarından kontrol edin. (${e.code})',
        );
        return;
      }
      if (file != null && mounted) await _cropAndRecognize(file);
    } catch (e) {
      _message(
        'Kartvizit okunamadı. Net ve iyi aydınlatılmış bir fotoğrafla tekrar deneyin. ($e)',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _batchScan() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final files = await _picker.pickMultiImage(
        maxWidth: 2400,
        imageQuality: 95,
        requestFullMetadata: false,
        limit: ScanQueue.limit,
      );
      if (!mounted || files.isEmpty) return;
      if (files.length > ScanQueue.limit) {
        _message('Bir seferde en fazla 20 fotoğraf seçin.');
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BatchScanPage(
            paths: files.map((file) => file.path).toList(),
            archive: _archive,
          ),
        ),
      );
    } catch (_) {
      _message('Fotoğraflar seçilemedi. İzinleri kontrol edip tekrar deneyin.');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _archiveRevision++;
        });
      }
    }
  }

  Future<void> _personalCard() => Navigator.of(context)
      .push<void>(MaterialPageRoute(builder: (_) => const PersonalCardPage()));

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
      try {
        await directory.delete(recursive: true);
      } on FileSystemException {
        /* Cache cleanup can be retried by the OS. */
      }
    }
  }

  Future<void> _recognize(XFile file) async {
    final reader = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await reader.processImage(
        InputImage.fromFilePath(file.path),
      );
      if (!mounted) return;
      if (result.text.trim().isEmpty) {
        _message('Yazı bulunamadı. Fotoğrafı yakından ve net çekin.');
        return;
      }
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
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EditPage(
            data: data,
            raw: result.text,
            imagePath: previewPath,
            onDataChanged: archivedCard == null
                ? null
                : (updated) =>
                      _archive.updateCardData(archivedCard!.id, updated),
          ),
        ),
      );
    } finally {
      await reader.close();
      if (mounted) setState(() => _archiveRevision++);
    }
  }

  Future<void> _openArchive({
    bool favorites = false,
    bool reminders = false,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArchivePage(
          service: _archive,
          favoritesOnly: favorites,
          reminderFilter: reminders
              ? ReminderFilter.pending
              : ReminderFilter.all,
        ),
      ),
    );
    if (mounted) setState(() => _archiveRevision++);
  }

  Future<void> _openCard(ArchivedCard card) async {
    await openCardProfile(context, card, _archive);
    if (mounted) setState(() => _archiveRevision++);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _section == 0,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) setState(() => _section = 0);
    },
    child: Scaffold(
      backgroundColor: const Color(0xFFF6F5F0),
      bottomNavigationBar: IvoryNavigation(
        selected: _section,
        onSelected: _busy
            ? null
            : (index) => setState(() {
                _section = index;
                _archiveRevision++;
              }),
      ),
      body: switch (_section) {
        1 => ArchivePage(service: _archive),
        2 => RemindersPage(
          service: _archive,
          onOpen: _openCard,
          onArchive: () => setState(() => _section = 1),
        ),
        3 => const PersonalCardPage(),
        4 => SettingsHelpPage(
          onBackups: _backups,
          onReminders: () => setState(() => _section = 2),
        ),
        _ => _homeContent(context),
      },
    ),
  );

  Widget _homeContent(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Kartvizit Cep'),
      actions: [
        IconButton(
          onPressed: _busy ? null : _backups,
          tooltip: 'Yedekleme ve geri yükleme',
          icon: const Icon(Icons.backup_outlined),
        ),
        IconButton(
          onPressed: _busy ? null : _personalCard,
          tooltip: 'Kartvizitim',
          icon: const Icon(Icons.badge_outlined),
        ),
      ],
    ),
    body: TechBackground(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                const TechBadge(
                  label: 'BAĞLANTILARINIZ BİR ARADA',
                  icon: Icons.auto_awesome_outlined,
                ),
                const SizedBox(height: 24),
                const IvoryHero(),
                const SizedBox(height: 18),
                const Text(
                  'Kartvizitlerini tek tek veya topluca tara; notlar, etiketler ve favorilerle kişilerini düzenle. Hatırlatmalarla iletişimi sürdür, kendi QR kartvizitini kolayca paylaş.',
                  style: TextStyle(fontSize: 15, height: 1.65),
                ),
                const SizedBox(height: 20),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TechBadge(label: 'OCR', icon: Icons.center_focus_strong),
                    TechBadge(
                      label: 'GALERİ',
                      icon: Icons.collections_bookmark_outlined,
                    ),
                    TechBadge(label: 'REHBER', icon: Icons.contacts_outlined),
                  ],
                ),
                const SizedBox(height: 24),
                IvoryButton(
                  label: 'Kartvizit tara',
                  icon: Icons.camera_alt_outlined,
                  selected: true,
                  onPressed: _busy ? null : () => _scan(ImageSource.camera),
                ),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final single =
                        constraints.maxWidth < 280 ||
                        MediaQuery.textScalerOf(context).scale(14) > 21;
                    final width = single
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 16) / 2;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 18,
                      children: [
                        SizedBox(
                          width: width,
                          child: IvoryButton(
                            label: 'Fotoğraflardan seç',
                            icon: Icons.photo_library_outlined,
                            onPressed: _busy
                                ? null
                                : () => _scan(ImageSource.gallery),
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: IvoryButton(
                            label: 'Toplu tarama',
                            icon: Icons.layers_outlined,
                            onPressed: _busy ? null : _batchScan,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: IvoryButton(
                            label: 'Bilgileri elle gir',
                            icon: Icons.edit_note,
                            onPressed: _busy
                                ? null
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          EditPage(data: CardData()),
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: IvoryButton(
                            label: 'QR kartım',
                            icon: Icons.qr_code_2,
                            onPressed: _busy ? null : _personalCard,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                TextButton.icon(
                  onPressed: _busy ? null : () => _openArchive(),
                  icon: const Icon(Icons.contacts_outlined),
                  label: const Text('Kartvizit Galerisi'),
                ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Kartvizit okunuyor…'),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                ArchiveOverview(
                  service: _archive,
                  revision: _archiveRevision,
                  onOpen: _openCard,
                  onArchive: () => _openArchive(),
                  onFavorites: () => _openArchive(favorites: true),
                  onReminders: () => setState(() => _section = 2),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Okunan ad, şirket ve numaraları kaydetmeden önce kontrol et.',
                  textAlign: TextAlign.center,
                ),
                const IvoryFooter(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class ArchivePage extends StatefulWidget {
  final CardArchiveService service;
  final bool favoritesOnly;
  final ReminderFilter reminderFilter;
  const ArchivePage({
    super.key,
    required this.service,
    this.favoritesOnly = false,
    this.reminderFilter = ReminderFilter.all,
  });

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  late Future<List<ArchivedCard>> _cards;
  final _searchController = TextEditingController();
  late bool _favoritesOnly = widget.favoritesOnly;
  String? _selectedTag;
  late ArchiveFilters _filters = ArchiveFilters(
    reminders: widget.reminderFilter,
  );

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

  void _reload() {
    _cards = widget.service.loadCards();
  }

  String _date(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}.${two(value.month)}.${value.year}  ${two(value.hour)}:${two(value.minute)}';
  }

  Future<void> _open(ArchivedCard card) async {
    await openCardProfile(context, card, widget.service);
    if (mounted) setState(_reload);
  }

  Future<void> _delete(ArchivedCard card) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kartviziti arşivden sil'),
        content: Text(
          '${card.data.name.isNotEmpty ? card.data.name : card.data.company}\n\nBu işlem yalnızca uygulama arşivindeki fotoğrafı siler. Rehber kaydı etkilenmez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (approved != true) return;
    try {
      await ReminderService(widget.service).deleteCard(card);
      if (mounted) setState(_reload);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kartvizit silinemedi. Tekrar deneyin.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Kartvizit Galerisi')),
    body: TechBackground(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: FutureBuilder<List<ArchivedCard>>(
              future: _cards,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text('Kartvizit arşivi açılamadı.'),
                    ),
                  );
                }
                final allCards = snapshot.data ?? const <ArchivedCard>[];
                if (allCards.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.collections_bookmark_outlined,
                            size: 76,
                            color: Color(0xFF8A692F),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Arşiv henüz boş',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Taradığın kartvizitler otomatik olarak burada saklanır.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final query = searchKey(_searchController.text);
                final tags =
                    allCards.expand((card) => card.tags).toSet().toList()
                      ..sort();
                final activeTag = tags.contains(_selectedTag)
                    ? _selectedTag
                    : null;
                final cards = queryCards(
                  allCards,
                  query: query,
                  favoritesOnly: _favoritesOnly,
                  tag: activeTag,
                  company: _filters.company,
                  from: _filters.dates?.start,
                  to: _filters.dates?.end,
                  sort: _filters.sort,
                  reminders: _filters.reminders,
                );
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.tune),
                            label: Text(
                              _filters.active
                                  ? 'Filtreler etkin'
                                  : 'Filtrele ve sırala',
                            ),
                            onPressed: () async {
                              final companies =
                                  allCards
                                      .map((card) => card.data.company)
                                      .where((s) => s.isNotEmpty)
                                      .toSet()
                                      .toList()
                                    ..sort(compareTurkish);
                              final filters = await showDialog<ArchiveFilters>(
                                context: context,
                                builder: (_) => ArchiveFilterDialog(
                                  filters: _filters,
                                  companies: companies,
                                ),
                              );
                              if (mounted && filters != null) {
                                setState(() => _filters = filters);
                              }
                            },
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.ios_share),
                            label: const Text('Dışa aktar'),
                            onPressed: cards.isEmpty
                                ? null
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ExportPage(cards: cards),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Kişi, şirket, etiket veya not ara',
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('Favoriler'),
                            avatar: const Icon(Icons.star_rounded, size: 18),
                            selected: _favoritesOnly,
                            onSelected: (value) =>
                                setState(() => _favoritesOnly = value),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Tüm etiketler'),
                            selected: activeTag == null,
                            onSelected: (_) =>
                                setState(() => _selectedTag = null),
                          ),
                          for (final tag in tags)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ChoiceChip(
                                label: Text(tag),
                                selected: activeTag == tag,
                                onSelected: (selected) => setState(
                                  () => _selectedTag = selected ? tag : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 6, 22, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          query.isEmpty &&
                                  !_favoritesOnly &&
                                  activeTag == null &&
                                  !_filters.active
                              ? '${allCards.length} kartvizit'
                              : '${cards.length} sonuç',
                          style: const TextStyle(
                            color: Color(0xFF10382F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: cards.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(28),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 64,
                                      color: Color(0xFF68756A),
                                    ),
                                    SizedBox(height: 14),
                                    Text(
                                      'Eşleşen kartvizit bulunamadı',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                              itemCount: cards.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final card = cards[index];
                                final title = card.data.name.isNotEmpty
                                    ? card.data.name
                                    : card.data.company;
                                final subtitle =
                                    card.data.name.isNotEmpty &&
                                        card.data.company.isNotEmpty
                                    ? card.data.company
                                    : 'Kartvizit kaydı';
                                return Card(
                                  elevation: 8,
                                  clipBehavior: Clip.antiAlias,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                    side: const BorderSide(
                                      color: Color(0xFFD6C6A7),
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () => _open(card),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Container(
                                          color: const Color(0xFFEDE8DC),
                                          height: 180,
                                          child: Image.file(
                                            File(card.imagePath),
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => const Icon(
                                                  Icons.broken_image_outlined,
                                                  size: 56,
                                                ),
                                          ),
                                        ),
                                        ListTile(
                                          contentPadding:
                                              const EdgeInsets.fromLTRB(
                                                18,
                                                8,
                                                8,
                                                8,
                                              ),
                                          title: Text(
                                            title.isEmpty
                                                ? 'İsimsiz kartvizit'
                                                : title,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '$subtitle\n${_date(card.createdAt)}',
                                          ),
                                          isThreeLine: true,
                                          leading: card.isFavorite
                                              ? const Icon(
                                                  Icons.star_rounded,
                                                  color: Color(0xFF8A692F),
                                                )
                                              : null,
                                          trailing: IconButton(
                                            tooltip: 'Arşivden sil',
                                            onPressed: () => _delete(card),
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: Color(0xFFB3261E),
                                            ),
                                          ),
                                        ),
                                        if (card.tags.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              18,
                                              0,
                                              18,
                                              12,
                                            ),
                                            child: Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: [
                                                for (final tag in card.tags)
                                                  Chip(label: Text(tag)),
                                              ],
                                            ),
                                          ),
                                        if (card.reminder != null &&
                                            !card.reminder!.completed)
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              18,
                                              0,
                                              18,
                                              12,
                                            ),
                                            child: Text(
                                              '${reminderDate(card.reminder!.dueAt)} · ${card.reminder!.title}',
                                              style: TextStyle(
                                                color:
                                                    card.reminder!.dueAt
                                                        .isBefore(
                                                          DateTime.now(),
                                                        )
                                                    ? const Color(0xFF8A692F)
                                                    : const Color(0xFF174B40),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> openCardProfile(
  BuildContext context,
  ArchivedCard card,
  CardArchiveService service,
) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => CardDetailPage(
      card: card,
      service: service,
      onEdit: (context, current) => Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => EditPage(
            data: current.data,
            raw: current.fullRawText,
            imagePath: current.imagePath,
            onDataChanged: (data) => service.updateCardData(current.id, data),
          ),
        ),
      ),
    ),
  ),
);
