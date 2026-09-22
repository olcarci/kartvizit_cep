import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizit_cep/main.dart';
import 'package:kartvizit_cep/models/card_data.dart';
import 'package:kartvizit_cep/models/archived_card.dart';
import 'package:kartvizit_cep/services/card_archive_service.dart';

class _EmptyArchive extends CardArchiveService {
  @override
  Future<List<ArchivedCard>> loadCards() async => [];
}

void main() {
  testWidgets('Elle giriş kişi kartını açar', (tester) async {
    await tester.pumpWidget(KartvizitApp(archiveService: _EmptyArchive()));

    // ListView's outer Scrollable is visited before nested text-field scrollers.
    Finder pageScroll() => find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;

    final manualEntry = find.text('Bilgileri elle gir');
    await tester.scrollUntilVisible(manualEntry, 200, scrollable: pageScroll());
    await tester.pumpAndSettle();
    await tester.tap(manualEntry);
    await tester.pumpAndSettle();
    expect(find.text('Kişi bilgilerini kontrol et'), findsOneWidget);
    final name = find.widgetWithText(TextFormField, 'Ad soyad');
    await tester.scrollUntilVisible(name, 150, scrollable: pageScroll());
    expect(find.text('Ad soyad'), findsOneWidget);

    // Verify each field after scrolling it into view, even in a short viewport.
    final mobile = find.text('Cep telefonu');
    await tester.scrollUntilVisible(mobile, 150, scrollable: pageScroll());
    expect(mobile, findsOneWidget);
    final work = find.text('Sabit / iş telefonu');
    await tester.scrollUntilVisible(work, 150, scrollable: pageScroll());
    expect(work, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ana ekran telefon fotoğrafları ile uygulama arşivini ayırır', (
    tester,
  ) async {
    await tester.pumpWidget(KartvizitApp(archiveService: _EmptyArchive()));
    Finder pageScroll() => find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    final gallery = find.text('Kartvizit Galerisi');
    await tester.scrollUntilVisible(gallery, 200, scrollable: pageScroll());
    expect(find.text('Fotoğraflardan seç'), findsOneWidget);
    expect(gallery, findsOneWidget);
    expect(find.text('Galeriden seç'), findsNothing);
    await tester.scrollUntilVisible(find.text('BAĞLANTILARINIZ BİR ARADA'), -200, scrollable: pageScroll());
    expect(find.text('BAĞLANTILARINIZ BİR ARADA'), findsOneWidget);
    expect(find.text('OCR'), findsOneWidget);
  });

  testWidgets('Galeri bilgileri rehbere eklemeden güncellenebilir', (
    tester,
  ) async {
    CardData? updated;
    await tester.pumpWidget(
      MaterialApp(
        home: EditPage(
          data: CardData(name: 'Ali Şahin'),
          onDataChanged: (data) async {
            updated = data;
          },
        ),
      ),
    );

    Finder pageScroll() => find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    final company = find.widgetWithText(TextFormField, 'Şirket');
    await tester.scrollUntilVisible(company, 150, scrollable: pageScroll());
    await tester.pumpAndSettle();
    await tester.enterText(company, 'Eren Group');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final updateButton = find.text('Galeri bilgilerini güncelle');
    await tester.scrollUntilVisible(
      updateButton,
      250,
      scrollable: pageScroll(),
    );
    await tester.tap(updateButton);
    await tester.pump();

    expect(updated?.name, 'Ali Şahin');
    expect(updated?.company, 'Eren Group');
    expect(find.text('Galeri bilgileri güncellendi.'), findsOneWidget);
  });
}
