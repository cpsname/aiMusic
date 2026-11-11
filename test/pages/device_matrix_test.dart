import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/music_harness.dart';
import 'page_goldens_test.dart' show PageCase, pageCases;

/// Device matrix (Phase 5).
///
/// * Layout sweep: every prototype page on every device of the matrix,
///   portrait and iPad landscape, at the default text size and at the largest
///   accessibility Dynamic Type. Any overflow, unbounded layout or build error
///   is reported by the framework as an exception and fails the case.
/// * Goldens for review: the core pages across the matrix (the create home's
///   composer states A / B / C and the iPad two-pane layout included), six
///   pages at AX5 and two in dark mode, under
///   `test/goldens/matrix/` (rendered at 1×: layout review, not pixel diff —
///   the design-device pixel goldens are `test/goldens/pages/`).
const _matrixPages = {
  'P01',
  'P01-options',
  'P01-picked',
  'P01-keyboard',
  'P03',
  'P03-options',
  'P03-keyboard',
  'P07',
  'P09',
  'P12',
};
const _largeTextPages = {
  'P01',
  'P01-options',
  'P03',
  'P03-options',
  'P08',
  'P09',
};
const _darkPages = {'P01', 'P09'};

void main() {
  setUp(mockNativeChannels);

  for (final scale in [1.0, TextScale.largestAccessibility]) {
    for (final device in MusicTestDevice.matrix) {
      for (final page in pageCases) {
        // Layout errors fail the case through the test binding, with the
        // offending widget's location in the report.
        testWidgets(
          '${page.id} · ${device.name} · text ×$scale',
          (tester) => _pump(tester, page, device, scale),
        );
      }
    }
  }

  PageCase page(String id) => pageCases.firstWhere((p) => p.id == id);
  Future<void> golden(WidgetTester tester, String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../goldens/matrix/$name.png'),
  );

  for (final device in MusicTestDevice.matrix) {
    for (final id in _matrixPages) {
      testWidgets('golden $id · ${device.name}', (tester) async {
        await _pump(tester, page(id), device.withPixelRatio(1), 1);
        await golden(tester, '${id}_${device.name}');
      });
    }
  }
  for (final id in _largeTextPages) {
    testWidgets('golden $id · AX5', (tester) async {
      await _pump(
        tester,
        page(id),
        MusicTestDevice.iPhone17Pro.withPixelRatio(1),
        TextScale.largestAccessibility,
      );
      await golden(tester, '${id}_ax5');
    });
  }
  for (final id in _darkPages) {
    testWidgets('golden $id · dark', (tester) async {
      await _pump(
        tester,
        page(id),
        MusicTestDevice.iPhone17Pro.withPixelRatio(1),
        1,
        brightness: Brightness.dark,
      );
      await golden(tester, '${id}_dark');
    });
  }
}

Future<void> _pump(
  WidgetTester tester,
  PageCase page,
  MusicTestDevice device,
  double scale, {
  Brightness brightness = Brightness.light,
}) async {
  final env = MusicTestEnv();
  page.setup?.call(env);
  await pumpRoute(
    tester,
    page.location,
    env: env,
    overrides: page.overrides,
    device: device,
    textScale: scale,
    brightness: brightness,
  );
  await page.prepare?.call(tester);
  await settleFrames(tester);
}
