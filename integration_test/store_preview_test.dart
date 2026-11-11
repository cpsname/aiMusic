import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:songlet/l10n/generated/app_localizations.dart';
import 'package:songlet/main.dart' as app;
import 'package:songlet/ui/create/music_create_labels.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:store_preview_driver/store_preview_driver.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:video_player/video_player.dart';

/// App Store preview recordings (store_preview/songlet, packages/store_preview):
/// `store-preview render --app songlet` hands this test its plan; the built-in
/// steps (tap, type, pickPhotos, …) come from store_preview_driver, Songlet's
/// own steps and playback readers are registered here.
void main() => storePreviewTest(appMain: app.main, registry: songletSteps());

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first));

GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Navigator).first));

/// A prompt's `lyric_language` (`ja`, `pt`, `zh`, `pt-BR` …) as the app's
/// language: exact code first, else the first with that base code.
MusicLyricLanguage _lyricLanguage(String code) {
  final lower = code.toLowerCase();
  return MusicLyricLanguage.values
          .where((l) => l.code.toLowerCase() == lower)
          .firstOrNull ??
      MusicLyricLanguage.values.firstWhere(
        (l) => l.baseCode.toLowerCase() == lower.split('-').first,
        orElse: () => fail('no lyric language $code'),
      );
}

StepRegistry songletSteps() => StepRegistry()
  // Off camera: a clean composer, as after a fresh start (the previous
  // script's pick and words are not carried over).
  ..step('newDraft', (c, step) async {
    _container(c.tester).read(creationDraftProvider.notifier).clear();
    _router(c.tester).go('/library');
    await c.hold(const Duration(milliseconds: 500));
    _router(c.tester).go('/create');
    await c.hold(const Duration(milliseconds: 800));
  })
  ..step('go', (c, step) async {
    final location = step['location'] as String;
    _router(c.tester).go(
      location.startsWith('@')
          ? (c.remembered[location.substring(1)] ??
                fail('nothing remembered as $location'))
          : location,
    );
    await c.hold(const Duration(milliseconds: 400));
  })
  // The current location (e.g. a song page) for a later `go: '@name'`.
  ..step('remember', (c, step) async {
    c.remembered[step['as'] as String] = _router(
      c.tester,
    ).routerDelegate.currentConfiguration.uri.toString();
  })
  // The picker's photos landed in the draft.
  ..step('waitPhotos', (c, step) async {
    final count = (step['count'] as num).toInt();
    await c.waitUntil(
      () =>
          (_container(
                c.tester,
              ).read(creationDraftProvider).draft?.photos.length ??
              0) >=
          count,
      timeout: 60,
      what: '$count photos from the picker',
    );
  })
  // In the open lyric-language sheet, the row of this language — by its name
  // in the UI language, as a user reads it.
  ..step('tapLyricLanguage', (c, step) async {
    final language = _lyricLanguage(step['language'] as String);
    final name = languageName(
      AppLocalizations.of(c.tester.element(find.byType(Navigator).first)),
      language,
    );
    final row = find.widgetWithText(OptionRow, name);
    await c.reveal(row, within: 'widget:OptionRow');
    await c.tester.tap(row.first);
    await c.hold(const Duration(milliseconds: 500));
  })
  // The song's lyrics are in this language: the draft (and so the player's
  // meta line) must say so too.
  ..step('checkLyricLanguage', (c, step) async {
    final want = _lyricLanguage(step['language'] as String);
    final have = _container(
      c.tester,
    ).read(creationDraftProvider).draft?.lyricLanguage;
    if (have != want)
      fail(
        'the draft writes lyrics in ${have?.code}, the song is in ${want.code}',
      );
  })
  // Attested, with the server's entitlement mirrored.
  ..step('waitOnline', (c, step) async {
    await c.waitUntil(
      () => _container(c.tester).read(musicEntitlementProvider).hasValue,
      timeout: 90,
      what: 'attestation',
    );
  })
  // A server-side grant (the headless simulator cannot finish a StoreKit
  // sheet) reaches the app the way a foreground refresh does.
  ..step('refreshEntitlement', (c, step) async {
    final tier = step['tier'] as String;
    _container(c.tester).invalidate(walletSnapshotProvider);
    await c.waitUntil(
      () =>
          _container(
            c.tester,
          ).read(musicEntitlementProvider).value?.tier.name ==
          tier,
      timeout: 30,
      what: 'the $tier entitlement',
    );
  })
  // Starts the page's song unless it already plays.
  ..step('play', (c, step) async {
    final controls = find.byKey(ValueKey(step['key'] as String));
    await c.waitFor(PlanFinder(controls, '${step['key']}'));
    final pause = find.descendant(
      of: controls,
      matching: find.byIcon(Icons.pause_rounded),
    );
    if (pause.evaluate().isEmpty) {
      await c.tester.tap(
        find
            .descendant(
              of: controls,
              matching: find.byIcon(Icons.play_arrow_rounded),
            )
            .first,
      );
    }
    await c.waitUntil(
      () => pause.evaluate().isNotEmpty,
      timeout: 30,
      what: 'the song playing',
    );
    await c.hold(const Duration(milliseconds: 300));
  })
  ..step('waitPlaying', (c, step) async {
    await c.waitUntil(
      () => _container(c.tester).read(playerControllerProvider).isPlaying,
      timeout: 60,
      what: 'the song playing',
    );
  })
  // Starts the lyric video with its play control unless it plays.
  ..step('playVideo', (c, step) async {
    bool playing() {
      final player = find.byType(VideoPlayer).evaluate();
      return player.isNotEmpty &&
          (player.first.widget as VideoPlayer).controller.value.isPlaying;
    }

    await c.waitFor(PlanFinder(find.byType(VideoPlayer), 'VideoPlayer'));
    await c.hold(const Duration(milliseconds: 500));
    if (!playing())
      await c.tap(
        PlanFinder.parse({'key': step['key'] ?? 'mv.toggle'}),
        reveal: false,
      );
    await c.waitUntil(playing, timeout: 30, what: 'the lyric video playing');
  })
  // The song's position from the native player's progress stream (sampled
  // until it ticks, then extrapolated back to the scene's start).
  ..position('song', (c, at) async {
    final first = _container(c.tester).read(playerControllerProvider);
    if (!first.isPlaying)
      fail('the song is not playing at a scene that follows it');
    final deadline = at.add(const Duration(seconds: 1));
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 8));
      final now = _container(c.tester).read(playerControllerProvider).position;
      if (now != first.position)
        return now - DateTime.now().difference(at).inMilliseconds / 1000;
    }
    fail('the song position did not move');
  })
  // The lyric video's position from its controller.
  ..position('video', (c, at) async {
    final player = find.byType(VideoPlayer);
    if (player.evaluate().isEmpty) fail('no lyric video on screen to follow');
    final controller =
        (player.evaluate().first.widget as VideoPlayer).controller;
    final now = await controller.position ?? Duration.zero;
    final lag = DateTime.now().difference(at);
    return (now - lag).inMilliseconds / 1000;
  });
