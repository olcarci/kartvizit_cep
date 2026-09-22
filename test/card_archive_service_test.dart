import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizit_cep/models/card_data.dart';
import 'package:kartvizit_cep/services/card_archive_service.dart';

void main() {
  test('Kartvizit görüntüsü ve bilgileri arşivlenip silinebilir', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'kartvizit_archive_test_',
    );
    addTearDown(() async {
      if (await temporary.exists()) await temporary.delete(recursive: true);
    });
    final image = File('${temporary.path}${Platform.pathSeparator}source.jpg');
    await image.writeAsBytes([1, 2, 3, 4]);
    final service = CardArchiveService(
      directoryProvider: () async => temporary,
    );

    final saved = await service.saveScan(
      sourceImagePath: image.path,
      data: CardData(name: 'Nihat Olcarciyuz', company: 'Zirve Doğalgaz'),
      rawText: 'örnek metin',
    );

    final cards = await service.loadCards();
    expect(cards, hasLength(1));
    expect(cards.single.data.company, 'Zirve Doğalgaz');
    expect(await File(saved.imagePath).exists(), isTrue);

    await service.updateOrganization(
      saved.id,
      notes: 'Fuarda tanıştık.',
      tags: [' Müşteri ', 'Fuar', 'Müşteri', ''],
      isFavorite: true,
    );

    await service.updateCardData(
      saved.id,
      CardData(name: 'Nihat Olcarcıyüz', company: 'Zirve Doğalgaz'),
    );
    expect((await service.loadCards()).single.data.name, 'Nihat Olcarcıyüz');
    final reopened = CardArchiveService(
      directoryProvider: () async => temporary,
    );
    final organized = (await reopened.loadCards()).single;
    expect(organized.notes, 'Fuarda tanıştık.');
    expect(organized.tags, ['Müşteri', 'Fuar']);
    expect(organized.isFavorite, isTrue);
    expect(organized.rawText, 'örnek metin');
    await reopened.updateOrganization(saved.id, isFavorite: false);
    expect((await reopened.loadCards()).single.notes, 'Fuarda tanıştık.');
    await reopened.updateOrganization(saved.id, notes: '', tags: []);
    expect((await reopened.loadCards()).single.tags, isEmpty);
    expect((await reopened.loadCards()).single.notes, isEmpty);

    await service.deleteCard(saved);
    expect(await service.loadCards(), isEmpty);
    expect(await File(saved.imagePath).exists(), isFalse);
  });

  test(
    'Eski arşiv yeni alanlar olmadan açılır ve kayıpsız güncellenir',
    () async {
      final root = await Directory.systemTemp.createTemp('legacy_card_');
      addTearDown(() => root.delete(recursive: true));
      final dir = await Directory('${root.path}/kartvizit_arsivi').create();
      await File('${dir.path}/kartvizitler.json').writeAsString(
        jsonEncode([
          {
            'id': 'legacy',
            'imagePath': 'old.jpg',
            'createdAt': '2026-09-01T10:00:00.000',
            'data': {'name': 'Eski Kişi', 'company': 'Örnek Şirket'},
            'rawText': 'eski OCR',
          },
        ]),
      );
      final service = CardArchiveService(directoryProvider: () async => root);
      final old = (await service.loadCards()).single;
      expect(old.notes, isEmpty);
      expect(old.tags, isEmpty);
      expect(old.isFavorite, isFalse);
      await service.updateOrganization(old.id, tags: ['Eski müşteri']);
      final current = (await service.loadCards()).single;
      expect(current.data.name, 'Eski Kişi');
      expect(current.rawText, 'eski OCR');
      expect(current.createdAt, old.createdAt);
      expect(current.imagePath, old.imagePath);
    },
  );

  test('iOS güncellemesiyle container yolu değişse bile arşiv fotoğrafları bulunur', () async {
    final oldRoot = await Directory.systemTemp.createTemp(
      'kartvizit_old_container_',
    );
    final newRoot = await Directory.systemTemp.createTemp(
      'kartvizit_new_container_',
    );
    addTearDown(() async {
      for (final dir in [oldRoot, newRoot]) {
        if (await dir.exists()) await dir.delete(recursive: true);
      }
    });

    final image = File('${oldRoot.path}${Platform.pathSeparator}source.jpg');
    await image.writeAsBytes([1, 2, 3, 4]);

    var currentRoot = oldRoot;
    final service = CardArchiveService(
      directoryProvider: () async => currentRoot,
    );

    final saved = await service.saveScan(
      sourceImagePath: image.path,
      data: CardData(name: 'Aycan Salık', company: 'Emir Kombi'),
    );
    expect(saved.data.name, 'Aycan Salık');

    // iOS güncellemesinde Documents klasörünün tüm içeriği (resim + JSON
    // index) yeni container'a taşınır, sadece klasörün tam yolu değişir.
    final oldArchiveDir = Directory(
      '${oldRoot.path}${Platform.pathSeparator}kartvizit_arsivi',
    );
    final newArchiveDir = Directory(
      '${newRoot.path}${Platform.pathSeparator}kartvizit_arsivi',
    );
    await newArchiveDir.create(recursive: true);
    for (final entity in oldArchiveDir.listSync()) {
      if (entity is File) {
        final fileName = entity.uri.pathSegments.last;
        await entity.copy(
          '${newArchiveDir.path}${Platform.pathSeparator}$fileName',
        );
      }
    }
    await oldRoot.delete(recursive: true);
    currentRoot = newRoot;

    final cards = await service.loadCards();
    expect(cards, hasLength(1));
    expect(
      await File(cards.single.imagePath).exists(),
      isTrue,
      reason: 'Eski container yoluna göre kaydedilmiş kart, güncel dizine göre yeniden çözülebilmeli.',
    );
  });
}
