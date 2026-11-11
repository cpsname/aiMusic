import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet/ui/paywall/music_paywall_page.dart';
import 'package:songlet/ui/player/music_preview_page.dart';
import 'package:songlet/ui/routing/music_routes.dart';
import 'package:songlet_kit/songlet_kit.dart';

import '../support/music_harness.dart';

void main() {
  setUp(mockNativeChannels);

  Future<MusicRecordingGeneration> open(
    WidgetTester tester,
    MusicGenerationState state, {
    MusicTestEnv? env,
  }) async {
    final generation = MusicRecordingGeneration(state);
    final environment = env ?? MusicTestEnv();
    environment.addWork(sampleClip());
    await pumpRoute(
      tester,
      '/create/generate',
      env: environment,
      overrides: [generationControllerProvider.overrideWith(() => generation)],
    );
    return generation;
  }

  testWidgets('P05 running: title, progress, meta, glimpse, cancel', (
    tester,
  ) async {
    await open(tester, waitingGeneration());
    expect(find.text('Writing Alex’s song…'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('Usually about 45 seconds'), findsOneWidget);
    expect(find.text("Here's to you, Alex"), findsOneWidget);
    expect(find.byKey(const ValueKey('generating.queue')), findsNothing);
    expect(find.byKey(const ValueKey('generating.cancel')), findsOneWidget);
  });

  testWidgets(
    'P06 queued: the banner from the status alone, with the wait and no position',
    (tester) async {
      // The platform never reports a queue position (contract v2 §3).
      await open(tester, waitingGeneration(queued: true));
      expect(find.byKey(const ValueKey('generating.queue')), findsOneWidget);
      expect(find.text('≈ 2 min'), findsOneWidget);
      expect(find.text('Position'), findsNothing);
    },
  );

  testWidgets('preparing: the local step is shown, no cancel yet', (
    tester,
  ) async {
    await open(
      tester,
      const MusicGenerationPreparing(MusicSongModel.clip, MusicPreparingStep.uploadingPhotos),
    );
    expect(find.byKey(const ValueKey('generating.cancel')), findsNothing);
  });

  testWidgets('cancel asks first, then stops and returns home', (tester) async {
    final generation = await open(tester, waitingGeneration(queued: true));
    await tester.ensureVisible(find.byKey(const ValueKey('generating.cancel')));
    await tester.tap(find.byKey(const ValueKey('generating.cancel')));
    await settleFrames(tester);
    expect(find.text('Stop this song?'), findsOneWidget);
    expect(find.textContaining('won’t count'), findsOneWidget);
    await tester.tap(find.text('Stop song'));
    await settleFrames(tester);
    expect(generation.cancels, 1);
    expect(currentLocation(tester), '/create');
    expect(find.text('Song stopped — nothing was used'), findsOneWidget);
  });

  testWidgets(
    'a cancel that lost the race to completion is a note, not an error',
    (tester) async {
      final generation = await open(tester, waitingGeneration());
      generation.finishedBeforeCancel = true;
      await tester.ensureVisible(
        find.byKey(const ValueKey('generating.cancel')),
      );
      await tester.tap(find.byKey(const ValueKey('generating.cancel')));
      await settleFrames(tester);
      await tester.tap(find.text('Stop song'));
      await settleFrames(tester);
      expect(generation.cancels, 1);
      expect(
        find.text("It already finished — there's nothing to cancel."),
        findsOneWidget,
      );
      expect(
        currentLocation(tester),
        '/create/generate',
        reason: 'the song is on its way; polling opens it',
      );
    },
  );

  testWidgets('success opens the preview player', (tester) async {
    final generation = await open(tester, waitingGeneration());
    generation.current = MusicGenerationSucceeded(sampleClip());
    await settleFrames(tester);
    expect(find.byType(MusicPreviewPage), findsOneWidget);
    expect(currentLocation(tester), '/library/works/clip-1/preview');
  });

  testWidgets('after the song opens, the Create tab is back on its home', (
    tester,
  ) async {
    final generation = await open(tester, waitingGeneration());
    generation.current = MusicGenerationSucceeded(sampleClip());
    await settleFrames(tester);
    await tester.tap(find.byKey(const ValueKey('nav.create')));
    await settleFrames(tester);
    expect(currentLocation(tester), const MusicCreateRoute().location);
  });

  testWidgets('QUOTA_EXHAUSTED opens the paywall once', (tester) async {
    final generation = await open(tester, waitingGeneration());
    generation.current = MusicGenerationFailed(
      const ErrorHandler().handle(MusicErrorCode.quotaExhausted.toApiError()),
    );
    await settleFrames(tester);
    expect(find.byType(MusicPaywallPage), findsOneWidget);
  });

  group(
    'a purchase that lands outside the paywall (ADR-0031: the ledger is server-side)',
    () {
      Future<(MusicRecordingGeneration, MusicTestEnv)> refused(
        WidgetTester tester,
      ) async {
        final env = MusicTestEnv();
        final generation = await open(tester, waitingGeneration(), env: env);
        generation.current = MusicGenerationFailed(
          const ErrorHandler().handle(
            MusicErrorCode.quotaExhausted.toApiError(),
          ),
          model: MusicSongModel.fullSong,
          draft: draftFromWork(sampleClip()),
        );
        await settleFrames(tester);
        expect(find.byType(MusicPaywallPage), findsOneWidget);
        return (generation, env);
      }

      testWidgets(
        'closed after the ledger gained the song: the song is made all the same',
        (tester) async {
          final (generation, env) = await refused(tester);
          // Granted by the server (approved later, a renewal, the acceptance run).
          env.entitlement = const MusicEntitlement(
            tier: MusicTier.pro,
            songsLeft: 40,
            clipsLeft: 100,
          );
          await tester.tap(find.byKey(const ValueKey('paywall.close')));
          await settleFrames(tester);
          expect(generation.generated.single.$2, MusicSongModel.fullSong);
        },
      );

      testWidgets(
        'the real run: refused, granted outside the sheet, retried — its progress shows cleanly',
        (tester) async {
          final env = MusicTestEnv()..addWork(sampleClip());
          env.jobs.submitError = MusicErrorCode.quotaExhausted.toApiError();
          final container = await pumpRoute(
            tester,
            '/library/works/clip-1/preview',
            env: env,
          );
          await settleFrames(tester);
          await reveal(tester, find.byKey(const ValueKey('player.fullSong')));
          await tester.tap(find.byKey(const ValueKey('player.fullSong')));
          await settleFrames(tester);
          await settleFrames(tester);
          expect(find.byType(MusicPaywallPage), findsOneWidget);
          env.entitlement = const MusicEntitlement(
            tier: MusicTier.pro,
            songsLeft: 40,
            clipsLeft: 100,
          );
          await tester.tap(find.byKey(const ValueKey('paywall.close')));
          await settleFrames(tester);
          await settleFrames(tester);
          expect(tester.takeException(), isNull);
          expect(
            env.jobs.submitted,
            hasLength(2),
            reason: 'refused once, then made',
          );
          expect(env.jobs.submitted.last.model, MusicSongModel.fullSong);
          expect(
            find.byKey(const ValueKey('generating.progress')),
            findsOneWidget,
          );
          await container.read(generationControllerProvider.notifier).cancel();
          await settleFrames(tester);
        },
      );

      testWidgets('closed with nothing gained: nothing is sent again', (
        tester,
      ) async {
        final (generation, _) = await refused(tester);
        await tester.tap(find.byKey(const ValueKey('paywall.close')));
        await settleFrames(tester);
        expect(generation.generated, isEmpty);
        expect(find.byType(MusicPaywallPage), findsNothing, reason: 'shown once');
      });
    },
  );

  testWidgets(
    'QUOTA_EXHAUSTED offer=packs: the credit packs lead, the recommended pack preselected',
    (tester) async {
      final generation = await open(tester, waitingGeneration());
      generation.current = MusicGenerationFailed(
        const ErrorHandler().handle(
          MusicErrorCode.quotaExhausted.toApiError(
            details: const {
              'offer': 'packs',
              'recommended_product_id': MusicCatalog.pack50,
              'reason': 'insufficient',
              'required_credits': '120',
              'available_credits': '20',
            },
          ),
        ),
      );
      await settleFrames(tester);
      expect(find.byType(MusicPaywallPage), findsOneWidget);
      expect(
        find.byKey(const ValueKey('paywall.product.${MusicCatalog.proWeekly}')),
        findsNothing,
      );
      expect(find.text('Buy pack'), findsOneWidget);
      expect(find.byKey(const ValueKey('paywall.seePlans')), findsOneWidget);
    },
  );

  testWidgets(
    'QUOTA_EXHAUSTED offer=subscription: the plans lead with Weekly Pro preselected',
    (tester) async {
      final generation = await open(tester, waitingGeneration());
      generation.current = MusicGenerationFailed(
        const ErrorHandler().handle(
          MusicErrorCode.quotaExhausted.toApiError(
            details: const {'offer': 'subscription'},
          ),
        ),
      );
      await settleFrames(tester);
      expect(
        find.byKey(const ValueKey('paywall.product.${MusicCatalog.proWeekly}')),
        findsOneWidget,
      );
      expect(find.text('Subscribe'), findsOneWidget);
    },
  );

  testWidgets('a retryable failure shows the §6.5 copy and retry', (
    tester,
  ) async {
    await open(
      tester,
      MusicGenerationFailed(
        const ErrorHandler().handle(
          MusicErrorCode.upstreamTimeout.toApiError(),
        ),
        model: MusicSongModel.clip,
        draft: MusicCreationDraft(
          occasion: MusicOccasion.custom,
          region: RegionPresets.all.first,
          genre: null,
          lyricLanguage: MusicLyricLanguage.en,
          prompt: 'sea',
        ),
      ),
    );
    expect(find.textContaining('Taking longer than usual'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  MusicCreationDraft seaDraft() => MusicCreationDraft(
    occasion: MusicOccasion.custom,
    region: RegionPresets.all.first,
    genre: null,
    lyricLanguage: MusicLyricLanguage.en,
    prompt: 'sea',
  );

  testWidgets(
    'every failure has a way back: "Back to edit" returns to the create home',
    (tester) async {
      await open(
        tester,
        MusicGenerationFailed(
          const ErrorHandler().handle(
            MusicErrorCode.upstreamTimeout.toApiError(),
          ),
          model: MusicSongModel.clip,
          draft: seaDraft(),
        ),
      );
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('generating.back')));
      await settleFrames(tester);
      expect(currentLocation(tester), const MusicCreateRoute().location);
    },
  );

  testWidgets(
    'a server 40001 on the prompt says what to add, offers no retry, and goes back to edit',
    (tester) async {
      await open(
        tester,
        MusicGenerationFailed(
          const ErrorHandler().handle(
            const ValidationApiError(
              code: 40001,
              message: 'validation failed',
              details: {
                'prompt':
                    'a recipient with keywords, a description, lyrics or photos is required',
              },
            ),
          ),
          model: MusicSongModel.clip,
          draft: seaDraft(),
        ),
      );
      expect(
        find.text('Tell us about the song — a few words, lyrics or photos.'),
        findsOneWidget,
      );
      expect(find.text('Something went wrong'), findsNothing);
      expect(find.text('Retry'), findsNothing);
      await tester.tap(find.text('Back to edit'));
      await settleFrames(tester);
      expect(currentLocation(tester), const MusicCreateRoute().location);
    },
  );

  testWidgets('a scene that needs words (40001 prompt.description) says so', (
    tester,
  ) async {
    await open(
      tester,
      MusicGenerationFailed(
        const ErrorHandler().handle(
          const ValidationApiError(
            code: 40001,
            message: 'validation failed',
            details: {
              'prompt.description': 'this inspiration needs your words',
            },
          ),
        ),
        draft: seaDraft(),
      ),
    );
    expect(
      find.text('This idea needs your words — write a line about the song.'),
      findsOneWidget,
    );
  });

  testWidgets('a draft refused by preflight shows why and goes back to edit', (
    tester,
  ) async {
    await open(tester, const MusicGenerationRejected([MusicPreflightIssue.briefMissing]));
    expect(
      find.text('Tell us about the song — a few words, lyrics or photos.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Back to edit'));
    await settleFrames(tester);
    expect(currentLocation(tester), const MusicCreateRoute().location);
  });

  testWidgets(
    'a server REGION_UNAVAILABLE reads as a temporary delay (ADR-0005)',
    (tester) async {
      await open(
        tester,
        MusicGenerationFailed(
          const ErrorHandler().handle(
            MusicErrorCode.regionUnavailable.toApiError(),
          ),
        ),
      );
      expect(find.textContaining('Taking longer than usual'), findsOneWidget);
      expect(find.textContaining('region'), findsNothing);
    },
  );

  testWidgets('with nothing running the route falls back to the create home', (
    tester,
  ) async {
    await open(tester, const MusicGenerationIdle());
    expect(currentLocation(tester), const MusicCreateRoute().location);
    expect(find.text('Nothing is being made right now.'), findsNothing);
  });
}
