import 'package:songlet_mock_server/songlet_mock_server.dart';
import 'package:test/test.dart';

void main() {
  const languages = [
    'en', 'ja', 'pt', 'es', 'de', 'fr', 'ko', 'hi', 'id', 'vi', 'tr', 'zh', //
  ];

  test('every required language has a template', () {
    expect(supportedLyricLanguages, containsAll(languages));
  });

  for (final lang in languages) {
    test('$lang: recipient ≥1× in a clip, ≥2× in a song, tags present', () {
      final prompt = PromptBlock.parse(
        'recipient: Zoë\nkeywords: kite | river\nlyric_language: $lang\n',
      );
      final clip = generateLyrics(prompt: prompt, isSong: false);
      final song = generateLyrics(prompt: prompt, isSong: true);
      expect('Zoë'.allMatches(clip).length, greaterThanOrEqualTo(1));
      expect('Zoë'.allMatches(song).length, greaterThanOrEqualTo(2));
      for (final tag in ['[Intro]', '[Verse]', '[Chorus]']) {
        expect(clip, contains(tag));
        expect(song, contains(tag));
      }
      for (final tag in ['[Verse 2]', '[Bridge]', '[Outro]']) {
        expect(clip, isNot(contains(tag)));
        expect(song, contains(tag));
      }
      expect(clip, contains('kite'));
    });
  }

  test('region subtags and unknown languages', () {
    final pt = generateLyrics(
      prompt: PromptBlock.parse('recipient: Ana\nlyric_language: pt-BR'),
      isSong: false,
    );
    expect(pt, contains('pra você'));
    final fallback = generateLyrics(
      prompt: PromptBlock.parse('recipient: Ana\nlyric_language: xx'),
      isSong: false,
    );
    expect(fallback, contains('this one is for you'));
  });

  test('clip and song structures', () {
    expect(structureFor(isSong: false).last['end'], 30.0);
    final song = structureFor(isSong: true);
    expect(song, hasLength(8));
    expect(song.first, {'section': 'Intro', 'start': 0.0, 'end': 8.0});
    expect(song.last, {'section': 'Outro', 'start': 112.0, 'end': 120.0});
  });
}
