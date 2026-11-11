import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../support/music_harness.dart';
import 'page_goldens_test.dart' show pageCases;

/// Renders every prototype page at the prototypes' own design size (393×852
/// pt, ADR-0007) into `build/diff_report/actual/` for `tool/diff_report`.
/// Captures, not goldens: nothing is compared here and nothing is committed
/// (`make diff-report` runs this, then the tool).
void main() {
  setUp(mockNativeChannels);
  const out = 'build/diff_report/actual';

  setUpAll(
    () => goldenFileComparator = _WriteOnlyComparator(
      Directory(out).absolute.uri,
    ),
  );

  // The light colour tokens, so the (Flutter-free) tool reads them from the
  // one source instead of a copy.
  test('export colour tokens', () {
    const c = SongletColors.light;
    String hex(Color color) =>
        '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    final tokens = {
      'canvas': hex(c.canvas),
      'surface': hex(c.surface),
      'surfaceMuted': hex(c.surfaceMuted),
      'hairline': hex(c.hairline),
      'accent': hex(c.accent),
      'accentSoft': hex(c.accentSoft),
      'ink': hex(c.ink),
      'inkSecondary': hex(c.inkSecondary),
      'inkTertiary': hex(c.inkTertiary),
      'success': hex(c.success),
      'danger': hex(c.danger),
    };
    File('$out/../tokens.json')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(tokens));
  });

  for (final page in pageCases) {
    testWidgets('capture ${page.id}', (tester) async {
      final env = MusicTestEnv();
      page.setup?.call(env);
      await pumpRoute(
        tester,
        page.location,
        env: env,
        overrides: page.overrides,
        device: MusicTestDevice.design,
      );
      if (page.id == 'P03a') {
        env.speech.session?.add(
          const MusicSpeechPartial(
            "It's Alex's thirtieth birthday, she loves hiking and Sunday coffee",
          ),
        );
      }
      await page.prepare?.call(tester);
      await settleFrames(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('${page.id}.png'),
      );
    });
  }
}

/// Writes every "golden" to [base] and reports a match.
class _WriteOnlyComparator extends GoldenFileComparator {
  _WriteOnlyComparator(this.base);

  final Uri base;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    await update(golden, imageBytes);
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    final file = File.fromUri(base.resolveUri(golden));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(imageBytes);
  }
}
