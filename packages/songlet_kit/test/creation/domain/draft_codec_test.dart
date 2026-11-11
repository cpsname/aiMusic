import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

void main() {
  MusicWork work({
    String region = 'JP',
    String lyricLanguage = 'ja',
    String? userLyrics,
    MusicFestival? festival,
    List<String> imageBids = const [],
  }) =>
      MusicWork(
        id: 'w1',
        jobId: 'job-1',
        model: MusicSongModel.clip,
        status: MusicWorkStatus.ready,
        occasion: MusicOccasion.festival,
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
    final withSlug = MusicWork(
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
    MusicWork picked(String prompt) => MusicWork(
          id: base.id,
          model: base.model,
          status: base.status,
          occasion: MusicOccasion.confession,
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
        festival: MusicFestival.newYear,
        userLyrics: '[Verse]\nsnow',
        imageBids: ['b1', 'b2'],
      ),
    )!;

    expect(draft.occasion, MusicOccasion.festival);
    expect(draft.region, same(RegionPresets.byCode('JP')));
    expect(draft.genre, 'Chiptune');
    expect(draft.lyricLanguage, MusicLyricLanguage.ja);
    expect(draft.festival, MusicFestival.newYear);
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
      MusicLyricLanguage.hi,
    );
    expect(
      draftFromWork(work(region: 'CA', lyricLanguage: 'fr'))!.lyricLanguage,
      MusicLyricLanguage.fr,
    );
  });

  test('a region outside the presets yields no draft', () {
    expect(draftFromWork(work(region: 'ES')), isNull);
  });

  test('the rebuilt draft passes preflight again', () {
    final draft = draftFromWork(work(userLyrics: '[Verse]\nsnow on the roof'))!;
    expect(MusicPreflight().check(draft).isOk, isTrue);
  });
}
