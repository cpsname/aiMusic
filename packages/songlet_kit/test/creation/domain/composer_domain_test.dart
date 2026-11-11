import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

MusicCreationDraft _draft({
  MusicOccasion occasion = MusicOccasion.custom,
  MusicSongTemplate? template,
  String recipient = '',
  List<String> keywords = const [],
  String prompt = '',
  String? genre = 'Indie Pop',
  MusicVocals vocals = MusicVocals.vocals,
}) =>
    MusicCreationDraft(
      occasion: template?.occasion ?? occasion,
      template: template,
      region: RegionPresets.all.first,
      genre: genre,
      lyricLanguage: MusicLyricLanguage.en,
      recipient: recipient,
      keywords: keywords,
      prompt: prompt,
      vocals: vocals,
    );

void main() {
  group('catalogues', () {
    test('18 genres, unique labels, same list for every region (ADR-0005)', () {
      expect(MusicGenre.values, hasLength(18));
      expect(MusicGenre.values.map((g) => g.label).toSet(), hasLength(18));
      expect(MusicGenre.fromLabel('Hip-Hop & Rap'), MusicGenre.hipHop);
      expect(MusicGenre.fromLabel('Indie Pop'), isNull);
    });

    test('16 templates, unique ids, each on a PRD F01 occasion (ADR-0008)', () {
      expect(MusicSongTemplate.values, hasLength(16));
      expect(MusicSongTemplate.values.map((t) => t.id).toSet(), hasLength(16));
      for (final t in MusicSongTemplate.values) {
        expect(MusicOccasion.templates, contains(t.occasion), reason: t.id);
        expect(MusicSongTemplate.fromId(t.id), t);
      }
    });

    test('custom is not one of the eight occasion cards', () {
      expect(MusicOccasion.templates, hasLength(8));
      expect(MusicOccasion.templates, isNot(contains(MusicOccasion.custom)));
      expect(MusicOccasion.custom.requiresRecipient, isFalse);
    });
  });

  group('preflight', () {
    final preflight = MusicPreflight();

    test('a free-form prompt alone is enough', () {
      final result = preflight.check(_draft(prompt: 'A song for my sister moving to Lisbon'));
      expect(result.isOk, isTrue);
      expect(result.draft!.prompt, 'A song for my sister moving to Lisbon');
    });

    test('an empty free-form draft asks for words', () {
      expect(preflight.check(_draft()).issues, [MusicPreflightIssue.briefMissing]);
    });

    test('a scene never requires a name (contract 02 v2.1 §1.3); a free-form occasion that names someone still does', () {
      expect(preflight.check(_draft(template: MusicSongTemplate.birthdayWish)).isOk, isTrue, reason: 'the card alone can be sent');
      expect(preflight.check(_draft(template: MusicSongTemplate.businessPromo, keywords: ['tacos'])).isOk, isTrue);
      expect(preflight.check(_draft(occasion: MusicOccasion.birthday, keywords: ['coffee'])).issues, [MusicPreflightIssue.recipientMissing]);
    });

    test('prompt over 300 characters is rejected', () {
      final long = 'a' * (MusicPreflight.maxPrompt + 1);
      expect(preflight.check(_draft(prompt: long)).issues, contains(MusicPreflightIssue.promptTooLong));
    });

    test('the prompt is screened for artists and imitation', () {
      expect(
        preflight.check(_draft(prompt: 'make it sound like Drake')).issues,
        containsAll([MusicPreflightIssue.artistName, MusicPreflightIssue.styleImitation]),
      );
    });

    test('P18: "Taylor Swift style" in the name field is rejected', () {
      final issues = preflight
          .check(_draft(template: MusicSongTemplate.birthdayWish, recipient: 'Taylor Swift style', keywords: ['coffee']))
          .issues;
      expect(issues, [MusicPreflightIssue.recipientArtistName]);
    });

    test('a friend called Adele is still fine', () {
      expect(
        preflight.check(_draft(template: MusicSongTemplate.birthdayWish, recipient: 'Adele', keywords: ['coffee'])).isOk,
        isTrue,
      );
      expect(
        preflight.check(_draft(template: MusicSongTemplate.birthdayWish, recipient: 'Adele style', keywords: ['coffee'])).issues,
        [MusicPreflightIssue.recipientArtistName],
      );
    });
  });

  group('prompt block', () {
    test('carries the template as the scene, description, vocals; omits a custom genre', () {
      final block = MusicPromptBlock.build(_draft(
        template: MusicSongTemplate.petAnthem,
        recipient: 'Biscuit',
        prompt: 'a golden retriever who loves the beach',
        genre: null,
        vocals: MusicVocals.instrumental,
      ));
      expect(block, contains('inspiration: pet_anthem'));
      expect(block, contains('description: a golden retriever who loves the beach'));
      expect(block, contains('vocals: instrumental'));
      expect(block, isNot(contains('genre:')));
    });

    test('keeps the chosen genre', () {
      expect(MusicPromptBlock.build(_draft(genre: 'Bossa Nova')), contains('genre: Bossa Nova'));
    });
  });

  group('draft', () {
    test('customGenre clears the genre; a later genre sets it again', () {
      final custom = _draft().copyWith(customGenre: true);
      expect(custom.genre, isNull);
      expect(custom.copyWith(genre: 'Pop').genre, 'Pop');
    });
  });
}
