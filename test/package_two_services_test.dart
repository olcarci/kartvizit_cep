import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizit_cep/models/archived_card.dart';
import 'package:kartvizit_cep/models/card_data.dart';
import 'package:kartvizit_cep/models/card_reminder.dart';
import 'package:kartvizit_cep/services/archive_query.dart';
import 'package:kartvizit_cep/services/backup_codec.dart';
import 'package:kartvizit_cep/services/card_archive_service.dart';
import 'package:kartvizit_cep/services/card_export_service.dart';
import 'package:kartvizit_cep/services/reminder_service.dart';

class FailingArchive extends CardArchiveService {
  bool failUpdates = false;
  FailingArchive(Directory root) : super(directoryProvider: () async => root);
  @override
  Future<ArchivedCard> updateReminder(String id, CardReminder? reminder) {
    if (failUpdates) throw FileSystemException('Disk full');
    return super.updateReminder(id, reminder);
  }
}

class FakeNotifications implements ReminderNotifications {
  bool permitted = true;
  bool failSchedule = false;
  final scheduled = <int, String>{};
  final cancelled = <int>[];
  @override
  Future<bool> requestPermission() async => permitted;
  @override
  Future<Set<int>> pendingIds() async => scheduled.keys.toSet();
  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    scheduled.remove(id);
  }

  @override
  Future<void> schedule(
    int id,
    String cardId,
    String person,
    CardReminder reminder,
  ) async {
    if (failSchedule) throw StateError('Scheduling failed');
    scheduled[id] = cardId;
  }
}

void main() {
  late Directory root;
  late CardArchiveService archive;
  late ArchivedCard card;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('kartvizit_package_two_');
    archive = CardArchiveService(directoryProvider: () async => root);
    final image = await File('${root.path}/source.png')
        .writeAsBytes([137, 80, 78, 71, 1, 2]);
    card = await archive.saveScan(
      sourceImagePath: image.path,
      data: CardData(
        name: 'İpek Şahin',
        company: 'Çağrı, A.Ş.',
        phones: ['+905321234567'],
        email: 'ipek@example.com',
      ),
      rawText: 'Örnek OCR',
    );
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });

  test(
    'Yedek fotoğraflarla başka cihaza taşınır; tekrarı mevcut notları ezmez',
    () async {
      await archive.updateOrganization(
        card.id,
        notes: 'Özel görüşme',
        tags: ['Müşteri'],
        isFavorite: true,
      );
      await archive.updateReminder(
        card.id,
        CardReminder(
          title: 'Teklif gönder',
          dueAt: DateTime(2030),
          notificationId: 47,
        ),
      );
      final bundle = BackupBundle.decode(
        (await archive.createBackup()).encode(),
      );
      final destination = await Directory('${root.path}/new_device').create();
      final second = CardArchiveService(
        directoryProvider: () async => destination,
      );
      final result = await second.restoreBackup(bundle);
      expect(result.added, 1);
      final restored = (await second.loadCards()).single;
      expect(
        await File(restored.imagePath).readAsBytes(),
        await File(card.imagePath).readAsBytes(),
      );
      expect(restored.notes, 'Özel görüşme');
      expect(restored.tags, ['Müşteri']);
      expect(restored.isFavorite, isTrue);
      expect(restored.rawText, 'Örnek OCR');
      expect(restored.reminder?.notificationId, isNull);
      expect(restored.reminder?.title, 'Teklif gönder');
      await second.updateOrganization(restored.id, notes: 'Yeni not');
      final duplicate = await second.restoreBackup(bundle);
      expect(duplicate.added, 0);
      expect(duplicate.skipped, 1);
      expect((await second.loadCards()).single.notes, 'Yeni not');
    },
  );

  test('Yedekteki dosya yolları ve kart kimlikleri hedef klasörden çıkamaz', () async {
    final malicious = ArchivedCard(
      id: '../../outside',
      imagePath: '../../outside.jpg',
      createdAt: DateTime(2026),
      data: CardData(name: 'Örnek'),
    );
    final validated = BackupBundle.decode(
      BackupBundle([
        BackupEntry(malicious, Uint8List.fromList([1])),
      ]).encode(),
    );
    await archive.restoreBackup(validated);
    final restored = (await archive.loadCards()).firstWhere(
      (c) => c.id == malicious.id,
    );
    expect(
      restored.imagePath,
      startsWith(
        '${root.path}${Platform.pathSeparator}kartvizit_arsivi${Platform.pathSeparator}restored_',
      ),
    );
  });

  test('Bozuk/sürümsüz ve aynı kimlikli yedekler reddedilir', () {
    expect(
      () => BackupBundle.decode(Uint8List.fromList(utf8.encode('{broken'))),
      throwsFormatException,
    );
    expect(
      () =>
          BackupBundle.decode(Uint8List.fromList(utf8.encode('{"cards":[]}'))),
      throwsFormatException,
    );
    final duplicate = BackupBundle([
      BackupEntry(card, null),
      BackupEntry(card, null),
    ]).encode();
    expect(() => BackupBundle.decode(duplicate), throwsFormatException);
    final wrongVersion = jsonDecode(
      utf8.decode(BackupBundle([BackupEntry(card, null)]).encode()),
    ) as Map;
    wrongVersion['version'] = 99;
    expect(
      () => BackupBundle.decode(
        Uint8List.fromList(utf8.encode(jsonEncode(wrongVersion))),
      ),
      throwsFormatException,
    );
  });

  test('Eksik fotoğraf metin yedeğini engellemez', () async {
    await File(card.imagePath).delete();
    final backup = await archive.createBackup();
    expect(backup.missingImages, 1);
    expect(
      BackupBundle.decode(backup.encode()).entries.single.card.data.name,
      'İpek Şahin',
    );
  });

  test('Bozuk mevcut arşiv üzerine yeni kayıt yazılmaz', () async {
    final index = File('${root.path}/kartvizit_arsivi/kartvizitler.json');
    await index.writeAsString('broken archive');
    await expectLater(
      archive.updateOrganization(card.id, notes: 'Yeni'),
      throwsFormatException,
    );
    expect(await index.readAsString(), 'broken archive');
  });

  test(
    'Eşzamanlı güncellemeler not, favori ve hatırlatmayı kaybetmez',
    () async {
      await Future.wait([
        archive.updateOrganization(card.id, notes: 'Not'),
        archive.updateOrganization(card.id, isFavorite: true),
        archive.updateReminder(
          card.id,
          CardReminder(title: 'Ara', dueAt: DateTime(2030)),
        ),
      ]);
      final saved = (await archive.loadCards()).single;
      expect(saved.notes, 'Not');
      expect(saved.isFavorite, isTrue);
      expect(saved.reminder?.title, 'Ara');
    },
  );

  test('CSV Türkçe, virgül, tırnak, satır sonu ve formül metnini korur', () {
    final item = card.copyWith(
      notes: 'Özel\n"not"',
      data: CardData(
        name: '=HYPERLINK("bad")',
        company: 'Çağrı, A.Ş.',
        phones: ['+905321234567'],
      ),
    );
    final csv = CardExportService.csv([item]);
    expect(csv.startsWith('\uFEFF'), isTrue);
    expect(csv, contains('"Çağrı, A.Ş."'));
    expect(csv, contains('"\'=HYPERLINK(""bad"")"'));
    expect(csv, contains('"\'+905321234567"'));
    expect(csv, isNot(contains('Özel')));
    expect(
      CardExportService.csv([item], includeNotes: true),
      contains('"Özel\n""not"""'),
    );
  });

  test('VCF çoklu kartı ve uzun Türkçe alanları kayıpsız katlar; notları paylaşmaz', () {
    final item = card.copyWith(
      notes: 'Gizli not',
      data: CardData(name: 'Şahin' * 40, company: 'A;B'),
    );
    final vcf = utf8.decode(
      CardExportService.export([item, card], CardExportFormat.vcf),
    );
    expect('BEGIN:VCARD'.allMatches(vcf).length, 2);
    expect(vcf.replaceAll('\r\n ', ''), contains(item.data.toVCard()));
    expect(vcf, isNot(contains('Gizli not')));
    for (final line in vcf.split('\r\n')) {
      expect(utf8.encode(line).length, lessThanOrEqualTo(75));
    }
  });

  test('Tarih aralığı gün sonunu kapsar; şirket, etiket ve hatırlatma birlikte süzülür', () {
    final overdue = ArchivedCard(
      id: 'other',
      imagePath: 'x',
      createdAt: DateTime(2026, 9, 22, 23, 59),
      data: CardData(name: 'Çetin', company: 'Şirket'),
      tags: ['Fuar'],
      isFavorite: true,
      reminder: CardReminder(title: 'Ara', dueAt: DateTime(2026, 9, 21)),
    );
    final results = queryCards(
      [card, overdue],
      from: DateTime(2026, 9, 22),
      to: DateTime(2026, 9, 22),
      company: 'Şirket',
      tag: 'Fuar',
      favoritesOnly: true,
      reminders: ReminderFilter.overdue,
      now: DateTime(2026, 9, 23),
    );
    expect(results.map((c) => c.id), ['other']);
    expect(queryCards([overdue], query: 'cetin'), [overdue]);
    expect(compareTurkish('Cem', 'Çetin'), lessThan(0));
    expect(compareTurkish('Işık', 'İpek'), lessThan(0));
  });

  test('Bildirim izni reddedilirse takip saklanır ve uyarı döner', () async {
    final gateway = FakeNotifications()..permitted = false;
    final service = ReminderService(
      archive,
      notifications: gateway,
      now: () => DateTime(2026),
    );
    final result = await service.save(card.id, 'Teklif gönder', DateTime(2030));
    expect(result.warning, contains('bildirim izni kapalı'));
    expect((await archive.loadCards()).single.reminder?.notificationId, isNull);
    expect((await archive.loadCards()).single.reminder?.title, 'Teklif gönder');
    expect(gateway.scheduled, isEmpty);
  });

  test('Hatırlatma değişince eskisi iptal edilir; tamamlanınca bekleyen bildirim kalmaz', () async {
    final gateway = FakeNotifications();
    final service = ReminderService(
      archive,
      notifications: gateway,
      now: () => DateTime(2026),
    );
    final first = await service.save(card.id, 'Ara', DateTime(2030));
    final oldId = first.card.reminder!.notificationId!;
    final second = await service.save(card.id, 'Teklif gönder', DateTime(2031));
    expect(gateway.cancelled, contains(oldId));
    expect(gateway.scheduled.length, 1);
    expect(second.warning, isNull);
    final done = await service.finish(card.id);
    expect(done.reminder?.completed, isTrue);
    expect(gateway.scheduled, isEmpty);
    await service.finish(card.id, remove: true);
    expect((await archive.loadCards()).single.reminder, isNull);
  });

  test(
    'Kart silinince hatırlatma iptal edilir; geçmiş tarih reddedilir',
    () async {
      final gateway = FakeNotifications();
      final service = ReminderService(
        archive,
        notifications: gateway,
        now: () => DateTime(2026),
      );
      await expectLater(
        service.save(card.id, 'Ara', DateTime(2025)),
        throwsArgumentError,
      );
      await service.save(card.id, 'Ara', DateTime(2030));
      await service.deleteCard(card);
      expect(gateway.scheduled, isEmpty);
      expect(await archive.loadCards(), isEmpty);
    },
  );

  test(
    'Planlama başarısızlığı ve 60 bildirim sınırı yanlış başarı göstermez',
    () async {
      final gateway = FakeNotifications()..failSchedule = true;
      final service = ReminderService(
        archive,
        notifications: gateway,
        now: () => DateTime(2026),
      );
      expect(
        (await service.save(card.id, 'Ara', DateTime(2030))).warning,
        contains('kurulamadı'),
      );
      gateway.failSchedule = false;
      gateway.scheduled.addAll({for (var i = 1; i <= 60; i++) i: 'other'});
      expect(
        (await service.save(card.id, 'Ara', DateTime(2030))).warning,
        contains('60'),
      );
      expect(
        (await archive.loadCards()).single.reminder?.notificationId,
        isNull,
      );
    },
  );

  test('Disk hatasında eski hatırlatma yeniden kurulur', () async {
    final failing = FailingArchive(root);
    final gateway = FakeNotifications();
    final service = ReminderService(
      failing,
      notifications: gateway,
      now: () => DateTime(2026),
    );
    final original = await service.save(
      card.id,
      'Eski hatırlatma',
      DateTime(2030),
    );
    failing.failUpdates = true;
    await expectLater(
      service.save(card.id, 'Yeni hatırlatma', DateTime(2031)),
      throwsA(isA<FileSystemException>()),
    );
    expect(
      gateway.scheduled.keys,
      contains(original.card.reminder!.notificationId),
    );
    expect(
      (await failing.loadCards()).single.reminder!.title,
      'Eski hatırlatma',
    );
  });

  test('Yarım kalan bildirim işlemleri açılışta düzeltilir; ithal hatırlatma kurulmaz', () async {
    final gateway = FakeNotifications();
    final service = ReminderService(
      archive,
      notifications: gateway,
      now: () => DateTime(2026),
    );
    final original = await service.save(card.id, 'Ara', DateTime(2030));
    gateway.scheduled.clear();
    gateway.scheduled[999] = 'deleted-card';
    await service.reconcile();
    expect(gateway.scheduled, {
      original.card.reminder!.notificationId!: card.id,
    });
    await archive.updateReminder(
      card.id,
      original.card.reminder!.withoutNotification(),
    );
    await service.reconcile();
    expect(gateway.scheduled, isEmpty);
  });
}
