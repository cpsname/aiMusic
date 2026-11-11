import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

Widget _host(Widget child, {ThemeData? theme}) => MaterialApp(
      theme: theme ?? AuraTheme.warm,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('AuraStyle resolves warm surfaces from the theme, aura by default',
      (tester) async {
    late AuraStyle warm;
    late AuraStyle fallback;
    await tester.pumpWidget(_host(Builder(builder: (c) {
      warm = AuraStyle.of(c);
      return const SizedBox();
    })));
    await tester.pumpWidget(_host(Builder(builder: (c) {
      fallback = AuraStyle.of(c);
      return const SizedBox();
    }), theme: ThemeData()));
    await tester.pumpAndSettle(); // the theme change animates
    expect(warm.accent, SongletPalette.terracotta);
    expect(warm.cardBlur, isFalse);
    expect(fallback.cardFill, StudioTokens.glassFill);
  });

  testWidgets('GlassCard hosts ink children on a Material (no hidden splashes)',
      (tester) async {
    await tester.pumpWidget(_host(const GlassCard(child: ListTile(title: Text('Row')))));
    expect(tester.takeException(), isNull);
    expect(find.text('Row'), findsOneWidget);
  });

  testWidgets('PillChip reports taps and removals', (tester) async {
    var taps = 0;
    var removed = 0;
    await tester.pumpWidget(_host(PillChip(
      label: 'coffee',
      selected: true,
      onTap: () => taps++,
      onRemove: () => removed++,
    )));
    await tester.tap(find.text('coffee'));
    await tester.tap(find.byIcon(Icons.close_rounded));
    expect((taps, removed), (1, 1));
  });

  testWidgets('WaveformView maps a tap to a 0..1 seek position (ltr and rtl)',
      (tester) async {
    double? seek;
    Widget wave(TextDirection d) => Directionality(
          textDirection: d,
          child: SizedBox(
            width: 200,
            child: WaveformView(
              bars: List.filled(20, 0.5),
              progress: 0.3,
              activeColor: Colors.red,
              inactiveColor: Colors.grey,
              onSeek: (v) => seek = v,
            ),
          ),
        );
    await tester.pumpWidget(_host(wave(TextDirection.ltr)));
    final box = tester.getRect(find.byType(WaveformView));
    await tester.tapAt(Offset(box.left + 50, box.center.dy));
    expect(seek, closeTo(0.25, 0.01));
    await tester.pumpWidget(_host(wave(TextDirection.rtl)));
    await tester.tapAt(Offset(box.left + 50, box.center.dy));
    expect(seek, closeTo(0.75, 0.01));
  });

  testWidgets('AiGeneratedBadge always shows its label and exposes it to a11y',
      (tester) async {
    await tester.pumpWidget(_host(const AiGeneratedBadge(label: 'AI generated')));
    expect(find.text('AI generated'), findsOneWidget);
    expect(find.bySemanticsLabel('AI generated'), findsWidgets);
  });
}
