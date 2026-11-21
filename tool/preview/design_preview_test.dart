import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/pages/page_goldens_test.dart' show pageCases;
import '../../test/support/music_harness.dart';

/// Renders the prototype pages to PNGs so the redesign can be looked at on a
/// host without the iOS fonts. Run with:
///
///     flutter test tool/preview/design_preview_test.dart --update-goldens
///
/// The images land next to this file in `design-preview/`.
const _ids = {
  'P01',
  'P01-options',
  'P01-picked',
  'P02a',
  'P03',
  'P05',
  'P07',
  'P09',
  'P12',
  'P08',
  'P30',
  'P10',
  'P20',
  'P24',
};

void main() {
  setUp(mockNativeChannels);

  for (final page in pageCases.where((p) => _ids.contains(p.id))) {
    testWidgets('${page.id} preview', (tester) async {
      final env = MusicTestEnv();
      page.setup?.call(env);
      await pumpRoute(
        tester,
        page.location,
        env: env,
        overrides: page.overrides,
        device: page.device ?? MusicTestDevice.iPhone17Pro,
      );
      await page.prepare?.call(tester);
      await settleFrames(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('design-preview/${page.id}.png'),
      );
    });
  }
}
