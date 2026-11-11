import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

MusicInspiration inspiration(String slug, int sort) => MusicInspiration(
      id: 'id-$slug',
      slug: slug,
      name: MusicLocalizedText(en: slug, zh: slug),
      style: MusicLocalizedText(en: 'style $slug', zh: slug),
      previewAudioUrl: 'https://cdn.example.com/$slug.mp3',
      sort: sort,
    );

MusicCreationDraft draft({MusicSongTemplate? template, String? slug}) => MusicCreationDraft(
      occasion: MusicOccasion.custom,
      region: RegionPresets.all.first,
      genre: null,
      lyricLanguage: MusicLyricLanguage.en,
      template: template,
      inspirationSlug: slug,
    );

void main() {
  test('without the server list the grid is the built-in templates, in order', () {
    final ideas = buildIdeas(const []);
    expect(ideas.map((i) => i.template), MusicSongTemplate.values);
    expect(ideas.every((i) => i.inspiration == null), isTrue);
  });

  test('with the list the grid is the list alone, by sort', () {
    final ideas = buildIdeas([inspiration('soundscape', 17), inspiration('birthday_wish', 1), inspiration('a', 17)]);
    expect(ideas.map((i) => i.slug), ['birthday_wish', 'a', 'soundscape'], reason: 'ties by slug');
    expect(ideas.every((i) => i.template == null), isTrue, reason: 'one kind of tile, no merge on the client');
    expect(ideas.first.key, 'inspiration:id-birthday_wish');
  });

  test('a server tile is picked by slug, an offline tile by template', () {
    final server = MusicIdea.inspiration(inspiration('team_anthem', 1));
    final offline = const MusicIdea.template(MusicSongTemplate.teamAnthem);
    final pickedServer = draft(template: MusicSongTemplate.teamAnthem, slug: 'team_anthem');
    expect(server.isPickedIn(pickedServer), isTrue);
    expect(offline.isPickedIn(pickedServer), isFalse, reason: 'one pick at a time');
    expect(offline.isPickedIn(draft(template: MusicSongTemplate.teamAnthem)), isTrue);
    expect(server.isPickedIn(draft()), isFalse);
    expect(server.isPickedIn(null), isFalse);
  });
}
