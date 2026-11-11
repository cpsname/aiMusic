import 'dart:async';

import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:songlet/ui/common/unavailable_page.dart';
import 'package:songlet/ui/create/create_home_page.dart';
import 'package:songlet/ui/create/region_sheet.dart';
import 'package:songlet/ui/paywall/paywall_page.dart';
import 'package:songlet/ui/routing/routes.dart';
import 'package:songlet/ui/settings/about_page.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../support/music_harness.dart';

void main() {
  setUp(mockNativeChannels);

  group('P02 region', () {
    testWidgets(
      'picking a country moves genres and lyric language (culture only)',
      (tester) async {
        final container = await pumpRoute(tester, '/create/region');
        await tester.enterText(
          find.descendant(
            of: find.byType(RegionSheet),
            matching: find.byType(TextField),
          ),
          'Japan',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('region.JP')));
        await tester.pump();
        final draft = container.read(creationDraftProvider).draft!;
        expect(draft.region.code, 'JP');
        expect(draft.lyricLanguage, LyricLanguage.ja);
        expect(find.text('Lyrics language: Japanese'), findsOneWidget);
      },
    );

    testWidgets('search narrows the list and reports no match', (tester) async {
      await pumpRoute(tester, '/create/region');
      final search = find.descendant(
        of: find.byType(RegionSheet),
        matching: find.byType(TextField),
      );
      await tester.enterText(search, 'bra');
      await tester.pump();
      expect(find.byKey(const ValueKey('region.BR')), findsOneWidget);
      expect(find.byKey(const ValueKey('region.US')), findsNothing);
      await tester.enterText(search, 'atlantis');
      await tester.pump();
      expect(find.text('No countries match'), findsOneWidget);
    });
  });

  group('P04 photos', () {
    testWidgets('opens the picker, shows the count, removes, creates', (
      tester,
    ) async {
      final generation = RecordingGeneration();
      final container = await pumpRoute(
        tester,
        '/create/photos',
        overrides: [
          generationControllerProvider.overrideWith(() => generation),
        ],
      );
      expect(find.text('2 / 10'), findsOneWidget);
      await tester.tap(find.byTooltip('Remove photo').first);
      await tester.pump();
      expect(container.read(creationDraftProvider).draft!.photos, hasLength(1));
      await tester.tap(find.byKey(const ValueKey('photos.create')));
      await settleFrames(tester);
      expect(generation.generated.single.$1.usesPhotos, isTrue);
    });
  });

  group('P08 paywall', () {
    testWidgets('Premier lists WAV only once the WAV switch is on', (
      tester,
    ) async {
      await pumpRoute(tester, '/paywall?reason=full_song');
      await reveal(
        tester,
        find.byKey(
          const ValueKey('paywall.product.${MusicCatalog.premierMonthly}'),
        ),
      );
      expect(find.text('MP3 + WAV download'), findsNothing);
      await settleFrames(tester);
    });

    testWidgets('with the WAV switch on, Premier lists MP3 + WAV', (
      tester,
    ) async {
      final env = SongletTestEnv()..remoteConfig = const {'wav_export': true};
      await pumpRoute(tester, '/paywall?reason=full_song', env: env);
      await reveal(tester, find.text('MP3 + WAV download'));
      expect(find.text('MP3 + WAV download'), findsOneWidget);
      await settleFrames(tester);
    });

    Finder product(String id) => find.byKey(ValueKey('paywall.product.$id'));

    testWidgets(
      'Weekly Pro leads and is preselected: price per week, the App Store\'s first-week discount, no free or unlimited wording',
      (tester) async {
        await pumpRoute(tester, '/paywall?reason=quota');
        expect(find.byType(PaywallPage), findsOneWidget);
        expect(
          find.text(r'$4.99/week'),
          findsOneWidget,
          reason: 'the period comes from the store, not "/mo"',
        );
        expect(
          find.text('50% off your first week'),
          findsOneWidget,
          reason: 'read from the introductory offer',
        );
        expect(
          find.text('Fresh credits every week'),
          findsOneWidget,
          reason: 'credits, not a song count — and never "unlimited"',
        );
        expect(
          find.text('Subscribe'),
          findsOneWidget,
          reason: 'the CTA of the preselected Weekly Pro, not a free trial',
        );
        expect(
          find.textContaining('After the introductory price of'),
          findsOneWidget,
        );
        expect(find.textContaining(r'$2.49'), findsOneWidget);
        expect(find.textContaining('nlimited'), findsNothing);
        expect(find.textContaining('free preview'), findsNothing);
        await reveal(tester, product(MusicCatalog.proYearly));
        expect(
          find.text('7-day free trial'),
          findsOneWidget,
          reason: 'Pro Yearly keeps its trial',
        );
        await settleFrames(tester);
      },
    );

    testWidgets('a pack changes the CTA and drops the renewal terms', (
      tester,
    ) async {
      await pumpRoute(tester, '/paywall?reason=full_song');
      await reveal(tester, product(MusicCatalog.pack10));
      await tester.tap(product(MusicCatalog.pack10));
      await tester.pump();
      expect(find.text('Buy pack'), findsOneWidget);
      expect(find.textContaining('renew automatically'), findsNothing);
      expect(find.textContaining('introductory price'), findsNothing);
      await settleFrames(tester);
    });

    testWidgets(
      'offer=packs: the credit packs lead with the recommended one preselected; subscriptions wait behind a link',
      (tester) async {
        await pumpRoute(
          tester,
          '/paywall?reason=quota&offer=packs&product=${MusicCatalog.pack50}',
        );
        expect(product(MusicCatalog.pack10), findsOneWidget);
        expect(product(MusicCatalog.pack50), findsOneWidget);
        expect(product(MusicCatalog.proWeekly), findsNothing);
        expect(
          find.text('Buy pack'),
          findsOneWidget,
          reason: 'a pack is preselected',
        );
        await reveal(tester, find.byKey(const ValueKey('paywall.seePlans')));
        await tester.tap(find.text('See subscriptions'));
        await settleFrames(tester);
        expect(product(MusicCatalog.proWeekly), findsOneWidget);
        expect(find.byKey(const ValueKey('paywall.seePlans')), findsNothing);
        expect(
          find.text('Subscribe'),
          findsOneWidget,
          reason: 'Weekly Pro takes over the selection',
        );
      },
    );

    testWidgets(
      'offer=subscription leads with the plans even when a pack was recommended',
      (tester) async {
        await pumpRoute(
          tester,
          '/paywall?reason=quota&offer=subscription&product=${MusicCatalog.pack50}',
        );
        expect(product(MusicCatalog.proWeekly), findsOneWidget);
        expect(find.text('Subscribe'), findsOneWidget);
        expect(find.byKey(const ValueKey('paywall.seePlans')), findsNothing);
        await reveal(tester, product(MusicCatalog.pack10));
        expect(
          product(MusicCatalog.pack10),
          findsOneWidget,
          reason: 'the packs are listed below the plans',
        );
        await settleFrames(tester);
      },
    );

    testWidgets(
      'no offer (only an error code): the plans, with the packs listed too',
      (tester) async {
        await pumpRoute(tester, '/paywall?reason=quota');
        expect(product(MusicCatalog.proWeekly), findsOneWidget);
        await reveal(tester, product(MusicCatalog.pack50));
        expect(product(MusicCatalog.pack50), findsOneWidget);
        await settleFrames(tester);
      },
    );

    testWidgets('Not now closes back to where it came from', (tester) async {
      await pumpRoute(tester, '/create');
      // Opened over the create home (Settings' Upgrade does the same push).
      unawaited(
        GoRouter.of(
          tester.element(find.byType(CreateHomePage)),
        ).push<bool>(const PaywallRoute().location),
      );
      await settleFrames(tester);
      await tester.tap(find.text('Not now'));
      await settleFrames(tester);
      expect(find.byType(CreateHomePage), findsOneWidget);
    });
  });

  group('P10 share', () {
    testWidgets('theme and layout change the card; lyrics copy', (
      tester,
    ) async {
      final env = SongletTestEnv()
        ..addWork(sampleClip(id: 'song-1', model: SongModel.fullSong));
      await pumpRoute(tester, '/library/works/song-1/share', env: env);
      await tester.tap(find.byKey(const ValueKey('share.theme.navy')));
      await tester.tap(find.byKey(const ValueKey('share.layout.text')));
      await tester.pump();
      final card = tester.widget<ShareCardCanvas>(find.byType(ShareCardCanvas));
      expect(card.palette, ArtPalette.navy);
      expect(card.layout, ShareCardLayout.text);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData')
            copied = (call.arguments as Map)['text'] as String;
          return null;
        },
      );
      await reveal(tester, find.text('Copy lyrics'));
      await tester.tap(find.text('Copy lyrics'));
      await settleFrames(tester);
      expect(copied, contains('Happy birthday, Alex'));
      expect(copied, contains('AI generated'));
    });
  });

  group('P11 download', () {
    testWidgets('no WAV row while the WAV switch is off (production default)', (
      tester,
    ) async {
      final env = SongletTestEnv()
        ..addWork(sampleClip(id: 'song-1', model: SongModel.fullSong))
        ..entitlement = const MusicEntitlement(
          tier: MusicTier.premier,
          songsLeft: 119,
          clipsLeft: 199,
        );
      await pumpRoute(
        tester,
        '/library/works/song-1/download',
        env: env,
        overrides: [
          exportServiceProvider.overrideWithValue(FakeExportService()),
        ],
      );
      await reveal(tester, find.byKey(const ValueKey('download.mp3')));
      expect(find.byKey(const ValueKey('download.wav')), findsNothing);
    });

    testWidgets(
      'Premier, switch on, a song without a WAV render: a note, never the paywall',
      (tester) async {
        final env = SongletTestEnv()
          ..addWork(sampleClip(id: 'song-1', model: SongModel.fullSong))
          ..entitlement = const MusicEntitlement(
            tier: MusicTier.premier,
            songsLeft: 119,
            clipsLeft: 199,
          )
          ..remoteConfig = const {'wav_export': true};
        await pumpRoute(
          tester,
          '/library/works/song-1/download',
          env: env,
          overrides: [
            exportServiceProvider.overrideWithValue(
              FakeExportService(wavRendered: false),
            ),
          ],
        );
        await tester.tap(find.bySemanticsLabel('Download WAV'));
        await settleFrames(tester);
        expect(
          find.textContaining("There's no WAV file for this song."),
          findsOneWidget,
        );
        expect(find.byType(PaywallPage), findsNothing);
      },
    );

    testWidgets('license details, MP3 save, WAV locked for non-Premier', (
      tester,
    ) async {
      final export = FakeExportService();
      final env = SongletTestEnv()
        ..addWork(sampleClip(id: 'song-1', model: SongModel.fullSong))
        ..entitlement = const MusicEntitlement(
          tier: MusicTier.pro,
          songsLeft: 39,
          clipsLeft: 99,
        )
        ..remoteConfig = const {'wav_export': true};
      await pumpRoute(
        tester,
        '/library/works/song-1/download',
        env: env,
        overrides: [exportServiceProvider.overrideWithValue(export)],
      );
      await tester.tap(find.bySemanticsLabel('Download MP3'));
      await settleFrames(tester);
      expect(export.saved, [ExportFile.mp3]);
      await reveal(tester, find.text('License ID: SL-20260924-7F3A9C'));
      expect(find.text('Personal use'), findsOneWidget);
      final wav = tester.widget<DownloadRow>(
        find.descendant(
          of: find.byKey(const ValueKey('download.wav')),
          matching: find.byType(DownloadRow),
        ),
      );
      expect(wav.locked, isTrue);
    });

    testWidgets('a refunded or free work shows the locked state (§8.4)', (
      tester,
    ) async {
      final env = SongletTestEnv()
        ..addWork(sampleClip(id: 'song-1', model: SongModel.fullSong));
      await pumpRoute(
        tester,
        '/library/works/song-1/download',
        env: env,
        overrides: [
          exportServiceProvider.overrideWithValue(
            FakeExportService(locked: true),
          ),
        ],
      );
      expect(find.byKey(const ValueKey('download.locked')), findsOneWidget);
    });
  });

  group('P14 / P15 settings', () {
    testWidgets('default lyrics language, about', (tester) async {
      final container = await pumpRoute(tester, '/settings');
      await reveal(tester, find.byKey(const ValueKey('settings.language')));
      await tester.tap(find.byKey(const ValueKey('settings.language')));
      await settleFrames(tester);
      await tester.tap(find.text('Japanese'));
      await settleFrames(tester);
      expect(container.read(lyricLanguagePreferenceProvider), LyricLanguage.ja);
      await reveal(tester, find.byKey(const ValueKey('settings.about')));
      await tester.tap(find.byKey(const ValueKey('settings.about')));
      await settleFrames(tester);
      expect(find.byType(AboutPage), findsOneWidget);
      await reveal(tester, find.byType(HighlightBanner));
      expect(
        find.text('Every song you share is labeled AI generated.'),
        findsOneWidget,
      );
    });
  });

  group('P14 profile', () {
    const accountId = '6b29fc40-ca47-1067-b31d-00dd010662da';

    testWidgets(
      'credits and the full account ID; the copy button puts it on the clipboard',
      (tester) async {
        final copied = <String>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData')
              copied.add((call.arguments as Map)['text'] as String);
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        final env = SongletTestEnv()
          ..entitlement = const MusicEntitlement(
            tier: MusicTier.pro,
            songsLeft: 9,
            clipsLeft: 21,
            creditsAvailable: 1850,
          );
        await pumpRoute(
          tester,
          '/settings',
          env: env,
          overrides: [appAccountTokenProvider.overrideWithValue(accountId)],
        );
        expect(find.text('Profile'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('settings.credits')),
            matching: find.text('1,850'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('settings.accountId')),
            matching: find.text(accountId),
          ),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('settings.copyAccountId')));
        await settleFrames(tester);
        expect(copied, [accountId]);
        expect(find.text('Copied'), findsOneWidget);
      },
    );

    testWidgets(
      'before the session and the balance are known: dashes, no copy button',
      (tester) async {
        await pumpRoute(
          tester,
          '/settings',
          overrides: [appAccountTokenProvider.overrideWithValue(null)],
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('settings.accountId')),
            matching: find.text('—'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('settings.copyAccountId')),
          findsNothing,
        );
      },
    );
  });

  group('P16 festival', () {
    testWidgets(
      'an occasion card picks its tile on the create home with the festival set',
      (tester) async {
        final container = await pumpRoute(tester, '/create/festival/diwali');
        expect(find.text('Diwali'), findsWidgets);
        await reveal(
          tester,
          find.byKey(const ValueKey('festival.occasion.wedding')),
        );
        await tester.tap(
          find.byKey(const ValueKey('festival.occasion.wedding')),
        );
        await settleFrames(tester);
        expect(find.byType(CreateHomePage), findsOneWidget);
        expect(currentLocation(tester), '/create');
        expect(find.byKey(const ValueKey('composer.fields')), findsOneWidget);
        final draft = container.read(creationDraftProvider).draft!;
        expect(draft.template, SongTemplate.wedding);
        expect(draft.festival, Festival.diwali);
      },
    );
  });

  group('P17 unavailable', () {
    testWidgets('retry returns to create; the library stays reachable', (
      tester,
    ) async {
      await pumpRoute(tester, '/unavailable');
      expect(find.byType(UnavailablePage), findsOneWidget);
      await tester.tap(find.text('Library'));
      await settleFrames(tester);
      expect(currentLocation(tester), '/library');
    });
  });

  group('deep links', () {
    testWidgets('an unknown link opens the create home', (tester) async {
      await pumpRoute(tester, '/definitely/not/a/page');
      expect(find.byType(CreateHomePage), findsOneWidget);
    });

    testWidgets('each tab keeps its own stack', (tester) async {
      final env = SongletTestEnv()..addWork(sampleClip());
      await pumpRoute(tester, '/library/works/clip-1', env: env);
      await tester.tap(find.text('Create'));
      await settleFrames(tester);
      await tester.tap(find.text('Library'));
      await settleFrames(tester);
      expect(currentLocation(tester), '/library/works/clip-1');
    });
  });
}
