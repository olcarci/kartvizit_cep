import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kartvizit_cep/models/archived_card.dart';
import 'package:kartvizit_cep/models/card_data.dart';
import 'package:kartvizit_cep/models/personal_card.dart';
import 'package:kartvizit_cep/screens/personal_card_page.dart';
import 'package:kartvizit_cep/screens/batch_scan_page.dart';
import 'package:kartvizit_cep/services/card_archive_service.dart';
import 'package:kartvizit_cep/services/card_scan_service.dart';
import 'package:kartvizit_cep/services/personal_card_service.dart';

class MemoryPersonal extends PersonalCardService {
  PersonalCard? card;
  @override
  Future<PersonalCard?> load() async => card;
  @override
  Future<PersonalCard> save(PersonalCard profile, {String? sourceAvatar, bool removeAvatar = false}) async {
    profile.validate(); return card = profile;
  }
}
class MemoryArchive extends CardArchiveService {
  final cards = <ArchivedCard>[];
  @override
  Future<ArchivedCard> saveScan({required String sourceImagePath, required CardData data, String rawText = ''}) async {
    final card = ArchivedCard(id: '${cards.length}', imagePath: sourceImagePath, createdAt: DateTime(2026), data: data, rawText: rawText);
    cards.add(card); return card;
  }
}
class TextReader extends CardTextReader {
  @override
  Future<String> read(String path) async => 'ALİ DEMİR\nZİRVE DOĞALGAZ\n0532 123 45 67';
  @override
  Future<void> close() async {}
}

void main() {
  testWidgets('Kişisel kart formdan kaydedilir ve QR önizlemesine dönülür', (tester) async {
    final service = MemoryPersonal();
    await tester.pumpWidget(MaterialApp(home: PersonalCardPage(service: service)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kartvizitimi oluştur')); await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Ad soyad'), 'İpek Şahin');
    final button = find.text('Kartvizitimi kaydet');
    await tester.scrollUntilVisible(button, 200, scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first);
    await tester.tap(button); await tester.pumpAndSettle();
    expect(service.card?.data.name, 'İpek Şahin');
    expect(find.text('İpek Şahin'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dar ekranda büyük yazı ve büyütülmüş QR taşmaz', (tester) async {
    tester.view.physicalSize = const Size(320, 750);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = MemoryPersonal()..card = PersonalCard(data: CardData(
      name: 'İpek Şahin', company: 'Çağrı Teknoloji ve Danışmanlık', title: 'Satış Yöneticisi',
      phones: ['+90 532 123 45 67'], email: 'ipek@example.com'));
    await tester.pumpWidget(MaterialApp(builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.5)), child: child!),
      home: PersonalCardPage(service: service)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('QR kodu büyüt'), 250,
      scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('QR kodu büyüt')); await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Kapat')); await tester.pumpAndSettle();
  });

  testWidgets('Toplu tarama açık kaydetme ister ve kaydedilen öğeyi işaretler', (tester) async {
    final archive = MemoryArchive();
    await tester.pumpWidget(MaterialApp(home: BatchScanPage(paths: ['missing.jpg'], archive: archive, reader: TextReader())));
    await tester.pumpAndSettle();
    expect(archive.cards, isEmpty);
    await tester.ensureVisible(find.text('Arşive kaydet'));
    await tester.tap(find.text('Arşive kaydet')); await tester.pumpAndSettle();
    expect(archive.cards, hasLength(1));
    expect(find.text('1. fotoğraf · Kaydedildi'), findsOneWidget);
    expect(find.text('Arşive kaydet'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
