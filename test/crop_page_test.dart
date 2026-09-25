import 'dart:async';
import 'package:kartvizit_cep/widgets/ivory_button.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizit_cep/screens/crop_page.dart';

/// A red image with a blue rectangle inset by 20% on every side, so a crop
/// that clears that margin should contain no red pixels.
Future<Uint8List> _redWithBlueCenter({int width = 300, int height = 200}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = Colors.red,
  );
  canvas.drawRect(
    Rect.fromLTWH(
      width * 0.2,
      height * 0.2,
      width * 0.6,
      height * 0.6,
    ),
    Paint()..color = Colors.blue,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } finally {
    image.dispose();
  }
}

Future<ui.Image> _decode(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

/// Pumps with real delays (only valid inside tester.runAsync()) until
/// [condition] holds or a generous timeout elapses.
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Condition not met within $timeout');
    }
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  await tester.pump();
}

Future<bool> _containsRed(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  for (var i = 0; i < bytes.length; i += 4) {
    // Pure red: R high, G and B near zero.
    if (bytes[i] > 200 && bytes[i + 1] < 60 && bytes[i + 2] < 60) {
      return true;
    }
  }
  return false;
}

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

  testWidgets(
    'Köşeler içeri sürüklenince kırpma gerçekten dar alanı kullanır',
    (tester) async {
      CropSelection? selection;
      // Real dart:ui codec work (both the test image generation and the
      // crop itself) doesn't resolve under the test binding's fake async
      // zone, so the whole interaction runs for real via runAsync(). For
      // the same reason, pumpAndSettle() can't be used while
      // CircularProgressIndicator (or anything else with its own
      // animation) is on screen - it never considers the tree settled -
      // so progress is driven by plain pump() calls plus real delays.
      await tester.runAsync(() async {
        final bytes = await _redWithBlueCenter();
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  selection = await Navigator.of(context).push<CropSelection>(
                    MaterialPageRoute(
                      builder: (_) => CropPage(
                        imagePath: '/fake/card.png',
                        imageLoader: () async => bytes,
                      ),
                    ),
                  );
                },
                child: const Text('Aç'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Aç'));
        await _pumpUntil(tester, () => find.byIcon(Icons.open_with).evaluate().length == 4);

        final handles = find.byIcon(Icons.open_with);
        final topLeft = tester.getCenter(handles.at(0));
        final bottomRight = tester.getCenter(handles.at(3));
        final boxWidth = bottomRight.dx - topLeft.dx;
        final boxHeight = bottomRight.dy - topLeft.dy;

        // Drag both corners well past the 20% red margin baked into the
        // test image, so a correct crop can contain no red pixels at all.
        await tester.drag(
          handles.at(0),
          Offset(boxWidth * 0.35, boxHeight * 0.35),
        );
        await tester.pump();
        await tester.drag(
          find.byIcon(Icons.open_with).at(3),
          Offset(-boxWidth * 0.35, -boxHeight * 0.35),
        );
        await tester.pump();

        await tester.tap(find.text('Kırp ve oku'));
        await _pumpUntil(tester, () => selection != null);

        final croppedBytes = selection?.bytes;
        expect(croppedBytes, isNotNull);

        final cropped = await _decode(croppedBytes!);
        try {
          expect(cropped.width, lessThan(250));
          expect(cropped.height, lessThan(170));
          expect(await _containsRed(cropped), isFalse);
        } finally {
          cropped.dispose();
        }
      });

      expect(selection, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );
}
