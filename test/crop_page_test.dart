import 'dart:async';
import 'package:kartvizit_cep/widgets/ivory_button.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizit_cep/screens/crop_page.dart';

void main() {
  testWidgets('Açılamayan fotoğrafta kırpmadan devam edilebilir', (tester) async {
    CropSelection? selection;
    final image = Completer<Uint8List>();
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) =>
      TextButton(onPressed: () async {
        selection = await Navigator.of(context).push<CropSelection>(
          MaterialPageRoute(builder: (_) => CropPage(
            imagePath: '/missing/card.png', imageLoader: () => image.future,
          )),
        );
      }, child: const Text('Aç')),
    )));
    await tester.tap(find.text('Aç'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    image.completeError(StateError('Fotoğraf açılamadı'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bu fotoğraf kırpma ekranında açılamadı'), findsOneWidget);
    expect(tester.widget<IvoryButton>(find.byType(IvoryButton)).onPressed, isNull);
    await tester.tap(find.text('Kırpmadan devam et'));
    await tester.pumpAndSettle();
    expect(selection, isNotNull);
    expect(selection!.bytes, isNull);
    expect(find.text('Aç'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
