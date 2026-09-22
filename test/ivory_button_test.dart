import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizit_cep/widgets/ivory_button.dart';

void main() {
  testWidgets('Hover lifts, touch activates once, disabled cannot activate', (
    tester,
  ) async {
    var count = 0;
    Future<void> mount(bool enabled, {bool reduced = false}) =>
        tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: Scaffold(
                body: Center(
                  child: IvoryButton(
                    label: 'Toplu tarama',
                    icon: Icons.layers,
                    onPressed: enabled ? () => count++ : null,
                  ),
                ),
              ),
            ),
          ),
        );
    await mount(true);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(IvoryButton)));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AnimatedContainer>(find.byType(AnimatedContainer))
          .transform!
          .storage[13],
      -5,
    );
    await tester.tap(find.text('Toplu tarama'));
    await tester.pumpAndSettle();
    expect(count, 1);
    await mount(false);
    await tester.tap(find.text('Toplu tarama'));
    expect(count, 1);
    await mount(true, reduced: true);
    await mouse.moveTo(tester.getCenter(find.byType(IvoryButton)));
    await tester.pumpAndSettle();
    expect(
      tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).duration,
      Duration.zero,
    );
    await mouse.removePointer();
  });
}
