import 'package:flutter_test/flutter_test.dart';
import 'package:songlet/ui/create/composer_model.dart';
import 'package:songlet_kit/songlet_kit.dart';

/// The composer's states and the primary action's table (ADR-0033, ADR-0035).
void main() {
  final us = RegionPresets.byCode('US')!;

  CreationDraft free({String prompt = '', SongModel model = SongModel.clip}) =>
      CreationDraft(
        occasion: Occasion.custom,
        region: us,
        genre: us.genres.first,
        lyricLanguage: LyricLanguage.en,
        prompt: prompt,
        model: model,
      );

  CreationDraft picked({
    String name = '',
    SongModel model = SongModel.clip,
    bool inputRequired = false,
  }) => free(model: model).copyWith(
    occasion: Occasion.birthday,
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
      expect(ComposerSubject.of(null), ComposerSubject.free);
      expect(ComposerSubject.of(free()), ComposerSubject.free);
      expect(ComposerSubject.of(picked()), ComposerSubject.picked);
    });
  });

  group('primary action label table', () {
    final rows = <(String, CreationDraft, MusicEntitlement?, CreateAction)>[
      (
        'Short · no name · free allowance',
        picked(),
        freeTier,
        const CreateAction(
          kind: CreateActionKind.preview,
          cost: CreateCost.free,
          enabled: true,
        ),
      ),
      (
        'Short · Alex · free allowance',
        picked(name: ' Alex '),
        freeTier,
        const CreateAction(
          kind: CreateActionKind.previewFor,
          name: 'Alex',
          cost: CreateCost.free,
          enabled: true,
        ),
      ),
      (
        'Short · plan allowance',
        picked(name: 'Alex'),
        proTier,
        const CreateAction(
          kind: CreateActionKind.previewFor,
          name: 'Alex',
          cost: CreateCost.preview,
          enabled: true,
        ),
      ),
      (
        'Short · nothing left',
        picked(name: 'Alex'),
        empty,
        const CreateAction(
          kind: CreateActionKind.previewFor,
          name: 'Alex',
          cost: CreateCost.none,
          enabled: true,
        ),
      ),
      (
        'Short · ledger unknown',
        picked(),
        null,
        const CreateAction(
          kind: CreateActionKind.preview,
          cost: CreateCost.none,
          enabled: true,
        ),
      ),
      (
        'Standard · songs left (name not shown)',
        picked(name: 'Alex', model: SongModel.fullSong),
        proTier,
        const CreateAction(
          kind: CreateActionKind.fullSong,
          cost: CreateCost.song,
          enabled: true,
        ),
      ),
      (
        'Standard · nothing left',
        picked(model: SongModel.fullSong),
        freeTier,
        const CreateAction(
          kind: CreateActionKind.fullSong,
          cost: CreateCost.none,
          enabled: true,
        ),
      ),
      (
        'free input never names anyone',
        free(prompt: 'rain').copyWith(recipient: 'Alex'),
        freeTier,
        const CreateAction(
          kind: CreateActionKind.preview,
          cost: CreateCost.free,
          enabled: true,
        ),
      ),
    ];
    for (final (name, draft, entitlement, expected) in rows) {
      test(
        name,
        () => expect(
          CreateAction.of(draft: draft, entitlement: entitlement),
          expected,
        ),
      );
    }
  });

  group('enabled', () {
    test('free input needs words, photos or own lyrics', () {
      expect(
        CreateAction.of(draft: free(), entitlement: freeTier).enabled,
        isFalse,
      );
      expect(
        CreateAction.of(
          draft: free(prompt: '  '),
          entitlement: freeTier,
        ).enabled,
        isFalse,
      );
      expect(
        CreateAction.of(
          draft: free(prompt: 'rain'),
          entitlement: freeTier,
        ).enabled,
        isTrue,
      );
      expect(
        CreateAction.of(
          draft: free().copyWith(imageBids: ['b1']),
          entitlement: null,
        ).enabled,
        isTrue,
      );
      expect(
        CreateAction.of(
          draft: free().copyWith(userLyrics: 'la la'),
          entitlement: null,
        ).enabled,
        isTrue,
      );
      expect(
        CreateAction.of(
          draft: free().copyWith(
            userLyrics: 'la la',
            vocals: Vocals.instrumental,
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
          CreateAction.of(draft: picked(), entitlement: empty).enabled,
          isTrue,
        );
        expect(
          CreateAction.of(
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
        CreateAction.of(
          draft: picked(inputRequired: true),
          entitlement: null,
        ).enabled,
        isFalse,
      );
      expect(
        CreateAction.of(
          draft: picked(inputRequired: true).copyWith(prompt: 'see you at 8'),
          entitlement: null,
        ).enabled,
        isTrue,
      );
    });

    test('nothing while a song is being made, or without a draft', () {
      expect(
        CreateAction.of(
          draft: picked(),
          entitlement: proTier,
          busy: true,
        ).enabled,
        isFalse,
      );
      expect(
        CreateAction.of(draft: null, entitlement: proTier).enabled,
        isFalse,
      );
    });
  });

  group('summary row', () {
    test('length · vocals · genre from the draft', () {
      expect(summaryParts(free(), optionsShown: false), [
        SummaryPart.preview,
        SummaryPart.vocalsOn,
        SummaryPart.genre,
      ]);
      expect(
        summaryParts(
          free(
            model: SongModel.fullSong,
          ).copyWith(vocals: Vocals.custom, customGenre: true),
          optionsShown: false,
        ),
        [SummaryPart.fullSong, SummaryPart.anyVocals, SummaryPart.anyGenre],
      );
      expect(
        summaryParts(
          free(
            model: SongModel.fullSong,
          ).copyWith(autoVideo: AutoVideo.chorus, vocals: Vocals.instrumental),
          optionsShown: false,
        ),
        [
          SummaryPart.songAndChorus,
          SummaryPart.instrumental,
          SummaryPart.genre,
        ],
      );
    });

    test('what will be sent from the folded options stays in sight', () {
      final withExtras = free(
        model: SongModel.fullSong,
      ).copyWith(userLyrics: 'la', autoVideo: AutoVideo.lyric);
      expect(summaryParts(withExtras, optionsShown: false), [
        SummaryPart.fullSong,
        SummaryPart.vocalsOn,
        SummaryPart.genre,
        SummaryPart.ownLyrics,
        SummaryPart.video,
      ]);
      expect(
        summaryParts(withExtras, optionsShown: true),
        hasLength(3),
        reason: 'the options show them',
      );
      expect(
        summaryParts(
          withExtras.copyWith(model: SongModel.clip),
          optionsShown: false,
        ),
        [
          SummaryPart.preview,
          SummaryPart.vocalsOn,
          SummaryPart.genre,
          SummaryPart.ownLyrics,
        ],
        reason: 'a preview makes no video',
      );
    });
  });
}
