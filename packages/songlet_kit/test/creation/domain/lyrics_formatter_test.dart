import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

void main() {
  group('isMostlyCjk / limitFor', () {
    test('Latin text uses the 1,200 limit', () {
      expect(MusicLyricsFormatter.isMostlyCjk('hello world'), isFalse);
      expect(MusicLyricsFormatter.limitFor('hello world'), MusicLyricsFormatter.latinLimit);
      expect(MusicLyricsFormatter.latinLimit, 1200);
    });

    test('Chinese, Japanese kana and Korean hangul use the 600 limit', () {
      for (final text in ['生日快乐', 'おめでとう', 'カタカナ', '사랑해요']) {
        expect(MusicLyricsFormatter.isMostlyCjk(text), isTrue, reason: text);
        expect(MusicLyricsFormatter.limitFor(text), MusicLyricsFormatter.cjkLimit);
      }
      expect(MusicLyricsFormatter.cjkLimit, 600);
    });

    test('the threshold is > 30 % of the non-space characters', () {
      // 3 CJK of 10 visible = exactly 30 % → not mostly CJK.
      expect(MusicLyricsFormatter.isMostlyCjk('爱爱爱abcdefg'), isFalse);
      // 4 of 10 → mostly CJK.
      expect(MusicLyricsFormatter.isMostlyCjk('爱爱爱爱abcdef'), isTrue);
      // Whitespace is ignored when counting.
      expect(MusicLyricsFormatter.isMostlyCjk('爱 爱 爱 爱      abcdef'), isTrue);
    });

    test('empty / whitespace-only text is not CJK', () {
      expect(MusicLyricsFormatter.isMostlyCjk(''), isFalse);
      expect(MusicLyricsFormatter.isMostlyCjk('  \n '), isFalse);
    });
  });

  group('withSectionTags', () {
    test('stanzas alternate [Verse] / [Chorus]', () {
      expect(
        MusicLyricsFormatter.withSectionTags('a1\na2\n\nb1\nb2\n\nc1'),
        '[Verse]\na1\na2\n\n[Chorus]\nb1\nb2\n\n[Verse]\nc1',
      );
    });

    test('a single stanza is split in half (first half rounds up)', () {
      expect(
        MusicLyricsFormatter.withSectionTags('l1\nl2\nl3'),
        '[Verse]\nl1\nl2\n\n[Chorus]\nl3',
      );
      expect(
        MusicLyricsFormatter.withSectionTags('l1\nl2\nl3\nl4'),
        '[Verse]\nl1\nl2\n\n[Chorus]\nl3\nl4',
      );
    });

    test('a single line becomes one verse', () {
      expect(MusicLyricsFormatter.withSectionTags('only line'), '[Verse]\nonly line');
    });

    test('CRLF and extra blank lines are normalized', () {
      expect(
        MusicLyricsFormatter.withSectionTags('\r\n a1\r\n\r\n\r\n  \r\nb1 \r\n'),
        '[Verse]\na1\n\n[Chorus]\nb1',
      );
    });

    test('lyrics that already carry tags are only trimmed', () {
      const tagged = '[Intro]\nooh\n\n[Chorus]\nla la';
      expect(MusicLyricsFormatter.withSectionTags('  $tagged \n'), tagged);
      expect(
        MusicLyricsFormatter.withSectionTags('line one\n[Bridge]\nline two'),
        'line one\n[Bridge]\nline two',
      );
    });

    test('an inline bracket is not a tag line', () {
      expect(
        MusicLyricsFormatter.withSectionTags('[wink] hello\nthere'),
        '[Verse]\n[wink] hello\n\n[Chorus]\nthere',
      );
    });

    test('empty input stays empty', () {
      expect(MusicLyricsFormatter.withSectionTags('   '), '');
    });
  });
}
