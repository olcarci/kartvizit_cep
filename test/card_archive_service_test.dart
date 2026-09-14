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
}
