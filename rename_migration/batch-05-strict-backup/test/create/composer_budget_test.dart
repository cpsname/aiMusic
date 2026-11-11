import 'package:flutter_test/flutter_test.dart';
import 'package:songlet/ui/create/composer_budget.dart';

/// The composer's space rule (ADR-0034) on the matrix's phone heights.
void main() {
  // Logical heights of the matrix phones and the room under the brand header
  // (status bar, header, tab bar, home indicator and the composer's padding
  // off), and the same room with the keyboard up (header gone).
  const phones = <(String, double, double, double)>[
    ('iPhone SE', 667, 667 - 20 - 72 - 80 - 24, 667 - 20 - 260 - 24),
    ('iPhone 17 Pro', 874, 874 - 62 - 72 - 80 - 34 - 24, 874 - 62 - 336 - 24),
    (
      'iPhone 17 Pro Max',
      956,
      956 - 62 - 72 - 80 - 34 - 24,
      956 - 62 - 346 - 24,
    ),
  ];
  const gridMin = 125.0;

  ComposerBudget resolve(
    double screen,
    double room, {
    bool picked = false,
    bool unfolded = false,
    bool keyboard = false,
  }) => ComposerBudget.resolve(
    screenHeight: screen,
    roomHeight: room,
    gridMinExtent: gridMin,
    picked: picked,
    unfolded: unfolded,
    keyboard: keyboard,
  );

  for (final (name, screen, room, keyboardRoom) in phones) {
    group(name, () {
      test('folded: at most 35 % of the screen, a row of the grid left', () {
        for (final picked in [false, true]) {
          final b = resolve(screen, room, picked: picked);
          expect(
            b.maxHeight,
            lessThanOrEqualTo(screen * ComposerBudget.foldedShare),
          );
          expect(room - b.maxHeight, greaterThanOrEqualTo(gridMin));
          expect(b.gridCollapsed, isFalse);
        }
      });

      test('unfolded: at most 55 % of the screen, a row of the grid left', () {
        final b = resolve(screen, room, unfolded: true);
        expect(
          b.maxHeight,
          lessThanOrEqualTo(screen * ComposerBudget.openShare),
        );
        expect(room - b.maxHeight, greaterThanOrEqualTo(gridMin));
      });

      test('keyboard up, free input: a row of the grid stays', () {
        final b = resolve(screen, keyboardRoom, keyboard: true);
        expect(b.gridCollapsed, isFalse);
        expect(keyboardRoom - b.maxHeight, greaterThanOrEqualTo(gridMin));
      });

      test(
        'keyboard up with a pick or unfolded: the grid folds, the composer has the room',
        () {
          for (final (picked, unfolded) in [
            (true, false),
            (false, true),
            (true, true),
          ]) {
            final b = resolve(
              screen,
              keyboardRoom,
              picked: picked,
              unfolded: unfolded,
              keyboard: true,
            );
            expect(b.gridCollapsed, isTrue);
            expect(b.maxHeight, keyboardRoom);
          }
        },
      );
    });
  }

  test('the header steps aside for the keyboard only', () {
    expect(ComposerBudget.showsHeader(keyboard: false), isTrue);
    expect(ComposerBudget.showsHeader(keyboard: true), isFalse);
  });

  test('never negative on a room too short for anything', () {
    expect(resolve(400, 100).maxHeight, 0);
    expect(resolve(400, -10, picked: true, keyboard: true).maxHeight, 0);
  });
}
