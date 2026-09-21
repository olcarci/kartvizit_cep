import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizit_cep/models/card_data.dart';
import 'package:kartvizit_cep/services/card_archive_service.dart';

void main() {
  test('Kartvizit görüntüsü ve bilgileri arşivlenip silinebilir', () async {
    final temporary = await Directory.systemTemp.createTemp('kartvizit_archive_test_');
    addTearDown(() async {
      if (await temporary.exists()) await temporary.delete(recursive: true);
    });
    final image = File('${temporary.path}${Platform.pathSeparator}source.jpg');
    await image.writeAsBytes([1, 2, 3, 4]);
    final service = CardArchiveService(directoryProvider: () async => temporary);

    final saved = await service.saveScan(
      sourceImagePath: image.path,
      data: CardData(name: 'Nihat Olcarciyuz', company: 'Zirve Doğalgaz'),
      rawText: 'örnek metin',
    );

    final cards = await service.loadCards();
    expect(cards, hasLength(1));
    expect(cards.single.data.company, 'Zirve Doğalgaz');
    expect(await File(saved.imagePath).exists(), isTrue);

    await service.updateCardData(
      saved.id,
      CardData(name: 'Nihat Olcarcıyüz', company: 'Zirve Doğalgaz'),
    );
    expect((await service.loadCards()).single.data.name, 'Nihat Olcarcıyüz');

    await service.deleteCard(saved);
    expect(await service.loadCards(), isEmpty);
    expect(await File(saved.imagePath).exists(), isFalse);
  });

  test('iOS güncellemesiyle container yolu değişse bile arşiv fotoğrafları bulunur', () async {
    final oldRoot = await Directory.systemTemp.createTemp('kartvizit_old_container_');
    final newRoot = await Directory.systemTemp.createTemp('kartvizit_new_container_');
    addTearDown(() async {
      for (final dir in [oldRoot, newRoot]) {
        if (await dir.exists()) await dir.delete(recursive: true);
      }
    });

    final image = File('${oldRoot.path}${Platform.pathSeparator}source.jpg');
    await image.writeAsBytes([1, 2, 3, 4]);

    var currentRoot = oldRoot;
    final service = CardArchiveService(directoryProvider: () async => currentRoot);

    final saved = await service.saveScan(
      sourceImagePath: image.path,
      data: CardData(name: 'Aycan Salık', company: 'Emir Kombi'),
    );
    expect(saved.data.name, 'Aycan Salık');

    // iOS güncellemesinde Documents klasörünün tüm içeriği (resim + JSON
    // index) yeni container'a taşınır, sadece klasörün tam yolu değişir.
    final oldArchiveDir = Directory('${oldRoot.path}${Platform.pathSeparator}kartvizit_arsivi');
    final newArchiveDir = Directory('${newRoot.path}${Platform.pathSeparator}kartvizit_arsivi');
    await newArchiveDir.create(recursive: true);
    for (final entity in oldArchiveDir.listSync()) {
      if (entity is File) {
        final fileName = entity.uri.pathSegments.last;
        await entity.copy('${newArchiveDir.path}${Platform.pathSeparator}$fileName');
      }
    }
    await oldRoot.delete(recursive: true);
    currentRoot = newRoot;

    final cards = await service.loadCards();
    expect(cards, hasLength(1));
    expect(await File(cards.single.imagePath).exists(), isTrue,
        reason: 'Eski container yoluna göre kaydedilmiş kart, güncel dizine göre yeniden çözülebilmeli.');
  });
}
