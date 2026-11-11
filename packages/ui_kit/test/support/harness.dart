import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

/// A 2×2 terracotta PNG standing in for template / photo art.
final MemoryImage testArt = MemoryImage(Uint8List.fromList(const [
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 2, 0, 0, 0, 2, 8, 2, 0, 0, 0, //
  253, 212, 154, 115, 0, 0, 0, 16, 73, 68, 65, 84, 120, 156, 99, 216, 154, 234, 5, 68, 12, 16, 10, 0, //
  40, 170, 5, 145, 22, 210, 1, 219, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
]));

/// Deterministic waveform bars.
final List<double> testBars = [
  for (var i = 0; i < 48; i++) 0.25 + 0.7 * ((i * 37) % 17) / 16,
];

const Key captureKey = ValueKey('capture');

/// Hosts [child] in the Songlet theme at phone width, reduce-motion on.
Future<void> pumpComponent(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
  double width = 393,
  double height = 852,
}) async {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AuraTheme.songlet(brightness),
      home: MotionPolicyOverride(
        reduceMotion: true,
        child: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: SingleChildScrollView(
              child: RepaintBoundary(
                key: captureKey,
                child: Builder(
                  builder: (context) => ColoredBox(
                    color: SongletColors.of(context).canvas,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(SongletSpace.x4),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.runAsync(() => precacheImage(testArt, tester.element(find.byKey(captureKey))));
  await tester.pump();
}

/// Golden variants every component sheet is captured in.
const goldenVariants = <(String, Brightness, TextDirection)>[
  ('light', Brightness.light, TextDirection.ltr),
  ('dark', Brightness.dark, TextDirection.ltr),
  ('rtl', Brightness.light, TextDirection.rtl),
];

/// Captures [sheet] in every [goldenVariants] entry as `goldens/<name>_<v>.png`.
void goldenSheet(String name, Widget Function() sheet, {double height = 852}) {
  for (final (variant, brightness, direction) in goldenVariants) {
    testWidgets('$name golden · $variant', (tester) async {
      await pumpComponent(tester, sheet(), brightness: brightness, direction: direction, height: height);
      await expectLater(find.byKey(captureKey), matchesGoldenFile('../goldens/components/${name}_$variant.png'));
    });
  }
}

/// Spacing between items on a golden sheet.
Widget gap() => const SizedBox(height: SongletSpace.x4);
