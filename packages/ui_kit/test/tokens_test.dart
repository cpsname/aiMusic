import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

double _luminance(Color c) => c.computeLuminance();

double _contrast(Color a, Color b) {
  final l1 = _luminance(a), l2 = _luminance(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  group('spacing', () {
    const steps = [
      SongletSpace.x1, SongletSpace.x2, SongletSpace.x3, SongletSpace.x4,
      SongletSpace.x5, SongletSpace.x6, SongletSpace.x7, SongletSpace.x8,
      SongletSpace.x10, SongletSpace.x12, SongletSpace.x16,
      SongletSpace.gutter, SongletSpace.gutterRegular,
    ];
    test('every step is a multiple of 4', () {
      for (final s in steps) {
        expect(s % 4, 0, reason: '$s');
      }
    });
    test('scale is strictly increasing', () {
      final scale = steps.take(11).toList();
      for (var i = 1; i < scale.length; i++) {
        expect(scale[i], greaterThan(scale[i - 1]));
      }
    });
  });

  test('radii follow docs/ui (cards 20, sheets 24, controls 16)', () {
    expect(SongletRadius.card, 20);
    expect(SongletRadius.sheet, 24);
    expect(SongletRadius.control, 16);
    expect(SongletRadius.cardAll, const BorderRadius.all(Radius.circular(20)));
  });

  test('light roles use the specified brand colours', () {
    const c = SongletColors.light;
    expect(c.canvas, const Color(0xFFFFF6EE));
    expect(c.accent, const Color(0xFFC9472B));
    expect(c.ink, const Color(0xFF1A1A1A));
    expect(c.inkSecondary, const Color(0xFF8A8A8A));
  });

  group('contrast', () {
    for (final (name, c) in [
      ('light', SongletColors.light),
      ('dark', SongletColors.dark),
    ]) {
      test('$name: primary text ≥ 7:1 on canvas and surface', () {
        expect(_contrast(c.ink, c.canvas), greaterThanOrEqualTo(7));
        expect(_contrast(c.ink, c.surface), greaterThanOrEqualTo(7));
      });
      test('$name: action label ≥ 4.5:1 on accent', () {
        expect(_contrast(c.onAccent, c.accent), greaterThanOrEqualTo(4.5));
      });
      test('$name: secondary text ≥ 3:1 (supporting text, AA large / UI)', () {
        expect(_contrast(c.inkSecondary, c.canvas), greaterThanOrEqualTo(3));
        expect(_contrast(c.inkSecondary, c.surface), greaterThanOrEqualTo(3));
      });
      test('$name: danger ≥ 4.5:1 on its banner fill', () {
        expect(_contrast(c.danger, c.dangerSoft), greaterThanOrEqualTo(4.5));
      });
      test('$name: badge text ≥ 4.5:1', () {
        expect(
          _contrast(c.onBadge, Color.alphaBlend(c.badgeFill, c.surface)),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });

  test('type scale is ordered largest to smallest with sane line heights', () {
    for (var i = 1; i < SongletType.scale.length; i++) {
      expect(
        SongletType.scale[i].fontSize,
        lessThanOrEqualTo(SongletType.scale[i - 1].fontSize!),
      );
    }
    for (final style in SongletType.scale) {
      expect(style.height, inInclusiveRange(1.0, 1.5));
      expect(style.color, isNull, reason: 'colour comes from the theme');
    }
  });

  test('motion durations increase from instant to emphasized', () {
    const ordered = [
      SongletMotion.none,
      SongletMotion.instant,
      SongletMotion.fast,
      SongletMotion.standard,
      SongletMotion.emphasized,
    ];
    for (var i = 1; i < ordered.length; i++) {
      expect(ordered[i], greaterThan(ordered[i - 1]));
    }
  });

  test('elevation levels grow in blur', () {
    for (final e in [SongletElevation.light, SongletElevation.dark]) {
      expect(e.level2.first.blurRadius, greaterThan(e.level1.first.blurRadius));
      expect(e.level3.first.blurRadius, greaterThan(e.level2.first.blurRadius));
    }
  });

  group('theme', () {
    for (final brightness in Brightness.values) {
      test('$brightness carries every Songlet extension', () {
        final theme = AuraTheme.songlet(brightness);
        final colors = theme.extension<SongletColors>()!;
        expect(theme.brightness, brightness);
        expect(theme.scaffoldBackgroundColor, colors.canvas);
        expect(theme.colorScheme.primary, colors.accent);
        expect(theme.extension<SongletElevation>(), isNotNull);
        expect(theme.extension<AuraStyle>()!.accent, colors.accent);
        expect(theme.textTheme.displayLarge!.fontSize, SongletType.largeTitle.fontSize);
        expect(theme.textTheme.bodyLarge!.color, colors.ink);
      });
    }

    test('colour roles lerp between light and dark', () {
      final mid = SongletColors.light.lerp(SongletColors.dark, 0.5);
      expect(mid.canvas, Color.lerp(SongletColors.light.canvas, SongletColors.dark.canvas, 0.5));
      expect(SongletColors.light.lerp(null, 0.5), SongletColors.light);
    });

    testWidgets('SongletColors.of follows the ambient brightness', (tester) async {
      late SongletColors light, dark;
      await tester.pumpWidget(MaterialApp(
        theme: AuraTheme.warm,
        home: Builder(builder: (c) {
          light = SongletColors.of(c);
          return const SizedBox();
        }),
      ));
      await tester.pumpWidget(MaterialApp(
        theme: AuraTheme.warmDark,
        home: Builder(builder: (c) {
          dark = SongletColors.of(c);
          return const SizedBox();
        }),
      ));
      await tester.pumpAndSettle();
      expect(light, SongletColors.light);
      expect(dark, SongletColors.dark);
    });
  });
}
