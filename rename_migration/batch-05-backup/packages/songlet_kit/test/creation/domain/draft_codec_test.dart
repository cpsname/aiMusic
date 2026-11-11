import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

void main() {
  Work work({
    String region = 'JP',
    String lyricLanguage = 'ja',
    String? userLyrics,
    Festival? festival,
    List<String> imageBids = const [],
  }) =>
      Work(
        id: 'w1',
        jobId: 'job-1',
        model: SongModel.clip,
        status: WorkStatus.ready,
        occasion: Occasion.festival,
        festival: festival,
        region: region,
        genre: 'Chiptune',
        lyricLanguage: lyricLanguage,
        recipient: 'Yuki',
        keywords: const ['snow', 'ramen'],
        userLyrics: userLyrics,
        imageBids: imageBids,
        createdAt: DateTime.utc(2026),
      );

  test('the inspiration comes back with the work, so another version sends it again', () {
    final base = work();
    final withSlug = Work(
      id: base.id,
      model: base.model,
      status: base.status,
      occasion: base.occasion,
      region: base.region,
      genre: base.genre,
      lyricLanguage: base.lyricLanguage,
      createdAt: base.createdAt,
      inspiration: 'soundscape',
    );
    expect(draftFromWork(withSlug)!.inspirationSlug, 'soundscape');
    expect(draftFromWork(base)!.inspirationSlug, isNull);
  });

  test("a description saved with a pick was the card's words: it is sent again", () {
    final base = work();
    Work picked(String prompt) => Work(
          id: base.id,
          model: base.model,
          status: base.status,
          occasion: Occasion.confession,
          region: base.region,
          genre: base.genre,
          lyricLanguage: base.lyricLanguage,
          createdAt: base.createdAt,
          inspiration: 'text_messages',
          prompt: prompt,
        );
    final replay = draftFromWork(picked('see you at 8'))!;
    expect(replay.pickInputRequired, isTrue);
    expect(replay.forSubmit().prompt, 'see you at 8');
    expect(draftFromWork(picked(''))!.pickInputRequired, isFalse);
    expect(draftFromWork(base)!.pickInputRequired, isFalse, reason: 'free input has no pick');
  });

  test('rebuilds every creation input from the work', () {
    final draft = draftFromWork(
      work(
        festival: Festival.newYear,
        userLyrics: '[Verse]\nsnow',
        imageBids: ['b1', 'b2'],
      ),
    )!;

    expect(draft.occasion, Occasion.festival);
    expect(draft.region, same(RegionPresets.byCode('JP')));
    expect(draft.genre, 'Chiptune');
    expect(draft.lyricLanguage, LyricLanguage.ja);
    expect(draft.festival, Festival.newYear);
    expect(draft.recipient, 'Yuki');
    expect(draft.keywords, ['snow', 'ramen']);
    expect(draft.userLyrics, '[Verse]\nsnow');
    expect(draft.lyricsOwnershipConfirmed, isTrue);
    expect(draft.imageBids, ['b1', 'b2']);
    expect(draft.photos, isEmpty, reason: 'photo bytes are never kept');
    expect(draft.usesPhotos, isTrue);
  });

  test('ownership is only pre-confirmed when the work had own lyrics', () {
    final draft = draftFromWork(work())!;
    expect(draft.userLyrics, isNull);
    expect(draft.lyricsOwnershipConfirmed, isFalse);
  });

  test('an unknown lyric language falls back to the preset language', () {
    expect(
      draftFromWork(work(region: 'IN', lyricLanguage: 'xx'))!.lyricLanguage,
      LyricLanguage.hi,
    );
    expect(
      draftFromWork(work(region: 'CA', lyricLanguage: 'fr'))!.lyricLanguage,
      LyricLanguage.fr,
    );
  });

  test('a region outside the presets yields no draft', () {
    expect(draftFromWork(work(region: 'ES')), isNull);
  });

  test('the rebuilt draft passes preflight again', () {
    final draft = draftFromWork(work(userLyrics: '[Verse]\nsnow on the roof'))!;
    expect(Preflight().check(draft).isOk, isTrue);
  });
}
