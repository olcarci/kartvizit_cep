import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizit_cep/main.dart';

void main() {
  testWidgets('Elle giriş kişi kartını açar', (tester) async {
    await tester.pumpWidget(const KartvizitApp());

    // ListView's outer Scrollable is visited before nested text-field scrollers.
    Finder pageScroll() => find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    ).first;

    final manualEntry = find.text('Bilgileri elle gir');
    await tester.scrollUntilVisible(manualEntry, 200, scrollable: pageScroll());
    await tester.pumpAndSettle();
    await tester.tap(manualEntry);
    await tester.pumpAndSettle();
    expect(find.text('Kişi bilgilerini kontrol et'), findsOneWidget);
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
}
