import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songlet/l10n/ui_locale.dart';
import 'package:songlet/ui/settings/ui_language_sheet.dart';
import 'package:ui_kit/ui_kit.dart';

import '../support/music_harness.dart';
import 'ui_language_test.dart' show openPicker;

void checkRows(WidgetTester tester) {
  expect(tester.takeException(), isNull);
  final rows = find.byWidgetPredicate(
    (widget) => widget is OptionRow || widget is SettingsRow,
  );
  for (final element
      in find.descendant(of: rows, matching: find.byType(Text)).evaluate()) {
    final render = element.renderObject;
    if (render is RenderParagraph) {
      expect(
        render.didExceedMaxLines,
        isFalse,
        reason: render.text.toPlainText(),
      );
    }
  }
}

Future<void> walkPicker(WidgetTester tester) async {
  final scroll = tester
      .state<ScrollableState>(
        find.descendant(
          of: find.byType(UiLanguageSheet),
          matching: find.byType(Scrollable),
        ),
      )
      .position;
  while (true) {
    checkRows(tester);
    if (scroll.pixels >= scroll.maxScrollExtent) break;
    scroll.jumpTo(
      (scroll.pixels + scroll.viewportDimension / 2).clamp(
        0,
        scroll.maxScrollExtent,
      ),
    );
    await tester.pump();
  }
  expect(
    find.byKey(const ValueKey('settings.uiLanguage.tr')).hitTestable(),
    findsOneWidget,
  );
}

void main() {
  setUpAll(() async {
    // The picker mixes autonyms from several scripts regardless of UI locale.
    // flutter_test has no automatic system-font fallback (the device does).
    const fonts = {
      'SongletGoldenCJK': '/System/Library/Fonts/Hiragino Sans GB.ttc',
      'SongletGoldenJP': '/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc',
      'SongletGoldenKR': '/System/Library/Fonts/AppleSDGothicNeo.ttc',
    };
    for (final entry in fonts.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(
          Future.value(
            ByteData.sublistView(File(entry.value).readAsBytesSync()),
          ),
        );
      await loader.load();
    }
  });
  setUp(mockNativeChannels);
  for (final tag in ['de', 'hi', 'vi']) {
    for (final scale in [1.0, TextScale.largestAccessibility]) {
      testWidgets(
        '$tag language settings and picker on small phone at $scale',
        (tester) async {
          final env = SongletTestEnv()
            ..preferences = {UiLanguagePreference.key: tag};
          await pumpRoute(
            tester,
            '/settings',
            env: env,
            dynamicLocale: true,
            fontFamilyFallback: const [
              'SongletGoldenCJK',
              'SongletGoldenJP',
              'SongletGoldenKR',
            ],
            device: TestDevice.iPhoneSE,
            textScale: scale,
          );
          await reveal(
            tester,
            find.byKey(const ValueKey('settings.uiLanguage')),
          );
          checkRows(tester);
          await openPicker(tester);
          await walkPicker(tester);
        },
      );
    }
  }
  for (final tag in ['de', 'hi']) {
    testWidgets('$tag settings language group and picker goldens', (
      tester,
    ) async {
      final env = SongletTestEnv()
        ..preferences = {UiLanguagePreference.key: tag};
      await pumpRoute(
        tester,
        '/settings',
        env: env,
        dynamicLocale: true,
        fontFamilyFallback: const [
          'SongletGoldenCJK',
          'SongletGoldenJP',
          'SongletGoldenKR',
        ],
      );
      await reveal(tester, find.byKey(const ValueKey('settings.language')));
      checkRows(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../goldens/l10n/${tag}_settings_language.png'),
      );
      await openPicker(tester);
      checkRows(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../goldens/l10n/${tag}_language_picker.png'),
      );
    });
  }
}
