import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizit_cep/main.dart';
import 'package:kartvizit_cep/models/archived_card.dart';
import 'package:kartvizit_cep/models/card_data.dart';
import 'package:kartvizit_cep/models/card_reminder.dart';
import 'package:kartvizit_cep/screens/reminders_page.dart';
import 'package:kartvizit_cep/services/card_archive_service.dart';

class MemoryArchive extends CardArchiveService {
  List<ArchivedCard> cards = [];
  @override
  Future<List<ArchivedCard>> loadCards() async => cards;
}

void main() {
  testWidgets(
    'Boş arşivde hatırlatmalar ve yardım görünür, kişi seçimi arşivi açar',
    (tester) async {
      await tester.pumpWidget(KartvizitApp(archiveService: MemoryArchive()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hatırlatmalar').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Henüz bekleyen'), findsOneWidget);
      await tester.tap(find.text('Hatırlatma için kişi seç'));
      await tester.pumpAndSettle();
      expect(find.text('Arşiv henüz boş'), findsOneWidget);
      await tester.tap(find.text('Ayarlar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hatırlatma nasıl eklenir?'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Başlığı, tarihi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Takipler tarihle sıralanır, tamamlananlar ayrılır ve profilden dönüş yeniler',
    (tester) async {
      final archive = MemoryArchive();
      ArchivedCard card(String name, int day, {bool done = false}) =>
          ArchivedCard(
            id: name,
            imagePath: '',
            createdAt: DateTime(2026),
            data: CardData(name: name),
            reminder: CardReminder(
              title: 'Ara',
              dueAt: DateTime(2026, 1, day),
              completed: done,
            ),
          );
      archive.cards = [
        card('Sonra', 5),
        card('Önce', 1),
        card('Bitti', 2, done: true),
      ];
      String? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: RemindersPage(
            service: archive,
            onArchive: () {},
            onOpen: (c) async {
              opened = c.id;
              archive.cards = [card('Bitti', 2, done: true)];
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Önce')).dy,
        lessThan(tester.getTopLeft(find.text('Sonra')).dy),
      );
      expect(find.text('Bitti'), findsNothing);
      await tester.tap(find.text('Önce'));
      await tester.pumpAndSettle();
      expect(opened, 'Önce');
      expect(find.textContaining('Henüz bekleyen'), findsOneWidget);
      await tester.tap(find.text('Tamamlananlar'));
      await tester.pumpAndSettle();
      expect(find.text('Bitti'), findsOneWidget);
    },
  );

  testWidgets('Dar ekranda büyük yazı ile gezinme taşmaz', (tester) async {
    tester.view.physicalSize = const Size(320, 750);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(KartvizitApp(archiveService: MemoryArchive()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hatırlatmalar').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
