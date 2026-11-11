import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

CreationDraft _draft({
  Occasion occasion = Occasion.custom,
  SongTemplate? template,
  String recipient = '',
  List<String> keywords = const [],
  String prompt = '',
  String? genre = 'Indie Pop',
  Vocals vocals = Vocals.vocals,
}) =>
    CreationDraft(
      occasion: template?.occasion ?? occasion,
      template: template,
      region: RegionPresets.all.first,
      genre: genre,
      lyricLanguage: LyricLanguage.en,
      recipient: recipient,
      keywords: keywords,
      prompt: prompt,
      vocals: vocals,
    );

void main() {
  group('catalogues', () {
    test('18 genres, unique labels, same list for every region (ADR-0005)', () {
      expect(Genre.values, hasLength(18));
      expect(Genre.values.map((g) => g.label).toSet(), hasLength(18));
      expect(Genre.fromLabel('Hip-Hop & Rap'), Genre.hipHop);
      expect(Genre.fromLabel('Indie Pop'), isNull);
    });

    test('16 templates, unique ids, each on a PRD F01 occasion (ADR-0008)', () {
      expect(SongTemplate.values, hasLength(16));
      expect(SongTemplate.values.map((t) => t.id).toSet(), hasLength(16));
      for (final t in SongTemplate.values) {
        expect(Occasion.templates, contains(t.occasion), reason: t.id);
        expect(SongTemplate.fromId(t.id), t);
      }
    });

    test('custom is not one of the eight occasion cards', () {
      expect(Occasion.templates, hasLength(8));
      expect(Occasion.templates, isNot(contains(Occasion.custom)));
      expect(Occasion.custom.requiresRecipient, isFalse);
    });
  });

  group('preflight', () {
    final preflight = Preflight();

    test('a free-form prompt alone is enough', () {
      final result = preflight.check(_draft(prompt: 'A song for my sister moving to Lisbon'));
      expect(result.isOk, isTrue);
      expect(result.draft!.prompt, 'A song for my sister moving to Lisbon');
    });

    test('an empty free-form draft asks for words', () {
      expect(preflight.check(_draft()).issues, [PreflightIssue.briefMissing]);
    });

    test('a scene never requires a name (contract 02 v2.1 §1.3); a free-form occasion that names someone still does', () {
      expect(preflight.check(_draft(template: SongTemplate.birthdayWish)).isOk, isTrue, reason: 'the card alone can be sent');
      expect(preflight.check(_draft(template: SongTemplate.businessPromo, keywords: ['tacos'])).isOk, isTrue);
      expect(preflight.check(_draft(occasion: Occasion.birthday, keywords: ['coffee'])).issues, [PreflightIssue.recipientMissing]);
    });

    test('prompt over 300 characters is rejected', () {
      final long = 'a' * (Preflight.maxPrompt + 1);
      expect(preflight.check(_draft(prompt: long)).issues, contains(PreflightIssue.promptTooLong));
    });

    test('the prompt is screened for artists and imitation', () {
      expect(
        preflight.check(_draft(prompt: 'make it sound like Drake')).issues,
        containsAll([PreflightIssue.artistName, PreflightIssue.styleImitation]),
      );
    });

    test('P18: "Taylor Swift style" in the name field is rejected', () {
      final issues = preflight
          .check(_draft(template: SongTemplate.birthdayWish, recipient: 'Taylor Swift style', keywords: ['coffee']))
          .issues;
      expect(issues, [PreflightIssue.recipientArtistName]);
    });

    test('a friend called Adele is still fine', () {
      expect(
        preflight.check(_draft(template: SongTemplate.birthdayWish, recipient: 'Adele', keywords: ['coffee'])).isOk,
        isTrue,
      );
      expect(
        preflight.check(_draft(template: SongTemplate.birthdayWish, recipient: 'Adele style', keywords: ['coffee'])).issues,
        [PreflightIssue.recipientArtistName],
      );
    });
  });

  group('prompt block', () {
    test('carries the template as the scene, description, vocals; omits a custom genre', () {
      final block = PromptBlock.build(_draft(
        template: SongTemplate.petAnthem,
        recipient: 'Biscuit',
        prompt: 'a golden retriever who loves the beach',
        genre: null,
        vocals: Vocals.instrumental,
      ));
      expect(block, contains('inspiration: pet_anthem'));
      expect(block, contains('description: a golden retriever who loves the beach'));
      expect(block, contains('vocals: instrumental'));
      expect(block, isNot(contains('genre:')));
    });

    test('keeps the chosen genre', () {
      expect(PromptBlock.build(_draft(genre: 'Bossa Nova')), contains('genre: Bossa Nova'));
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
