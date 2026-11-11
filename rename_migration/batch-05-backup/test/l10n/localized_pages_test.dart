import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

import '../pages/page_goldens_test.dart' show PageCase, pageCases;
import '../support/music_harness.dart';

// Creation home (free and with a picked tile), purchase, video configuration, song/video progress.
const _pages = ['P01', 'P01-inspirations', 'P03', 'P08', 'P20', 'P05', 'P24'];

Future<void> _show(
  WidgetTester tester,
  PageCase page,
  Locale locale, {
  TestDevice device = TestDevice.iPhone17Pro,
  double scale = 1,
}) async {
  final env = SongletTestEnv();
  page.setup?.call(env);
  await pumpRoute(
    tester,
    page.location,
    env: env,
    overrides: page.overrides,
    device: device,
    locale: locale,
    textScale: scale,
  );
  await page.prepare?.call(tester);
  await settleFrames(tester);
  if (page.id == 'P01-inspirations') await _walkInspirationGrid(tester);
  _expectReadableActions(tester);
}

void _expectReadableActions(WidgetTester tester) {
  expect(tester.takeException(), isNull);
  for (final text
      in find
          .descendant(
            of: find.byWidgetPredicate(
              (w) => w is ObsButton || w is TemplateTile,
            ),
            matching: find.byType(Text),
          )
          .evaluate()) {
    final render = text.renderObject;
    if (render is RenderParagraph) {
      expect(
        render.didExceedMaxLines,
        isFalse,
        reason:
            'Primary action and idea name must be readable: ${render.text.toPlainText()}',
      );
      final tile = find.ancestor(
        of: find.byWidget(text.widget),
        matching: find.byType(TemplateTile),
      );
      if (tile.evaluate().isNotEmpty) {
        final bounds = tester.getRect(tile.first);
        final textBounds = tester.getRect(find.byWidget(text.widget));
        expect(textBounds.top, greaterThanOrEqualTo(bounds.top));
        expect(textBounds.bottom, lessThanOrEqualTo(bounds.bottom));
      }
    }
  }
}

// Lazy grid children must be checked throughout the scroll, not only at the
// first/last frame. Leave the viewport at the end for the inspiration golden.
Future<void> _walkInspirationGrid(WidgetTester tester) async {
  final scroll = tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position;
  scroll.jumpTo(0);
  await tester.pump();
  while (true) {
    _expectReadableActions(tester);
    if (scroll.pixels >= scroll.maxScrollExtent) break;
    scroll.jumpTo(
      (scroll.pixels + scroll.viewportDimension / 2).clamp(
        0,
        scroll.maxScrollExtent,
      ),
    );
    await tester.pump();
  }
  await settleFrames(tester);
  expect(find.byKey(const ValueKey('tile.weather_report')), findsOneWidget);
}

Future<void> _showBottom(WidgetTester tester) async {
  final scroll = tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position;
  // Lazy page children can increase the scroll extent after the first jump.
  for (var i = 0; i < 4; i++) {
    scroll.jumpTo(scroll.maxScrollExtent);
    await tester.pump();
  }
  await settleFrames(tester);
  _expectReadableActions(tester);
}

void main() {
  setUp(mockNativeChannels);
  PageCase page(String id) => pageCases.firstWhere((p) => p.id == id);
  for (final tag in ['de', 'hi']) {
    final locale = Locale(tag);
    for (final id in _pages) {
      testWidgets('$tag $id golden and layout', (tester) async {
        await _show(tester, page(id), locale);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('../goldens/l10n/${tag}_$id.png'),
        );
      });
    }
    for (final id in ['P08', 'P20']) {
      testWidgets('$tag $id lower content golden', (tester) async {
        await _show(tester, page(id), locale);
        await _showBottom(tester);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('../goldens/l10n/${tag}_${id}_bottom.png'),
        );
      });
    }
  }
  for (final tag in ['de', 'hi', 'vi']) {
    for (final id in _pages) {
      for (final scale in [1.0, TextScale.largestAccessibility]) {
        testWidgets('$tag $id small phone text scale $scale', (tester) async {
          await _show(
            tester,
            page(id),
            Locale(tag),
            device: TestDevice.iPhoneSE,
            scale: scale,
          );
          if (id == 'P08' || id == 'P20') {
            await _showBottom(tester);
          }
        });
      }
    }
  }
}
