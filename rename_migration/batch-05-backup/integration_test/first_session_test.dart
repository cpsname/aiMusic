import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:songlet/main.dart' as app;
import 'package:songlet/ui/paywall/paywall_page.dart';
import 'package:ui_kit/ui_kit.dart';

/// First session end to end, in-process (Phase 6): the real app — native
/// bridge, network stack, ledger mirror — against the dev mock, on a
/// simulator.
///
///   make mock                          # terminal 1
///   make integration SIM=`udid`        # terminal 2
///
/// open → Birthday Wish picked, a name, the primary action (three decisions,
/// the request checked on the mock) → 30 s preview playing → "Get the full song" →
/// paywall → purchase (applied server-side, as in the XCUITest acceptance run:
/// a headless simulator cannot complete the StoreKit sheet) → the full song →
/// the share card. Timings land in the test report (`reportData`): debug-build
/// numbers on a simulator; `make perf DEVICE=…` runs the same test in profile
/// mode on a device (docs/perf/performance.md).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // The mock's admin API sits next to its /v1 (BASE_URL), so a device run
  // against a LAN mock reaches it too.
  const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8787/v1',
  );
  final admin = _MockAdmin(
    Uri.parse(baseUrl.replaceFirst(RegExp(r'/v1/?$'), '/__admin/')),
  );

  setUpAll(() async {
    await admin.post('reset');
    await admin.post('config', {
      'clip_delay_ms': 4000,
      'song_delay_ms': 6000,
      'mv_delay_ms': 5000,
    });
  });

  testWidgets(
    'first session: clip → paywall → full song → share card → lyric video → chorus video',
    (tester) async {
      final opened = DateTime.now();
      app.main();

      await _waitFor(tester, find.byKey(const ValueKey('tile.birthday_wish')));
      final interactive = DateTime.now().difference(opened);

      // The first session in three decisions (ADR-0033): who it is for (the
      // Birthday Wish tile), what to say (a name), start (the one primary
      // action) — length, vocals and genre are the summary row's defaults.
      // The grid starts as the 16 built-in templates and becomes the server's
      // list once attested (ADR-0032): pick only after it has (its tiles carry
      // the server's cover), so the tap does not land mid-swap.
      await _waitFor(
        tester,
        find.byWidgetPredicate(
          (w) => w is TemplateTile && w.image is NetworkImage,
        ),
      );
      var decisions = 0;
      await tester.tap(find.byKey(const ValueKey('tile.birthday_wish')));
      decisions++;
      await _waitFor(tester, find.byKey(const ValueKey('composer.name')));
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('composer.name')),
          matching: find.byType(TextField),
        ),
        'Alex',
      );
      decisions++;
      FocusManager.instance.primaryFocus?.unfocus();
      await _settle(tester);
      expect(
        tester
            .widget<ObsButton>(
              find.descendant(
                of: find.byKey(const ValueKey('composer.create')),
                matching: find.byType(ObsButton),
              ),
            )
            .label,
        contains('Alex'),
        reason: 'the action names who the preview is for (any UI language)',
      );
      await _tapRevealed(tester, find.byKey(const ValueKey('composer.create')));
      decisions++;
      expect(decisions, 3, reason: 'pick, name, press');

      // What reached the server (contract 02 v2.1): a preview of the scene,
      // the name in the prompt block, nothing else the composer did not show.
      Map<String, dynamic>? accepted;
      final asked = DateTime.now();
      while ((accepted = await admin.lastJob()) == null) {
        expect(
          DateTime.now().difference(asked),
          lessThan(const Duration(seconds: 30)),
          reason: 'the request reaches the mock',
        );
        await tester.pump(const Duration(milliseconds: 200));
      }
      final job = accepted!;
      expect(job['model'], 'lyria-3-clip-preview');
      expect(job['occasion'], 'birthday');
      expect(
        job['template'],
        'birthday_wish',
        reason: 'the scene slug sent as `inspiration`',
      );
      expect(job['region'], isNotEmpty);
      final lines = (job['prompt'] as String).split('\n');
      expect(lines.first, 'inspiration: birthday_wish');
      expect(lines, contains('recipient: Alex'));
      expect(lines.where((l) => l.startsWith('description:')), isEmpty);
      expect(lines.where((l) => l.startsWith('vocals:')), hasLength(1));
      expect(lines.where((l) => l.startsWith('lyric_language:')), hasLength(1));
      expect(job['user_lyrics'], isNull);
      expect(job['images'], isEmpty);

      await _waitFor(tester, _playing, timeout: const Duration(seconds: 90));
      final firstListen = DateTime.now().difference(opened);
      expect(
        firstListen,
        lessThan(const Duration(seconds: 90)),
        reason: 'PRD §13.2: open → first listen < 90 s',
      );

      // Scrolling the preview while it plays: frame timings for the report —
      // when the engine reports them here; a headless simulator may not, and
      // `watchPerformance` would then wait for them forever.
      Future<void> scrollPreview() async {
        final list = find.byType(Scrollable).first;
        for (var i = 0; i < 3; i++) {
          await tester.fling(list, const Offset(0, -400), 1500);
          await _settle(tester);
          await tester.fling(list, const Offset(0, 400), 1500);
          await _settle(tester);
        }
      }

      if (await _reportsFrameTimings(tester)) {
        await binding.watchPerformance(
          scrollPreview,
          reportKey: 'preview_scroll',
        );
      } else {
        await scrollPreview();
        binding.reportData = {
          ...?binding.reportData,
          'preview_scroll': 'frame timings not reported on this simulator',
        };
      }
      // On a slow simulator the flings outlast the 30 s preview, and its end
      // opens the paywall by itself (PRD §8.2: after the first listen): close
      // it, the full song is asked for below.
      if (find.byType(PaywallPage).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const ValueKey('paywall.close')));
        await _settle(tester);
      }

      // Full song behind the paywall; the purchase lands on the server.
      if (_playing.evaluate().isNotEmpty) await tester.tap(_playing);
      await _tapRevealed(tester, find.byKey(const ValueKey('player.fullSong')));
      await _waitFor(tester, find.byType(PaywallPage));
      await admin.post('grant', {'product_id': 'com.songlet.pro.monthly'});
      await tester.tap(find.byKey(const ValueKey('paywall.close')));
      // The song page (P09); its action tiles sit below the fold, so wait on
      // the section track near the top.
      await _waitFor(
        tester,
        find.byKey(const ValueKey('player.sections')),
        timeout: const Duration(seconds: 90),
      );
      final account = await admin.account();
      expect(account['tier'], 'pro');
      expect(account['songs_left'], 39);

      // The share card of the full song.
      await _tapRevealed(tester, find.byKey(const ValueKey('player.share')));
      await _waitFor(tester, find.byKey(const ValueKey('share.card')));
      // Its send button sits under the card, below the fold on a small phone.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('share.send')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const ValueKey('share.send')), findsOneWidget);

      // A music video of the song (PRD ch.15): the free lyric video, end to end
      // — the entry card (P19) → the hub prices all three levels (saves the
      // song) → staged run with real progress (P24) → the video (P26).
      // Back to the song (a message banner may sit over the header button).
      GoRouter.of(
        tester.element(find.byKey(const ValueKey('share.card'))),
      ).pop();
      // The song page as it was left, scrolled to its actions.
      await _waitFor(tester, find.byKey(const ValueKey('player.share')));
      await _tapRevealed(tester, find.byKey(const ValueKey('mv.entry.open')));
      await _waitFor(
        tester,
        find.byKey(const ValueKey('mv.level.lyric_video')),
      );
      await tester.tap(find.byKey(const ValueKey('mv.level.lyric_video')));
      await _waitFor(tester, _createReady);
      await _tapRevealed(tester, find.byKey(const ValueKey('mv.create')));
      await _waitFor(tester, find.byKey(const ValueKey('mv.progressTitle')));
      await _waitFor(
        tester,
        find.byKey(const ValueKey('mv.player')),
        timeout: const Duration(seconds: 90),
      );
      expect(find.byKey(const ValueKey('mv.aiLabel')), findsOneWidget);
      expect(
        (await admin.account())['credits'],
        66,
        reason: 'a lyric video costs nothing',
      );

      // A chorus video (P20 → P22 → P24 → P26): refused for credits, the sheet
      // offers the pack; the purchase is applied server-side (a headless
      // simulator cannot complete the StoreKit sheet), and Continue sends the
      // same request again — charged once.
      await _tapRevealed(tester, find.byKey(const ValueKey('mv.regenerate')));
      await _waitFor(tester, find.byKey(const ValueKey('mv.level.chorus_mv')));
      await tester.tap(find.byKey(const ValueKey('mv.level.chorus_mv')));
      await _waitFor(tester, _createReady);
      await _tapRevealed(tester, find.byKey(const ValueKey('mv.create')));
      // The sheet; its buy button shows only where StoreKit resolves the pack (a
      // bare simulator resolves none), and the purchase is applied server-side.
      await _waitFor(tester, find.byKey(const ValueKey('mv.quota')));
      await tester.tap(find.byKey(const ValueKey('mv.quota.close')));
      await _settle(tester);
      await admin.post('grant', {'product_id': 'com.songlet.mv.chorus'});
      // The waiting video's banner heads the hub.
      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(0, 2000),
        4000,
      );
      await _settle(tester);
      await _waitFor(tester, find.byKey(const ValueKey('mv.intent')));
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('mv.intent')),
          matching: find.byType(TextButton),
        ),
      );
      await _waitFor(tester, find.byKey(const ValueKey('mv.progressTitle')));
      await _waitFor(
        tester,
        find.byKey(const ValueKey('mv.player')),
        timeout: const Duration(seconds: 90),
      );
      expect(
        (await admin.account())['credits'],
        66 + 2395 - 2169,
        reason: 'the chorus video is charged once',
      );

      // Share the video (the system share sheet opens over the player).
      await _tapRevealed(tester, find.byKey(const ValueKey('mv.share')));

      binding.reportData = {
        ...?binding.reportData,
        'build': kProfileMode
            ? 'profile'
            : (kReleaseMode ? 'release' : 'debug'),
        'create_home_interactive_ms': interactive.inMilliseconds,
        'open_to_first_listen_ms': firstListen.inMilliseconds,
      };
      // `flutter test` does not surface reportData; `flutter drive` does.
      debugPrint('SONGLET_REPORT ${jsonEncode(binding.reportData)}');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

/// The hub's primary action, enabled once the level is priced.
final Finder _createReady = find.descendant(
  of: find.byKey(const ValueKey('mv.create')),
  matching: find.byWidgetPredicate(
    (w) => w is ObsButton && w.onPressed != null,
  ),
);

/// The play / pause disc showing "pause": the song is playing.
final Finder _playing = find.descendant(
  of: find.byKey(const ValueKey('player.toggle')),
  matching: find.byIcon(Icons.pause_rounded),
);

/// Pumps real-time frames until [finder] matches (the app animates forever,
/// so there is no settle).
Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(deadline)) {
      final shown = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data)
          .whereType<String>()
          .join(' | ');
      fail(
        'timed out after ${timeout.inSeconds} s waiting for $finder; on screen: $shown',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
  await tester.pump();
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pump();
  }
}

Future<void> _tapRevealed(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await _settle(tester);
  await tester.tap(finder);
  await _settle(tester);
}

/// Whether the engine reports frame timings here: it batches them about once
/// a second while frames are drawn; a headless simulator may report none.
Future<bool> _reportsFrameTimings(WidgetTester tester) async {
  var reported = false;
  void onTimings(List<FrameTiming> _) => reported = true;
  SchedulerBinding.instance.addTimingsCallback(onTimings);
  final until = DateTime.now().add(const Duration(seconds: 5));
  while (!reported && DateTime.now().isBefore(until)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  SchedulerBinding.instance.removeTimingsCallback(onTimings);
  return reported;
}

/// The dev mock's `/__admin` API.
class _MockAdmin {
  _MockAdmin(this.base);

  final Uri base;
  final _client = HttpClient();

  Future<Map<String, dynamic>> post(
    String path, [
    Map<String, Object?> body = const {},
  ]) => _call('POST', path, body);

  /// The last job the mock accepted, as it stored the request; null before
  /// the first.
  Future<Map<String, dynamic>?> lastJob() async {
    final state = await _call('GET', 'state', null);
    final jobs = ((state['data'] as Map)['jobs'] as List)
        .cast<Map<String, dynamic>>();
    return jobs.isEmpty ? null : jobs.last;
  }

  /// The computed status of the account with a purchase (or the latest).
  Future<Map<String, dynamic>> account() async {
    final state = await _call('GET', 'state', null);
    final accounts = ((state['data'] as Map)['accounts'] as List)
        .cast<Map<String, dynamic>>();
    final paid = accounts.where((a) => (a['status'] as Map)['tier'] != 'free');
    return ((paid.isNotEmpty ? paid.last : accounts.last)['status'] as Map)
        .cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> _call(
    String method,
    String path,
    Map<String, Object?>? body,
  ) async {
    final request = await _client.openUrl(method, base.resolve(path));
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    return text.isEmpty ? const {} : jsonDecode(text) as Map<String, dynamic>;
  }
}
