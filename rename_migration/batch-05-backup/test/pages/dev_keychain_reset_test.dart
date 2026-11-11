import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

import '../support/music_harness.dart';

/// The DEV-only Keychain reset in Settings. `devKeychainResetAvailable` is a
/// compile-time constant, so this file runs twice (`make test`): without
/// defines (production-like — the hidden group runs) and with
/// `--dart-define=ENV=dev` (the visible group runs).
void main() {
  setUp(mockNativeChannels);

  const entry = ValueKey('settings.dev.keychainReset');

  group('outside DEV (no ENV=dev define)', skip: devKeychainResetAvailable, () {
    testWidgets('no entry, no section, and nothing to call', (tester) async {
      final container = await pumpRoute(tester, '/settings');
      // The whole page, down to its end.
      final page = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      page.jumpTo(page.maxScrollExtent);
      await settleFrames(tester);
      expect(find.byKey(entry), findsNothing);
      expect(find.text('Developer (DEV only)'), findsNothing);
      expect(
        container.read(devKeychainResetProvider),
        isNull,
        reason: 'the logic layer hands out nothing',
      );
    });
  });

  group('DEV debug build (ENV=dev)', skip: !devKeychainResetAvailable, () {
    testWidgets('the entry asks first; cancel changes nothing, delete resets', (
      tester,
    ) async {
      await pumpRoute(tester, '/settings');
      await reveal(tester, find.byKey(entry));
      expect(find.text('Developer (DEV only)'), findsOneWidget);

      await tester.tap(find.byKey(entry));
      await settleFrames(tester);
      expect(find.text('Delete Keychain keys?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settleFrames(tester);
      expect(find.text('Delete Keychain keys?'), findsNothing);
      expect(
        find.text('Keychain keys deleted — signed in as a new guest'),
        findsNothing,
      );

      await tester.tap(find.byKey(entry));
      await settleFrames(tester);
      await tester.tap(
        find.byKey(const ValueKey('settings.dev.keychainReset.confirm')),
      );
      await settleFrames(tester);
      expect(
        find.text('Keychain keys deleted — signed in as a new guest'),
        findsOneWidget,
      );
    });
  });
}
