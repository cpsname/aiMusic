import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:songlet_kit/src/creation/domain/lyrics_fingerprint.dart';

void main() {
  final us = RegionPresets.byCode('US')!;
  final preflight = Preflight();

  CreationDraft draft({
    Occasion occasion = Occasion.birthday,
    String recipient = 'Alex',
    List<String> keywords = const ['coffee', 'hiking', 'Sunday'],
    String? userLyrics,
    bool ownership = false,
    List<List<int>> photos = const [],
    List<String> imageBids = const [],
  }) =>
      CreationDraft(
        occasion: occasion,
        region: us,
        genre: us.genres.first,
        lyricLanguage: LyricLanguage.en,
        recipient: recipient,
        keywords: keywords,
        userLyrics: userLyrics,
        lyricsOwnershipConfirmed: ownership,
        photos: photos,
        imageBids: imageBids,
      );

  List<PreflightIssue> issuesOf(CreationDraft d) => preflight.check(d).issues;

  group('an inspiration decides for itself whether text is needed', () {
    CreationDraft bare({String? slug, Occasion occasion = Occasion.birthday}) => CreationDraft(
          occasion: occasion,
          region: us,
          genre: us.genres.first,
          lyricLanguage: LyricLanguage.en,
          inspirationSlug: slug,
        );

    test('nothing typed is fine for a picked inspiration (the send button enforces input_required)', () {
      expect(issuesOf(bare(slug: 'soundscape')), isEmpty);
      expect(issuesOf(bare(slug: 'birthday_wish')), isEmpty, reason: 'even one that used to ask for a name');
    });

    test('without an inspiration the same draft still needs content', () {
      expect(issuesOf(bare()), containsAll([PreflightIssue.recipientMissing, PreflightIssue.briefMissing]));
    });

    test('the other checks still apply', () {
      final tooLong = bare(slug: 'soundscape').copyWith(prompt: 'x' * 301);
      expect(issuesOf(tooLong), contains(PreflightIssue.promptTooLong));
      final artist = bare(slug: 'soundscape').copyWith(prompt: 'a song in the style of Taylor Swift');
      expect(issuesOf(artist), isNotEmpty);
    });
  });

  group('a valid draft', () {
    test('passes and returns the trimmed draft', () {
      final result = preflight.check(
        draft(recipient: '  Alex  ', keywords: [' coffee ', '', 'hiking  ']),
      );

      expect(result.isOk, isTrue);
      expect(result.issues, isEmpty);
      expect(result.draft!.recipient, 'Alex');
      expect(result.draft!.keywords, ['coffee', 'hiking']);
      expect(result.draft!.userLyrics, isNull);
    });

    test('a failing draft carries no submittable draft', () {
      final result = preflight.check(draft(recipient: ''));
      expect(result.isOk, isFalse);
      expect(result.draft, isNull);
    });
  });

  group('recipient name (≤ 24)', () {
    test('exactly 24 characters passes, 25 fails', () {
      expect(issuesOf(draft(recipient: 'a' * 24)), isEmpty);
      expect(
        issuesOf(draft(recipient: 'a' * 25)),
        [PreflightIssue.recipientTooLong],
      );
    });

    test('counts user-perceived characters (CJK / emoji count once)', () {
      expect(issuesOf(draft(recipient: '小' * 24)), isEmpty);
      expect(issuesOf(draft(recipient: '🎂' * 24)), isEmpty);
    });

    test('missing on a personal occasion is an issue', () {
      expect(issuesOf(draft(recipient: '   ')), [PreflightIssue.recipientMissing]);
    });

    test('brand and soundtrack occasions do not require a recipient', () {
      expect(issuesOf(draft(occasion: Occasion.brand, recipient: '')), isEmpty);
      expect(
        issuesOf(draft(occasion: Occasion.soundtrack, recipient: '')),
        isEmpty,
      );
    });
  });

  group('keywords (≤ 3 × ≤ 20)', () {
    test('three keywords of 20 characters pass', () {
      expect(issuesOf(draft(keywords: ['a' * 20, 'b' * 20, 'c' * 20])), isEmpty);
    });

    test('a 21-character keyword is too long', () {
      expect(
        issuesOf(draft(keywords: ['a' * 21])),
        [PreflightIssue.keywordTooLong],
      );
    });

    test('four keywords are too many', () {
      expect(
        issuesOf(draft(keywords: ['a', 'b', 'c', 'd'])),
        [PreflightIssue.tooManyKeywords],
      );
    });

    test('blank keywords are ignored when counting', () {
      expect(issuesOf(draft(keywords: ['a', ' ', 'b', '', 'c'])), isEmpty);
    });

    test('no keywords, no photos, no lyrics is an issue', () {
      expect(issuesOf(draft(keywords: [])), [PreflightIssue.briefMissing]);
    });

    test('a photos-only draft needs neither keywords nor a recipient', () {
      final photosOnly = draft(
        recipient: '',
        keywords: [],
        photos: [
          [0xff, 0xd8],
        ],
      );
      expect(issuesOf(photosOnly), isEmpty);
      expect(
        issuesOf(draft(recipient: '', keywords: [], imageBids: ['bid-1'])),
        isEmpty,
      );
    });

    test('own lyrics replace keywords', () {
      expect(
        issuesOf(
          draft(keywords: [], userLyrics: 'we laughed all night', ownership: true),
        ),
        isEmpty,
      );
    });
  });

  group('photos (≤ 10)', () {
    test('ten photos pass, eleven fail', () {
      List<List<int>> photos(int n) => List.generate(n, (i) => [i]);
      expect(issuesOf(draft(photos: photos(10))), isEmpty);
      expect(issuesOf(draft(photos: photos(11))), [PreflightIssue.tooManyPhotos]);
      expect(
        issuesOf(draft(imageBids: List.generate(11, (i) => 'b$i'))),
        [PreflightIssue.tooManyPhotos],
      );
    });
  });

  group('artist-name blocklist', () {
    test('an artist name in keywords or lyrics is blocked', () {
      expect(
        issuesOf(draft(keywords: ['Taylor Swift'])),
        contains(PreflightIssue.artistName),
      );
      expect(
        issuesOf(
          draft(userLyrics: 'dancing to drake all night', ownership: true),
        ),
        contains(PreflightIssue.artistName),
      );
    });

    test('case and punctuation variants are caught', () {
      for (final variant in [
        'TAYLOR SWIFT',
        'taylor-swift',
        'Taylor_Swift',
        'taylor.swift!',
        "Taylor Swift's",
        '  taylor   swift  ',
        'Beyoncé',
        'BEYONCE',
        'Celine Dion',
        'Céline Dion',
        'bts',
      ]) {
        expect(
          issuesOf(draft(keywords: [variant])),
          contains(PreflightIssue.artistName),
          reason: variant,
        );
      }
    });

    test('only whole names match (no substring hits)', () {
      expect(issuesOf(draft(keywords: ['subtsy', 'adelaide'])), isEmpty);
      expect(issuesOf(draft(recipient: 'Drakeford')), isEmpty);
    });

    test('a custom blocklist replaces the seed and is case-insensitive', () {
      final custom = Preflight(artistBlocklist: {'Local Hero'});
      expect(
        custom.check(draft(keywords: ['local hero'])).issues,
        [PreflightIssue.artistName],
      );
      expect(custom.check(draft(keywords: ['Taylor Swift'])).issues, isEmpty);
    });
  });

  test('the recipient is a person, not screened against the artist list', () {
    // A friend may well be called Adele or Drake.
    expect(issuesOf(draft(recipient: 'Adele')), isNot(contains(PreflightIssue.artistName)));
  });

  group('style imitation', () {
    test('"in the style of" / "sound like" / "voice of" + a name are blocked (§7.4)', () {
      for (final phrase in [
        'in the style of Queen',
        'sounds like Adele',
        'sound like the Beatles',
        'voice of Freddie',
        'in the style of taylor swift',
      ]) {
        expect(
          issuesOf(draft(keywords: [phrase])),
          contains(PreflightIssue.styleImitation),
          reason: phrase,
        );
      }
    });

    test('also in own lyrics', () {
      expect(
        issuesOf(
          draft(
            userLyrics: 'sing it in the style of Elvis',
            ownership: true,
          ),
        ),
        contains(PreflightIssue.styleImitation),
      );
    });

    test('ordinary words are not flagged', () {
      expect(issuesOf(draft(keywords: ['stylish', 'likes coffee'])), isEmpty);
      // The phrase alone, without a name, is ordinary lyric language.
      expect(
        issuesOf(draft(userLyrics: 'your laugh sounds like summer', ownership: true)),
        isEmpty,
      );
    });
  });

  group('screening one field (where the composer shows the error)', () {
    final preflight = Preflight();

    test('names the field that mentions an artist or imitates one', () {
      expect(preflight.screen('a song for Sunday mornings'), isEmpty);
      expect(preflight.screen('like Taylor Swift'), {PreflightIssue.artistName});
      expect(preflight.screen('in the style of Adele'), {PreflightIssue.artistName, PreflightIssue.styleImitation});
      expect(preflight.screen('sounds like Marco'), {PreflightIssue.styleImitation});
      expect(preflight.screen('your laugh sounds like summer'), isEmpty);
    });
  });

  group('own lyrics', () {
    test('Latin lyrics: 1,200 characters pass, 1,201 fail', () {
      expect(
        issuesOf(draft(userLyrics: 'a' * 1200, ownership: true)),
        isEmpty,
      );
      expect(
        issuesOf(draft(userLyrics: 'a' * 1201, ownership: true)),
        [PreflightIssue.lyricsTooLong],
      );
    });

    test('CJK-heavy lyrics: 600 characters pass, 601 fail', () {
      expect(issuesOf(draft(userLyrics: '爱' * 600, ownership: true)), isEmpty);
      expect(
        issuesOf(draft(userLyrics: '爱' * 601, ownership: true)),
        [PreflightIssue.lyricsTooLong],
      );
    });

    test('700 Latin characters are fine where 700 CJK are not', () {
      expect(issuesOf(draft(userLyrics: 'b' * 700, ownership: true)), isEmpty);
      expect(
        issuesOf(draft(userLyrics: '사' * 700, ownership: true)),
        [PreflightIssue.lyricsTooLong],
      );
    });

    test('section tags do not count toward the limit', () {
      // 599 + blank-line separator (2) + 599 = 1,200 without the tags.
      final lyrics = '[Verse]\n${'a' * 599}\n\n[Chorus]\n${'b' * 599}';
      expect(issuesOf(draft(userLyrics: lyrics, ownership: true)), isEmpty);
    });

    test('the ownership checkbox is required', () {
      expect(
        issuesOf(draft(userLyrics: 'our little song')),
        [PreflightIssue.lyricsOwnershipUnconfirmed],
      );
    });

    test('lyrics > 0.8 similar to a public-domain song are blocked', () {
      const twinkle = 'Twinkle, twinkle, little star\n'
          'How I wonder what you are\n'
          'Up above the world so high\n'
          'Like a diamond in the sky';
      expect(
        issuesOf(draft(userLyrics: twinkle, ownership: true)),
        [PreflightIssue.lyricsNotOriginal],
      );
    });

    test('a short "happy birthday Alex" passes the originality check', () {
      final result = preflight.check(
        draft(userLyrics: 'happy birthday Alex', ownership: true),
      );
      expect(result.isOk, isTrue);
    });

    test('a custom fingerprint index is used', () {
      const song = 'the quick brown fox jumps over the lazy dog every day';
      final custom = Preflight(
        fingerprints: LyricsFingerprintIndex([LyricsFingerprintIndex.fingerprint(song)]),
      );
      expect(
        custom.check(draft(userLyrics: song, ownership: true)).issues,
        [PreflightIssue.lyricsNotOriginal],
      );
      expect(
        custom
            .check(
              draft(
                userLyrics: 'Twinkle twinkle little star how I wonder what you '
                    'are up above the world so high',
                ownership: true,
              ),
            )
            .issues,
        isEmpty,
      );
    });

    test('the returned draft carries auto [Verse] / [Chorus] tags', () {
      final result = preflight.check(
        draft(
          userLyrics: 'morning coffee with you\nwalking by the river\n\n'
              'you are my sunday\nevery single day',
          ownership: true,
        ),
      );

      expect(result.isOk, isTrue);
      expect(
        result.draft!.userLyrics,
        '[Verse]\nmorning coffee with you\nwalking by the river\n\n'
        '[Chorus]\nyou are my sunday\nevery single day',
      );
    });

    test('already-tagged lyrics are only trimmed', () {
      const tagged = '[Intro]\nla la\n\n[Chorus]\nhey hey';
      final result = preflight.check(
        draft(userLyrics: '\n  $tagged  \n', ownership: true),
      );
      expect(result.draft!.userLyrics, tagged);
    });

    test('blank lyrics count as none', () {
      final result = preflight.check(draft(userLyrics: '   \n  '));
      expect(result.isOk, isTrue);
      expect(result.draft!.userLyrics, isNull);
    });
  });

  test('every issue is reported at once', () {
    final issues = issuesOf(
      draft(
        recipient: 'x' * 30,
        keywords: ['a' * 25, 'b', 'c', 'Adele'],
        userLyrics: '爱' * 700,
      ),
    );
    expect(
      issues,
      containsAll(<PreflightIssue>[
        PreflightIssue.recipientTooLong,
        PreflightIssue.tooManyKeywords,
        PreflightIssue.keywordTooLong,
        PreflightIssue.artistName,
        PreflightIssue.lyricsTooLong,
        PreflightIssue.lyricsOwnershipUnconfirmed,
      ]),
    );
  });
}
