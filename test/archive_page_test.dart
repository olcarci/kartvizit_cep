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

  @override
  Future<ArchivedCard> updateOrganization(
    String id, {
    String? notes,
    List<String>? tags,
    bool? isFavorite,
  }) async {
    final index = cards.indexWhere((card) => card.id == id);
    return cards[index] = cards[index].copyWith(
      notes: notes,
      tags: tags,
      isFavorite: isFavorite,
    );
  }
}

void main() {
  testWidgets('Profilde favori, etiket ve not kaydedilir; galeride aranır', (
    tester,
  ) async {
    final service = _FakeArchiveService([
      ArchivedCard(
        id: 'profile',
        imagePath: 'missing.jpg',
        createdAt: DateTime(2026),
        data: CardData(name: 'Ayşe Yılmaz', company: 'Örnek'),
      ),
    ]);
    await tester.pumpWidget(MaterialApp(home: ArchivePage(service: service)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ayşe Yılmaz'));
    await tester.pumpAndSettle();
    expect(find.text('Kişi profili'), findsOneWidget);
    await tester.tap(find.byTooltip('Favorilere ekle'));
    await tester.pumpAndSettle();
    expect(service.cards.single.isFavorite, isTrue);
    final organize = find.text('Etiket ve not ekle / düzenle');
    await tester.scrollUntilVisible(
      organize,
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(organize);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Etiketler'), 'Fuar');
    await tester.enterText(
      find.widgetWithText(TextField, 'Notlar'),
      'İzmir toplantısı',
    );
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(service.cards.single.notes, 'İzmir toplantısı');
    expect(service.cards.single.tags, ['Fuar']);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'izmir');
    await tester.pumpAndSettle();
    expect(find.text('Ayşe Yılmaz'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Favori ve etiket filtreleri birlikte çalışır', (tester) async {
    final service = _FakeArchiveService([
      ArchivedCard(
        id: '1',
        imagePath: 'missing.jpg',
        createdAt: DateTime(2026),
        data: CardData(name: 'Favori Müşteri'),
        tags: ['Müşteri'],
        isFavorite: true,
      ),
      ArchivedCard(
        id: '2',
        imagePath: 'missing.jpg',
        createdAt: DateTime(2026),
        data: CardData(name: 'Diğer Kişi'),
        tags: ['Tedarikçi'],
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(home: ArchivePage(service: service, favoritesOnly: true)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Favori Müşteri'), findsOneWidget);
    expect(find.text('Diğer Kişi'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Tedarikçi'));
    await tester.pumpAndSettle();
    expect(find.text('Eşleşen kartvizit bulunamadı'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Favoriler'));
    await tester.pumpAndSettle();
    expect(find.text('Diğer Kişi'), findsOneWidget);
    expect(find.text('Favori Müşteri'), findsNothing);
  });

  testWidgets('Galeride ad ve şirket Türkçe karakterlerden bağımsız aranır', (
    tester,
  ) async {
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
