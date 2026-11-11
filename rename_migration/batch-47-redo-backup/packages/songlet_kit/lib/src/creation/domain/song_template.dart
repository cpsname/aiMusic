import 'genre.dart';
import 'occasion.dart';

/// The 16 create-home templates (docs/ui P01). Each maps to one PRD F01
/// occasion — the server-side prompt skeleton and ledger category — and may
/// refine it with a genre hint and whether a recipient is expected (ADR-0008).
/// [id] travels as `template` on `/v1/generate` so the server can specialise
/// the skeleton; an unknown id falls back to the occasion's.
enum SongTemplate {
  birthdayWish('birthday_wish', Occasion.birthday),
  birthdayParty('birthday_party', Occasion.birthday),
  loveStory('love_story', Occasion.anniversary),
  thankAFriend('thank_a_friend', Occasion.confession),
  partyInvite('party_invite', Occasion.festival, recipient: false),
  wedding('wedding', Occasion.wedding),
  inMemory('in_memory', Occasion.memorial),
  festival('festival', Occasion.festival, recipient: false),
  ringtone('ringtone', Occasion.soundtrack, recipient: false),
  teamAnthem('team_anthem', Occasion.brand, recipient: false, genre: Genre.rock),
  sportsRecap('sports_recap', Occasion.soundtrack, recipient: false, genre: Genre.cinematic),
  rapBattle('rap_battle', Occasion.confession, genre: Genre.hipHop),
  comedy('comedy', Occasion.soundtrack, recipient: false),
  petAnthem('pet_anthem', Occasion.confession),
  hometown('hometown', Occasion.brand, recipient: false, genre: Genre.folk),
  businessPromo('business_promo', Occasion.brand, recipient: false);

  const SongTemplate(
    this.id,
    this.occasion, {
    bool recipient = true,
    this.genre,
  }) : requiresRecipient = recipient;

  final String id;
  final Occasion occasion;

  /// Whether the form asks for a name (a person, pet or team).
  final bool requiresRecipient;

  /// Genre suggested when the template is picked; null keeps the region's.
  final Genre? genre;

  /// Whether the length panel's "also make a lyric video" starts on
  /// (docs/ui P28, ADR-0022): the occasion's rule.
  bool get videoByDefault => occasion.videoByDefault;

  /// Asset key of the tile art (`assets/templates/<id>.jpg`, ADR-0014).
  String get artKey => id;

  /// The template an occasion card opens (docs/ui P16 lists the eight PRD
  /// occasions; each starts its most typical template).
  static SongTemplate primaryFor(Occasion occasion) => switch (occasion) {
        Occasion.birthday => birthdayWish,
        Occasion.anniversary => loveStory,
        Occasion.confession => thankAFriend,
        Occasion.wedding => wedding,
        Occasion.memorial => inMemory,
        Occasion.festival || Occasion.custom => festival,
        Occasion.brand => businessPromo,
        Occasion.soundtrack => sportsRecap,
      };

  static SongTemplate? fromId(String? id) {
    for (final template in SongTemplate.values) {
      if (template.id == id) return template;
    }
    return null;
  }
}
