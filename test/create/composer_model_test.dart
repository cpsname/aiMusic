import 'package:flutter_test/flutter_test.dart';
import 'package:songlet/ui/create/music_composer_model.dart';
import 'package:songlet_kit/songlet_kit.dart';

/// The composer's states and the primary action's table (ADR-0033, ADR-0035).
void main() {
  final us = RegionPresets.byCode('US')!;

  MusicCreationDraft free({String prompt = '', MusicSongModel model = MusicSongModel.clip}) =>
      MusicCreationDraft(
        occasion: MusicOccasion.custom,
        region: us,
        genre: us.genres.first,
        lyricLanguage: MusicLyricLanguage.en,
        prompt: prompt,
        model: model,
      );

  MusicCreationDraft picked({
    String name = '',
    MusicSongModel model = MusicSongModel.clip,
    bool inputRequired = false,
  }) => free(model: model).copyWith(
    occasion: MusicOccasion.birthday,
    inspirationSlug: 'birthday_wish',
    pickInputRequired: inputRequired,
    recipient: name,
  );

  const freeTier = MusicEntitlement(
    tier: MusicTier.free,
    songsLeft: 0,
    clipsLeft: 3,
  );
  const proTier = MusicEntitlement(
    tier: MusicTier.pro,
    songsLeft: 40,
    clipsLeft: 100,
  );
  const empty = MusicEntitlement(
    tier: MusicTier.free,
    songsLeft: 0,
    clipsLeft: 0,
  );

  group('subject', () {
    test('free input without a pick, the card with one', () {
      expect(MusicComposerSubject.of(null), MusicComposerSubject.free);
      expect(MusicComposerSubject.of(free()), MusicComposerSubject.free);
      expect(MusicComposerSubject.of(picked()), MusicComposerSubject.picked);
    });
  });

  group('primary action label table', () {
    final rows = <(String, MusicCreationDraft, MusicEntitlement?, MusicCreateAction)>[
      (
        'Short · no name · free allowance',
        picked(),
        freeTier,
        const MusicCreateAction(
          kind: MusicCreateActionKind.preview,
          cost: MusicCreateCost.free,
          enabled: true,
        ),
      ),
      (
        'Short · Alex · free allowance',
        picked(name: ' Alex '),
        freeTier,
        const MusicCreateAction(
          kind: MusicCreateActionKind.previewFor,
          name: 'Alex',
          cost: MusicCreateCost.free,
          enabled: true,
        ),
      ),
      (
        'Short · plan allowance',
        picked(name: 'Alex'),
        proTier,
        const MusicCreateAction(
          kind: MusicCreateActionKind.previewFor,
          name: 'Alex',
          cost: MusicCreateCost.preview,
          enabled: true,
        ),
      ),
      (
        'Short · nothing left',
        picked(name: 'Alex'),
        empty,
        const MusicCreateAction(
          kind: MusicCreateActionKind.previewFor,
          name: 'Alex',
          cost: MusicCreateCost.none,
          enabled: true,
        ),
      ),
      (
        'Short · ledger unknown',
        picked(),
        null,
        const MusicCreateAction(
          kind: MusicCreateActionKind.preview,
          cost: MusicCreateCost.none,
          enabled: true,
        ),
      ),
      (
        'Standard · songs left (name not shown)',
        picked(name: 'Alex', model: MusicSongModel.fullSong),
        proTier,
        const MusicCreateAction(
          kind: MusicCreateActionKind.fullSong,
          cost: MusicCreateCost.song,
          enabled: true,
        ),
      ),
      (
        'Standard · nothing left',
        picked(model: MusicSongModel.fullSong),
        freeTier,
        const MusicCreateAction(
          kind: MusicCreateActionKind.fullSong,
          cost: MusicCreateCost.none,
          enabled: true,
        ),
      ),
      (
        'free input never names anyone',
        free(prompt: 'rain').copyWith(recipient: 'Alex'),
        freeTier,
        const MusicCreateAction(
          kind: MusicCreateActionKind.preview,
          cost: MusicCreateCost.free,
          enabled: true,
        ),
      ),
    ];
    for (final (name, draft, entitlement, expected) in rows) {
      test(
        name,
        () => expect(
          MusicCreateAction.of(draft: draft, entitlement: entitlement),
          expected,
        ),
      );
    }
  });

  group('enabled', () {
    test('free input needs words, photos or own lyrics', () {
      expect(
        MusicCreateAction.of(draft: free(), entitlement: freeTier).enabled,
        isFalse,
      );
      expect(
        MusicCreateAction.of(
          draft: free(prompt: '  '),
          entitlement: freeTier,
        ).enabled,
        isFalse,
      );
      expect(
        MusicCreateAction.of(
          draft: free(prompt: 'rain'),
          entitlement: freeTier,
        ).enabled,
        isTrue,
      );
      expect(
        MusicCreateAction.of(
          draft: free().copyWith(imageBids: ['b1']),
          entitlement: null,
        ).enabled,
        isTrue,
      );
      expect(
        MusicCreateAction.of(
          draft: free().copyWith(userLyrics: 'la la'),
          entitlement: null,
        ).enabled,
        isTrue,
      );
      expect(
        MusicCreateAction.of(
          draft: free().copyWith(
            userLyrics: 'la la',
            vocals: MusicVocals.instrumental,
          ),
          entitlement: null,
        ).enabled,
        isFalse,
        reason: 'an instrumental sends no lyrics',
      );
    });

    test(
      'a picked card is enough by itself; its folded fields do not make free input',
      () {
        expect(
          MusicCreateAction.of(draft: picked(), entitlement: empty).enabled,
          isTrue,
        );
        expect(
          MusicCreateAction.of(
            draft: free().copyWith(recipient: 'Alex', keywords: ['coffee']),
            entitlement: null,
          ).enabled,
          isFalse,
          reason: 'the name and three words are not sent without a pick',
        );
      },
    );

    test("a card that asks for the user's words waits for them", () {
      expect(
        MusicCreateAction.of(
          draft: picked(inputRequired: true),
          entitlement: null,
        ).enabled,
        isFalse,
      );
      expect(
        MusicCreateAction.of(
          draft: picked(inputRequired: true).copyWith(prompt: 'see you at 8'),
          entitlement: null,
        ).enabled,
        isTrue,
      );
    });

    test('nothing while a song is being made, or without a draft', () {
      expect(
        MusicCreateAction.of(
          draft: picked(),
          entitlement: proTier,
          busy: true,
        ).enabled,
        isFalse,
      );
      expect(
        MusicCreateAction.of(draft: null, entitlement: proTier).enabled,
        isFalse,
      );
    });
  });

  group('summary row', () {
    test('length · vocals · genre from the draft', () {
      expect(summaryParts(free(), optionsShown: false), [
        MusicSummaryPart.preview,
        MusicSummaryPart.vocalsOn,
        MusicSummaryPart.genre,
      ]);
      expect(
        summaryParts(
          free(
            model: MusicSongModel.fullSong,
          ).copyWith(vocals: MusicVocals.custom, customGenre: true),
          optionsShown: false,
        ),
        [MusicSummaryPart.fullSong, MusicSummaryPart.anyVocals, MusicSummaryPart.anyGenre],
      );
      expect(
        summaryParts(
          free(
            model: MusicSongModel.fullSong,
          ).copyWith(autoVideo: MusicAutoVideo.chorus, vocals: MusicVocals.instrumental),
          optionsShown: false,
        ),
        [
          MusicSummaryPart.songAndChorus,
          MusicSummaryPart.instrumental,
          MusicSummaryPart.genre,
        ],
      );
    });

    test('what will be sent from the folded options stays in sight', () {
      final withExtras = free(
        model: MusicSongModel.fullSong,
      ).copyWith(userLyrics: 'la', autoVideo: MusicAutoVideo.lyric);
      expect(summaryParts(withExtras, optionsShown: false), [
        MusicSummaryPart.fullSong,
        MusicSummaryPart.vocalsOn,
        MusicSummaryPart.genre,
        MusicSummaryPart.ownLyrics,
        MusicSummaryPart.video,
      ]);
      expect(
        summaryParts(withExtras, optionsShown: true),
        hasLength(3),
        reason: 'the options show them',
      );
      expect(
        summaryParts(
          withExtras.copyWith(model: MusicSongModel.clip),
          optionsShown: false,
        ),
        [
          MusicSummaryPart.preview,
          MusicSummaryPart.vocalsOn,
          MusicSummaryPart.genre,
          MusicSummaryPart.ownLyrics,
        ],
        reason: 'a preview makes no video',
      );
    });
  });
}
