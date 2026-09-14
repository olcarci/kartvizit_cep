import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizit_cep/main.dart';
import 'package:kartvizit_cep/models/archived_card.dart';
import 'package:kartvizit_cep/models/card_data.dart';
import 'package:kartvizit_cep/services/card_archive_service.dart';

class _FakeArchiveService extends CardArchiveService {
  final List<ArchivedCard> cards;

  _FakeArchiveService(this.cards);

  @override
  Future<List<ArchivedCard>> loadCards() => Future.value(cards);
}

void main() {
  testWidgets('Galeride ad ve şirket Türkçe karakterlerden bağımsız aranır', (tester) async {
    final service = _FakeArchiveService([
      ArchivedCard(
        id: 'test-card',
        imagePath: 'test-image-not-needed.jpg',
        createdAt: DateTime(2026, 9, 14, 13),
        data: CardData(name: 'Emrullah Veske', company: 'Zirve Doğalgaz'),
      ),
    ]);

    await tester.pumpWidget(MaterialApp(home: ArchivePage(service: service)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('Emrullah Veske'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'dogalgaz');
    await tester.pump();
    expect(find.text('Emrullah Veske'), findsOneWidget);
    expect(find.text('1 sonuç'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'bulunmayan');
    await tester.pump();
    expect(find.text('Eşleşen kartvizit bulunamadı'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
