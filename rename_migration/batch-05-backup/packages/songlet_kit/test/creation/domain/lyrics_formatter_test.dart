import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

void main() {
  group('isMostlyCjk / limitFor', () {
    test('Latin text uses the 1,200 limit', () {
      expect(LyricsFormatter.isMostlyCjk('hello world'), isFalse);
      expect(LyricsFormatter.limitFor('hello world'), LyricsFormatter.latinLimit);
      expect(LyricsFormatter.latinLimit, 1200);
    });

    test('Chinese, Japanese kana and Korean hangul use the 600 limit', () {
      for (final text in ['生日快乐', 'おめでとう', 'カタカナ', '사랑해요']) {
        expect(LyricsFormatter.isMostlyCjk(text), isTrue, reason: text);
        expect(LyricsFormatter.limitFor(text), LyricsFormatter.cjkLimit);
      }
      expect(LyricsFormatter.cjkLimit, 600);
    });

    test('the threshold is > 30 % of the non-space characters', () {
      // 3 CJK of 10 visible = exactly 30 % → not mostly CJK.
      expect(LyricsFormatter.isMostlyCjk('爱爱爱abcdefg'), isFalse);
      // 4 of 10 → mostly CJK.
      expect(LyricsFormatter.isMostlyCjk('爱爱爱爱abcdef'), isTrue);
      // Whitespace is ignored when counting.
      expect(LyricsFormatter.isMostlyCjk('爱 爱 爱 爱      abcdef'), isTrue);
    });

    test('empty / whitespace-only text is not CJK', () {
      expect(LyricsFormatter.isMostlyCjk(''), isFalse);
      expect(LyricsFormatter.isMostlyCjk('  \n '), isFalse);
    });
  });

  group('withSectionTags', () {
    test('stanzas alternate [Verse] / [Chorus]', () {
      expect(
        LyricsFormatter.withSectionTags('a1\na2\n\nb1\nb2\n\nc1'),
        '[Verse]\na1\na2\n\n[Chorus]\nb1\nb2\n\n[Verse]\nc1',
      );
    });

    test('a single stanza is split in half (first half rounds up)', () {
      expect(
        LyricsFormatter.withSectionTags('l1\nl2\nl3'),
        '[Verse]\nl1\nl2\n\n[Chorus]\nl3',
      );
      expect(
        LyricsFormatter.withSectionTags('l1\nl2\nl3\nl4'),
        '[Verse]\nl1\nl2\n\n[Chorus]\nl3\nl4',
      );
    });

    test('a single line becomes one verse', () {
      expect(LyricsFormatter.withSectionTags('only line'), '[Verse]\nonly line');
    });

    test('CRLF and extra blank lines are normalized', () {
      expect(
        LyricsFormatter.withSectionTags('\r\n a1\r\n\r\n\r\n  \r\nb1 \r\n'),
        '[Verse]\na1\n\n[Chorus]\nb1',
      );
    });

    test('lyrics that already carry tags are only trimmed', () {
      const tagged = '[Intro]\nooh\n\n[Chorus]\nla la';
      expect(LyricsFormatter.withSectionTags('  $tagged \n'), tagged);
      expect(
        LyricsFormatter.withSectionTags('line one\n[Bridge]\nline two'),
        'line one\n[Bridge]\nline two',
      );
    });

    test('an inline bracket is not a tag line', () {
      expect(
        LyricsFormatter.withSectionTags('[wink] hello\nthere'),
        '[Verse]\n[wink] hello\n\n[Chorus]\nthere',
      );
    });

    test('empty input stays empty', () {
      expect(LyricsFormatter.withSectionTags('   '), '');
    });
  });
}
