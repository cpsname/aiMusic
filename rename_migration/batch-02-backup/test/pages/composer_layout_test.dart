import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songlet/ui/create/composer_budget.dart';
import 'package:ui_kit/ui_kit.dart';

import '../support/songlet_harness.dart';

/// The create home's space rules (ADR-0034) measured on every device of the
/// matrix, in each composer state, with and without the keyboard:
/// * phones: the composer at most 35 % of the screen folded and 55 %
///   unfolded, a full row of tiles always in view with the keyboard down;
///   with it up, the composer above it — free input still shows a row, a
///   picked card or the options fold the grid and keep the card's head;
/// * iPad: the composer in its own pane beside the grid, nothing overlapping;
/// * everywhere: the primary action can be pressed, and unfolded options
///   come into view.
void main() {
  setUp(mockNativeChannels);

  const states = <(String, String, {bool picked, bool unfolded})>[
    ('A', '/create', picked: false, unfolded: false),
    ('B', '/create?template=birthday_wish', picked: true, unfolded: false),
    ('C over A', '/create?options=1', picked: false, unfolded: true),
    ('C over B', '/create?template=birthday_wish&options=1', picked: true, unfolded: true),
  ];

  /// Tolerance for sub-pixel rounding.
  const epsilon = 0.5;

  Rect composer(WidgetTester tester) => tester.getRect(find.byType(ComposerCard));
  Finder grid() => find.byType(SliverGrid);
  Rect gridViewport(WidgetTester tester) =>
      tester.getRect(find.ancestor(of: grid(), matching: find.byType(Scrollable)).first);

  /// Whether a whole tile shows inside the grid's viewport.
  bool fullRowShows(WidgetTester tester) {
    final viewport = gridViewport(tester);
    final tiles = find.descendant(of: grid(), matching: find.byType(TemplateTile));
    for (final element in tiles.evaluate()) {
      final rect = tester.getRect(find.byWidget(element.widget));
      if (rect.top >= viewport.top - epsilon && rect.bottom <= viewport.bottom + epsilon) return true;
    }
    return false;
  }

  for (final device in TestDevice.matrix) {
    final phone = device.size.shortestSide < SongletSize.twoPaneBreakpoint;
    for (final (name, location, :picked, :unfolded) in states) {
      for (final keyboard in [false, true]) {
        testWidgets('${device.name} · $name · keyboard ${keyboard ? 'up' : 'down'}', (tester) async {
          await pumpRoute(tester, location, device: device);
          await settleFrames(tester);
          if (keyboard) {
            await showKeyboard(tester);
            await settleFrames(tester);
          }
          expect(tester.takeException(), isNull);
          final height = device.size.height;
          final card = composer(tester);
          final keyboardTop = height - (keyboard ? keyboardHeightFor(device.size) : 0);
          expect(card.bottom, lessThanOrEqualTo(keyboardTop + epsilon), reason: 'the composer stays above the keyboard');
          expect(find.byKey(const ValueKey('composer.create')).hitTestable(), findsOneWidget, reason: 'the primary action can be pressed');
          if (picked) {
            expect(
              find.descendant(of: find.byType(ComposerTag), matching: find.byIcon(Icons.close_rounded)).hitTestable(),
              findsOneWidget,
              reason: "the picked card's head stays in view",
            );
          }

          if (unfolded && !keyboard) {
            expect(find.byKey(const ValueKey('composer.length')).hitTestable(), findsOneWidget,
                reason: 'unfolded, the selectors come into view');
          }

          if (!phone) {
            expect(grid(), findsOneWidget, reason: 'the iPad never folds the grid');
            final viewport = gridViewport(tester);
            expect(viewport.overlaps(card), isFalse, reason: 'the composer pane beside the grid, not over it');
            expect(card.left, greaterThanOrEqualTo(viewport.right), reason: 'grid leading, composer trailing');
            expect(fullRowShows(tester), isTrue);
            return;
          }
          if (!keyboard) {
            final share = unfolded ? ComposerBudget.openShare : ComposerBudget.foldedShare;
            expect(card.height, lessThanOrEqualTo(height * share + epsilon),
                reason: '${unfolded ? 'unfolded' : 'folded'} composer within ${(share * 100).round()} % of the screen');
            expect(fullRowShows(tester), isTrue, reason: 'a full row of tiles in view');
          } else if (picked || unfolded) {
            expect(grid(), findsNothing, reason: 'the grid folds for the keyboard');
          } else {
            expect(fullRowShows(tester), isTrue, reason: 'free input keeps a row with the keyboard up');
          }
        });
      }
    }
  }
}
