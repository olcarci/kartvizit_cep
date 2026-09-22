import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizit_cep/widgets/gold_shimmer.dart';

void main() {
  testWidgets('Parlama çalışırken dokunma geçer, hareket azaltmada durur', (tester) async {
    var taps = 0;
    Future<void> mount(bool reduced) => tester.pumpWidget(MaterialApp(home: MediaQuery(data: MediaQueryData(disableAnimations: reduced), child: Scaffold(body: GoldShimmer(child: TextButton(onPressed: () => taps++, child: const Text('Aç')))))));
    await mount(false);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.tap(find.text('Aç'));
    expect(taps, 1);
    await mount(true);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 8));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
