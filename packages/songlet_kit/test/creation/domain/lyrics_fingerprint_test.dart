import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/src/creation/domain/music_lyrics_fingerprint.dart';

void main() {
  group('fingerprint', () {
    test('one hash per distinct word 3-gram', () {
      expect(MusicLyricsFingerprintIndex.fingerprint('a b c d e'), hasLength(3));
      expect(MusicLyricsFingerprintIndex.fingerprint('a b'), isEmpty);
      // Repeated 3-grams collapse.
      expect(MusicLyricsFingerprintIndex.fingerprint('la la la la la'), hasLength(1));
    });

    test('ignores case, punctuation and whitespace layout', () {
      expect(
        MusicLyricsFingerprintIndex.fingerprint('Hello, World!\nHow  are you?'),
        MusicLyricsFingerprintIndex.fingerprint('hello world how are you'),
      );
    });

    test('keeps apostrophes inside words', () {
      expect(
        MusicLyricsFingerprintIndex.fingerprint("we'll take a cup"),
        isNot(MusicLyricsFingerprintIndex.fingerprint('we ll take a cup')),
      );
    });

    test('is deterministic 32-bit FNV-1a', () {
      final hashes = MusicLyricsFingerprintIndex.fingerprint('one two three');
      expect(hashes, hasLength(1));
      expect(hashes.single, inInclusiveRange(0, 0xffffffff));
      expect(MusicLyricsFingerprintIndex.fingerprint('one two three'), hashes);
    });

    test('handles non-Latin letters', () {
      expect(
        MusicLyricsFingerprintIndex.fingerprint('привет мой друг как дела'),
        hasLength(3),
      );
    });
  });

  group('maxSimilarity', () {
    const song = 'the quick brown fox jumps over the lazy dog and runs away fast';
    final index = MusicLyricsFingerprintIndex([MusicLyricsFingerprintIndex.fingerprint(song)]);

    test('the same text is fully contained', () {
      expect(index.maxSimilarity(song), 1.0);
    });

    test('a copied excerpt with different punctuation is fully contained', () {
      expect(
        index.maxSimilarity('The quick brown fox, jumps over the lazy dog!'),
        1.0,
      );
    });

    test('unrelated lyrics score 0', () {
      expect(
        index.maxSimilarity('my own original words about a sunny day at the beach'),
        0,
      );
    });

    test('partial overlap is the contained share of the user shingles', () {
      // 8 shingles: the first 4 come from the song, the rest do not.
      const mixed = 'the quick brown fox jumps over purple elephants dancing tonight';
      final score = index.maxSimilarity(mixed);
      expect(score, closeTo(4 / 8, 1e-9));
    });

    test('fewer than minShingles shingles never score', () {
      expect(MusicLyricsFingerprintIndex.minShingles, 6);
      // 5 shingles from the song (7 words) → below the floor.
      expect(index.maxSimilarity('the quick brown fox jumps over the'), 0);
      // 6 shingles (8 words) → compared.
      expect(index.maxSimilarity('the quick brown fox jumps over the lazy'), 1.0);
    });

    test('takes the best match over all indexed songs', () {
      final multi = MusicLyricsFingerprintIndex([
        MusicLyricsFingerprintIndex.fingerprint('alpha beta gamma delta epsilon zeta eta theta'),
        MusicLyricsFingerprintIndex.fingerprint(song),
      ]);
      expect(multi.maxSimilarity(song), 1.0);
    });

    test('an empty index scores 0', () {
      expect(MusicLyricsFingerprintIndex(const []).maxSimilarity(song), 0);
    });
  });

  group('publicDomain seed', () {
    final seed = MusicLyricsFingerprintIndex.publicDomain();

    test('flags a copied public-domain song', () {
      expect(
        seed.maxSimilarity(
          'Amazing grace, how sweet the sound\n'
          'That saved a wretch like me\n'
          'I once was lost, but now am found\n'
          'Was blind, but now I see',
        ),
        greaterThan(0.8),
      );
      expect(
        seed.maxSimilarity(
          'Mary had a little lamb, its fleece was white as snow',
        ),
        greaterThan(0.8),
      );
    });

    test('does not flag "happy birthday Alex"', () {
      expect(seed.maxSimilarity('happy birthday Alex'), 0);
    });

    test('does not flag original lyrics', () {
      expect(
        seed.maxSimilarity(
          'Coffee in the morning and a hike on Sunday\n'
          'You make every ordinary day feel like a holiday',
        ),
        lessThan(0.8),
      );
    });
  });
}
