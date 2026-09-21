import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizit_cep/widgets/contact_quick_actions.dart';

void main() {
  testWidgets('Boş alan pasif; değişiklik sonrası güncel site açılır', (tester) async {
    final fields = List.generate(9, (_) => TextEditingController());
    Uri? opened;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: ContactQuickActions(fields: fields, opener: (uri) async { opened = uri; return true; }),
    ))));
    expect(tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Web sitesini aç')).onPressed, isNull);
    fields[5].text = 'www.example.com';
    await tester.pump();
    await tester.tap(find.text('Web sitesini aç'));
    await tester.pumpAndSettle();
    expect(opened?.host, 'www.example.com');
    fields[3].text = '05301082510\n05301082511';
    await tester.pump();
    await tester.tap(find.text('Ara'));
    await tester.pumpAndSettle();
    expect(find.text('Aranacak numarayı seç'), findsOneWidget);
    await tester.tap(find.text('+905301082511'));
    await tester.pumpAndSettle();
    expect(opened?.scheme, 'tel');
    expect(opened?.path, '+905301082511');
    await tester.pumpWidget(const SizedBox());
    for (final field in fields) { field.dispose(); }
  });
}
