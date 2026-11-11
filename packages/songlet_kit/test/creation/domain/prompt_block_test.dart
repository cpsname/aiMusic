import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

/// `/v1/generate` as contract 02 v2.1 §2 defines it: eight top-level fields,
/// everything the user filled in inside the `prompt` block.
void main() {
  final us = RegionPresets.byCode('US')!;
  final india = RegionPresets.byCode('IN')!;

  MusicCreationDraft draft({
    MusicOccasion occasion = MusicOccasion.birthday,
    MusicRegionPreset? region,
    MusicSongTemplate? template = MusicSongTemplate.birthdayWish,
    String? inspirationSlug,
    String recipient = 'Alex',
    List<String> keywords = const ['coffee', 'hiking', 'Sunday'],
    String prompt = '',
    String? userLyrics,
    MusicVocals vocals = MusicVocals.vocals,
    MusicFestival? festival,
    MusicLyricLanguage language = MusicLyricLanguage.en,
    List<String> imageBids = const [],
  }) {
    final preset = region ?? us;
    return MusicCreationDraft(
      occasion: occasion,
      region: preset,
      genre: preset.genres.first,
      lyricLanguage: language,
      template: template,
      inspirationSlug: inspirationSlug,
      festival: festival,
      recipient: recipient,
      keywords: keywords,
      prompt: prompt,
      userLyrics: userLyrics,
      vocals: vocals,
      imageBids: imageBids,
    );
  }

  Map<String, Object?> body(MusicCreationDraft d, {String note = ''}) =>
      MusicGenerationRequest.fromDraft(d, clientRef: 'ref-1', note: note).toJson();

  group('request (§2.1)', () {
    test('the contract\'s example: a scene, nothing typed', () {
      final json = body(MusicCreationDraft(
        occasion: MusicOccasion.confession,
        region: us,
        genre: 'Pop',
        lyricLanguage: MusicLyricLanguage.en,
        inspirationSlug: 'say_it_with_a_track',
        vocals: MusicVocals.instrumental,
      ));
      expect(json, {
        'model': 'lyria-3-clip-preview',
        'occasion': 'confession',
        'inspiration': 'say_it_with_a_track',
        'region': 'US',
        'prompt': 'inspiration: say_it_with_a_track\ngenre: Pop\nvocals: instrumental\nlyric_language: en',
        'client_ref': 'ref-1',
      });
    });

    test('only the eight contract fields, never an id or a top-level fact', () {
      final json = body(draft(inspirationSlug: 'birthday_wish', prompt: 'warm', userLyrics: '[Verse]\nhi', imageBids: ['b1']));
      expect(json.keys.toSet().difference({'model', 'occasion', 'inspiration', 'region', 'prompt', 'lyrics', 'images', 'client_ref'}), isEmpty);
    });

    test('top-level inspiration and the first line are the same slug', () {
      final json = body(draft(inspirationSlug: 'birthday_wish'));
      expect(json['inspiration'], 'birthday_wish');
      expect((json['prompt']! as String).split('\n').first, 'inspiration: birthday_wish');
    });

    test('an offline template is sent by its id as the scene slug', () {
      final json = body(draft());
      expect(json['inspiration'], 'birthday_wish');
      expect(json['prompt'], isNot(contains('template:')));
    });

    test('free input: no inspiration anywhere', () {
      final json = body(draft(occasion: MusicOccasion.custom, template: null, prompt: 'rain'));
      expect(json.containsKey('inspiration'), isFalse);
      expect(json['prompt'], isNot(contains('inspiration:')));
    });
  });

  group('prompt block (§2.2)', () {
    test('the contract\'s line format and order', () {
      expect(
        MusicPromptBlock.build(draft(prompt: 'I am proud of her'), note: 'A warm acoustic birthday song'),
        'inspiration: birthday_wish\n'
        'recipient: Alex\n'
        'keywords: coffee | hiking | Sunday\n'
        'description: I am proud of her\n'
        'genre: Indie Pop\n'
        'vocals: vocals\n'
        'lyric_language: en\n'
        'note: A warm acoustic birthday song',
      );
    });

    test('no description line without the user\'s own text; vocals and lyric_language always', () {
      final block = MusicPromptBlock.build(draft(occasion: MusicOccasion.brand, template: null, recipient: '', keywords: []), note: '  ');
      expect(block, 'genre: Indie Pop\nvocals: vocals\nlyric_language: en');
    });

    test('festival, photo count, BCP-47 language', () {
      final block = MusicPromptBlock.build(draft(
        occasion: MusicOccasion.festival,
        region: india,
        template: MusicSongTemplate.festival,
        festival: MusicFestival.diwali,
        language: MusicLyricLanguage.zhHant,
        imageBids: ['b1', 'b2', 'b3'],
      ));
      expect(block.split('\n'), containsAll(['festival: diwali', 'lyric_language: zh-Hant', 'photos: 3', 'genre: Bhangra']));
    });

    test('user text cannot inject a line, a key twice, or control characters', () {
      final block = MusicPromptBlock.build(
        draft(recipient: 'Alex\ngenre: Death Metal\u0007', keywords: ['rock|roll', 'coffee\r\nnote: x'], prompt: 'hi\ninspiration: other'),
        note: 'nice\n\nfestival: diwali',
      );
      final lines = block.split('\n');
      final keys = [for (final l in lines) l.substring(0, l.indexOf(':'))];
      expect(keys.toSet(), hasLength(keys.length), reason: 'each key at most once');
      expect(lines, contains('recipient: Alex genre: Death Metal'));
      expect(lines, contains('keywords: rock roll | coffee note: x'));
      expect(block.contains('\u0007'), isFalse);
    });

    test('the note is capped at 600 characters', () {
      final block = MusicPromptBlock.build(draft(), note: 'x' * 700);
      expect(block.split('\n').last, 'note: ${'x' * 600}');
    });
  });

  group('the server\'s material rule (§2.3)', () {
    final preflight = MusicPreflight();

    /// The server's `HasBrief` over the block and the request, as it parses them.
    bool serverAccepts(MusicGenerationRequest request) {
      if (request.inspiration != null) return true;
      final keys = {for (final l in request.prompt.split('\n')) l.substring(0, l.indexOf(':')): l.substring(l.indexOf(':') + 1).trim()};
      return (keys['keywords'] ?? '').isNotEmpty ||
          (keys['description'] ?? '').isNotEmpty ||
          (keys['note'] ?? '').isNotEmpty ||
          (request.lyrics ?? '').trim().isNotEmpty ||
          request.images.isNotEmpty;
    }

    test('whatever passes preflight, the server finds material for', () {
      final cases = <MusicCreationDraft>[
        draft(occasion: MusicOccasion.custom, template: null, recipient: '', keywords: [], prompt: 'rain on a tin roof'),
        draft(occasion: MusicOccasion.custom, template: null, keywords: [], prompt: '|||'),
        draft(occasion: MusicOccasion.custom, template: null, keywords: ['|', ' '], prompt: '\u0007'),
        draft(occasion: MusicOccasion.custom, template: null, keywords: []),
        draft(occasion: MusicOccasion.custom, template: null, recipient: '', keywords: [], userLyrics: '[Verse]\nla la')
            .copyWith(lyricsOwnershipConfirmed: true),
        draft(occasion: MusicOccasion.custom, template: null, recipient: '', keywords: [], imageBids: ['b1']),
        draft(inspirationSlug: 'soundscape', template: null, recipient: '', keywords: []),
        draft(recipient: '', keywords: []),
      ];
      for (final d in cases) {
        final checked = preflight.check(d.forSubmit());
        if (!checked.isOk) {
          expect(checked.issues, contains(MusicPreflightIssue.briefMissing), reason: d.prompt);
          continue;
        }
        expect(serverAccepts(MusicGenerationRequest.fromDraft(checked.draft!, clientRef: 'r')), isTrue, reason: 'prompt "${d.prompt}"');
      }
    });

    test('only punctuation the block strips is not a description', () {
      final d = draft(occasion: MusicOccasion.custom, template: null, keywords: [], prompt: '|||');
      expect(preflight.check(d.forSubmit()).issues, [MusicPreflightIssue.briefMissing]);
      expect(MusicPromptBlock.build(d), isNot(contains('description:')));
    });
  });

  group('forSubmit (ADR-0033: only what the composer shows is sent)', () {
    test('free input sends the description, photos and lyrics, not the folded name or words', () {
      final free = draft(occasion: MusicOccasion.custom, template: null, prompt: 'rain', userLyrics: 'la', imageBids: ['b1']);
      final sent = free.forSubmit();
      expect(sent.recipient, isEmpty);
      expect(sent.keywords, isEmpty);
      expect(sent.prompt, 'rain');
      expect(sent.userLyrics, 'la', reason: 'own lyrics are an option of free input too');
      expect(sent.imageBids, ['b1']);
      expect(free.recipient, 'Alex', reason: 'the draft keeps them for the next pick');
    });

    test('a pick sends its fields, not the hidden description or photos', () {
      final picked = draft(inspirationSlug: 'birthday_wish', prompt: 'typed before the pick', imageBids: ['b1']);
      final sent = picked.forSubmit();
      expect(sent.recipient, 'Alex');
      expect(sent.keywords, ['coffee', 'hiking', 'Sunday']);
      expect(sent.prompt, isEmpty);
      expect(sent.imageBids, isEmpty);
      expect(MusicPromptBlock.build(sent), isNot(contains('description:')));
      expect(picked.prompt, 'typed before the pick', reason: 'kept for the way back to free input');
    });

    test("a card that asks for the user's words sends them", () {
      final sent = draft(inspirationSlug: 'text_messages', prompt: 'see you at 8').copyWith(pickInputRequired: true).forSubmit();
      expect(sent.prompt, 'see you at 8');
      expect(MusicPromptBlock.build(sent), contains('description: see you at 8'));
    });

    test('an instrumental takes no lyrics (§2.4)', () {
      final sent = draft(inspirationSlug: 'soundscape', vocals: MusicVocals.instrumental, userLyrics: '[Verse]\nla').forSubmit();
      expect(sent.userLyrics, isNull);
      expect(body(sent).containsKey('lyrics'), isFalse);
    });

    test('a preview makes no automatic video; the full song keeps the switch', () {
      final on = draft().copyWith(autoVideo: MusicAutoVideo.lyric);
      expect(on.forSubmit().autoVideo, MusicAutoVideo.none);
      expect(on.copyWith(model: MusicSongModel.fullSong).forSubmit().autoVideo, MusicAutoVideo.lyric);
      expect(on.autoVideo, MusicAutoVideo.lyric, reason: 'the intent stays for Standard');
    });

    test('sending twice changes nothing', () {
      final once = draft(inspirationSlug: 'birthday_wish', prompt: 'x', imageBids: ['b1']).forSubmit();
      final twice = once.forSubmit();
      expect(MusicPromptBlock.build(twice), MusicPromptBlock.build(once));
      expect(body(twice), body(once));
    });
  });

  group('polish brief', () {
    test('scene, recipient and keywords', () {
      expect(MusicPromptBlock.brief(draft()), 'birthday wish song for Alex: coffee, hiking, Sunday');
    });

    test('without recipient or keywords', () {
      expect(MusicPromptBlock.brief(draft(occasion: MusicOccasion.brand, template: null, recipient: '', keywords: [])), 'brand');
    });
  });
}
