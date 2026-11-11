import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: AuraTheme.dark, home: Scaffold(body: child));

void main() {
  testWidgets('AuroraBackground renders its child and advances via single-frame pump',
      (tester) async {
    await tester.pumpWidget(_wrap(const AuroraBackground(child: Text('hi'))));
    expect(find.text('hi'), findsOneWidget);
    // Must not hang on the perpetual animation (never pumpAndSettle).
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(AuroraBackground), findsOneWidget);
  });

  testWidgets('GradientText shows its text', (tester) async {
    await tester.pumpWidget(_wrap(const GradientText('Aurora')));
    expect(find.text('Aurora'), findsOneWidget);
  });

  testWidgets('GlassCard renders its child and reports taps', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(GlassCard(onTap: () => tapped = true, child: const Text('card'))),
    );
    expect(find.text('card'), findsOneWidget);
    await tester.tap(find.text('card'));
    expect(tapped, isTrue);
  });

  testWidgets('ObsButton fires onPressed; loading shows a spinner and disables',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(ObsButton(label: 'Buy', onPressed: () => taps++)));
    await tester.tap(find.text('Buy'));
    expect(taps, 1);

    await tester.pumpWidget(
      _wrap(ObsButton(label: 'Buy', loading: true, onPressed: () => taps++)),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(ObsButton), warnIfMissed: false);
    expect(taps, 1); // still disabled while loading
  });

  testWidgets('AuraSkeleton renders and shimmers via single-frame pump',
      (tester) async {
    await tester.pumpWidget(_wrap(const AuraSkeleton(width: 120)));
    expect(find.byType(AuraSkeleton), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(AuraSkeleton), findsOneWidget);
  });

  testWidgets('Typewriter completes to the full text', (tester) async {
    await tester.pumpWidget(
      _wrap(const Typewriter('Hello', duration: Duration(milliseconds: 50))),
    );
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('Hello'), findsOneWidget);
  });
}
