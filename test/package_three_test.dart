import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kartvizit_cep/models/card_data.dart';
import 'package:kartvizit_cep/models/card_reminder.dart';
import 'package:kartvizit_cep/models/personal_card.dart';
import 'package:kartvizit_cep/services/backup_codec.dart';
import 'package:kartvizit_cep/services/card_archive_service.dart';
import 'package:kartvizit_cep/services/card_scan_service.dart';
import 'package:kartvizit_cep/services/personal_card_service.dart';
import 'package:kartvizit_cep/services/scan_queue.dart';

class StubReader implements CardTextReader {
  final Future<String> Function(String) onRead;
  StubReader(this.onRead);
  @override
  Future<String> read(String path) => onRead(path);
  @override
  Future<void> close() async {}
}

void main() {
  late Directory root;
  late CardArchiveService archive;
  late File front;
  late File back;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('kartvizit_package_three_');
    archive = CardArchiveService(directoryProvider: () async => root);
    front = await File('${root.path}/front.png').writeAsBytes([1, 2, 3]);
    back = await File('${root.path}/back.png').writeAsBytes([4, 5, 6]);
  });
  tearDown(() async { await root.delete(recursive: true); });

  test('Arka yüz dolu bilgileri korur, boş alanları ve yeni telefonları tamamlar', () async {
    final saved = await archive.saveScan(sourceImagePath: front.path,
      data: CardData(name: 'Doğru Ad', company: 'Doğru Şirket', phones: ['05321234567']), rawText: 'Ön metin');
    await archive.updateOrganization(saved.id, notes: 'Görüşme notu', tags: ['Müşteri'], isFavorite: true);
    await archive.updateReminder(saved.id, CardReminder(title: 'Ara', dueAt: DateTime(2030)));
    final twoSided = await archive.attachBack(saved.id, ScanDraft(back.path, 'Arka metin', CardData(
      name: 'Yanlış OCR', company: 'Başka Şirket', email: 'info@example.com',
      phones: ['+905321234567', '02121234567'], address: 'İstanbul')));
    expect(twoSided.data.name, 'Doğru Ad');
    expect(twoSided.data.company, 'Doğru Şirket');
    expect(twoSided.data.phones, ['05321234567', '02121234567']);
    expect(twoSided.data.email, 'info@example.com');
    expect(twoSided.notes, 'Görüşme notu');
    expect(twoSided.reminder!.title, 'Ara');
    expect(twoSided.tags, ['Müşteri']);
    expect(twoSided.isFavorite, isTrue);
    expect(await File(twoSided.backImagePath!).readAsBytes(), [4, 5, 6]);
    expect(twoSided.fullRawText, contains('Ön metin'));
    expect(twoSided.fullRawText, contains('Arka metin'));
    final replaced = await archive.attachBack(saved.id, ScanDraft(back.path, 'Yeni arka', CardData()),
      reviewedData: CardData(name: 'Kullanıcı düzeltmesi'));
    expect(replaced.data.name, 'Kullanıcı düzeltmesi');
    expect(await File(twoSided.backImagePath!).exists(), isFalse);
    final removed = await archive.removeBack(saved.id);
    expect(removed.backImagePath, isNull);
    expect(removed.backRawText, isEmpty);
    expect(removed.data.name, 'Kullanıcı düzeltmesi');
    expect(await File(replaced.backImagePath!).exists(), isFalse);
    expect(await File(saved.imagePath).exists(), isTrue);
  });

  test('Çift yüzlü yedek fotoğrafları taşır; kart silinince iki fotoğraf da silinir', () async {
    final saved = await archive.saveScan(sourceImagePath: front.path, data: CardData(name: 'Ayşe'));
    await archive.attachBack(saved.id, ScanDraft(back.path, 'Arka', CardData()));
    final bundle = BackupBundle.decode((await archive.createBackup()).encode());
    final newRoot = await Directory('${root.path}/other').create();
    final other = CardArchiveService(directoryProvider: () async => newRoot);
    await other.restoreBackup(bundle);
    final restored = (await other.loadCards()).single;
    expect(await File(restored.imagePath).readAsBytes(), [1, 2, 3]);
    expect(await File(restored.backImagePath!).readAsBytes(), [4, 5, 6]);
    expect(restored.backRawText, 'Arka');
    await other.deleteCard(restored);
    expect(await File(restored.imagePath).exists(), isFalse);
    expect(await File(restored.backImagePath!).exists(), isFalse);
  });

  test('Sürüm 1 yedek ve tek yüzlü kayıtlar açılmaya devam eder', () async {
    final saved = await archive.saveScan(sourceImagePath: front.path, data: CardData(name: 'Eski kart'));
    final json = saved.toJson()..remove('backImagePath')..remove('backRawText');
    final oldBackup = Uint8List.fromList(utf8.encode(jsonEncode({
      'format': 'kartvizit_cep_backup', 'version': 1,
      'cards': [{'card': json, 'image': base64Encode([1, 2, 3])}],
    })));
    final bundle = BackupBundle.decode(oldBackup);
    expect(bundle.entries.single.card.backImagePath, isNull);
    expect(bundle.entries.single.card.backRawText, isEmpty);
    expect(bundle.personalCard, isNull);
  });

  test('Toplu OCR hatalı fotoğrafı atlayarak devam eder; açık kaydetme olmadan arşiv değişmez', () async {
    final reader = StubReader((path) async {
      if (path == 'bad') throw StateError('OCR failure');
      return 'AYŞE ŞAHİN\nZİRVE DOĞALGAZ\n0532 123 45 67';
    });
    final queue = ScanQueue(paths: [front.path, 'bad', back.path], archive: archive, scanner: CardScanService(reader));
    addTearDown(queue.dispose);
    await queue.readAll();
    expect(queue.items.first.draft, isNotNull);
    expect(queue.items[1].error, isNotNull);
    expect(queue.items[2].draft, isNotNull);
    expect(await archive.loadCards(), isEmpty);
    final saved = await queue.save(0, reviewedData: CardData(name: 'Düzeltilen Ad'));
    await queue.save(0, reviewedData: CardData(name: 'Son Ad'));
    expect((await archive.loadCards()).single.id, saved.id);
    expect((await archive.loadCards()).single.data.name, 'Son Ad');
    expect(queue.savedCount, 1);
    queue.skip(1);
    await expectLater(queue.save(1), throwsStateError);
    await queue.save(2, reviewedData: CardData(name: 'İkinci'));
    expect(queue.hasUnsaved, isFalse);
  });

  test('Toplu okuma durdurulup kaldığı yerden devam eder', () async {
    final first = Completer<String>();
    var calls = 0;
    final reader = StubReader((_) { calls++; return calls == 1 ? first.future : Future.value('ALI DEMİR\n05321234567'); });
    final queue = ScanQueue(paths: [front.path, back.path], archive: archive, scanner: CardScanService(reader));
    addTearDown(queue.dispose);
    final reading = queue.readAll();
    queue.stop(); first.complete('AYŞE ŞAHİN\n05321234567'); await reading;
    expect(calls, 1); expect(queue.items[1].draft, isNull); expect(queue.busy, isFalse);
    await queue.readAll(); expect(calls, 2); expect(queue.items[1].draft, isNotNull);
  });

  test('Metinsiz arka yüz saklanabilir; metinsiz ön yüz tekrar denemeye yönlendirir', () async {
    final scanner = CardScanService(StubReader((_) async => ''));
    await expectLater(scanner.scan(front.path), throwsFormatException);
    final saved = await archive.saveScan(sourceImagePath: front.path, data: CardData(name: 'Ali'));
    final queue = ScanQueue(paths: [back.path], archive: archive, scanner: scanner, backFor: saved);
    addTearDown(queue.dispose);
    await queue.readAll();
    final card = await queue.save(0);
    expect(card.backImagePath, isNotNull); expect(card.data.name, 'Ali');
  });

  test('Kişisel kart ve logo kalıcı saklanır, yedekten korunarak yüklenir', () async {
    final personal = PersonalCardService(directoryProvider: () async => root);
    final profile = PersonalCard(data: CardData(name: 'İpek Şahin', company: 'Çağrı A.Ş.'), theme: 2);
    final saved = await personal.save(profile, sourceAvatar: front.path);
    expect((await personal.load())!.data.name, 'İpek Şahin');
    expect((await personal.load())!.theme, 2);
    expect(await File(saved.avatarPath!).exists(), isTrue);
    final bundle = BackupBundle.decode((await archive.createBackup()).encode());
    expect(bundle.entries, isEmpty); expect(bundle.personalCard!.data.name, 'İpek Şahin');
    final destination = await Directory('${root.path}/new_phone').create();
    final other = CardArchiveService(directoryProvider: () async => destination);
    await other.restoreBackup(bundle);
    final otherPersonal = PersonalCardService(directoryProvider: () async => destination);
    final restored = (await otherPersonal.load())!;
    expect(await File(restored.avatarPath!).readAsBytes(), [1, 2, 3]);
    await otherPersonal.save(PersonalCard(data: CardData(name: 'Yeni Ad')));
    final repeated = await other.restoreBackup(bundle);
    expect(repeated.personalStatus, contains('korundu'));
    expect((await otherPersonal.load())!.data.name, 'Yeni Ad');
    await personal.save(profile, removeAvatar: true);
    expect((await personal.load())!.avatarPath, isNull);
    expect(await File(saved.avatarPath!).exists(), isFalse);
  });

  test('QR vCard Türkçe iletişim bilgilerini taşır; aşırı uzun/geçersiz bilgiler reddedilir', () {
    final profile = PersonalCard(data: CardData(name: 'İpek Şahin', company: 'Çağrı A.Ş.', phones: ['+905321234567'],
      email: 'ipek@example.com', address: 'İstanbul; Şişli'));
    profile.validate();
    final parsed = FlutterContacts.vCard.import(profile.qrData).single;
    expect(parsed.name!.first, 'İpek'); expect(parsed.name!.last, 'Şahin');
    final result = QrValidator.validate(data: profile.qrData, version: QrVersions.auto, errorCorrectionLevel: QrErrorCorrectLevel.M);
    expect(result.status, QrValidationStatus.valid);
    expect(() => PersonalCard(data: CardData(name: '')).validate(), throwsFormatException);
    expect(() => PersonalCard(data: CardData(name: 'Ali', email: 'bad')).validate(), throwsFormatException);
    expect(() => PersonalCard(data: CardData(name: 'Ş' * 2000)).validate(), throwsFormatException);
  });
}
