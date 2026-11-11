import 'music_genre.dart';
import 'music_occasion.dart';

/// The 16 create-home templates (docs/ui P01). Each maps to one PRD F01
/// occasion — the server-side prompt skeleton and ledger category — and may
/// refine it with a genre hint and whether a recipient is expected (ADR-0008).
/// [id] travels as `template` on `/v1/generate` so the server can specialise
/// the skeleton; an unknown id falls back to the occasion's.
enum MusicSongTemplate {
  birthdayWish('birthday_wish', MusicOccasion.birthday),
  birthdayParty('birthday_party', MusicOccasion.birthday),
  loveStory('love_story', MusicOccasion.anniversary),
  thankAFriend('thank_a_friend', MusicOccasion.confession),
  partyInvite('party_invite', MusicOccasion.festival, recipient: false),
  wedding('wedding', MusicOccasion.wedding),
  inMemory('in_memory', MusicOccasion.memorial),
  festival('festival', MusicOccasion.festival, recipient: false),
  ringtone('ringtone', MusicOccasion.soundtrack, recipient: false),
  teamAnthem('team_anthem', MusicOccasion.brand, recipient: false, genre: MusicGenre.rock),
  sportsRecap('sports_recap', MusicOccasion.soundtrack, recipient: false, genre: MusicGenre.cinematic),
  rapBattle('rap_battle', MusicOccasion.confession, genre: MusicGenre.hipHop),
  comedy('comedy', MusicOccasion.soundtrack, recipient: false),
  petAnthem('pet_anthem', MusicOccasion.confession),
  hometown('hometown', MusicOccasion.brand, recipient: false, genre: MusicGenre.folk),
  businessPromo('business_promo', MusicOccasion.brand, recipient: false);

  const MusicSongTemplate(
    this.id,
    this.occasion, {
    bool recipient = true,
    this.genre,
  }) : requiresRecipient = recipient;

  final String id;
  final MusicOccasion occasion;

  /// Whether the form asks for a name (a person, pet or team).
  final bool requiresRecipient;

  /// MusicGenre suggested when the template is picked; null keeps the region's.
  final MusicGenre? genre;

  /// Whether the length panel's "also make a lyric video" starts on
  /// (docs/ui P28, ADR-0022): the occasion's rule.
  bool get videoByDefault => occasion.videoByDefault;

  /// Asset key of the tile art (`assets/templates/<id>.jpg`, ADR-0014).
  String get artKey => id;

  /// The template an occasion card opens (docs/ui P16 lists the eight PRD
  /// occasions; each starts its most typical template).
  static MusicSongTemplate primaryFor(MusicOccasion occasion) => switch (occasion) {
        MusicOccasion.birthday => birthdayWish,
        MusicOccasion.anniversary => loveStory,
        MusicOccasion.confession => thankAFriend,
        MusicOccasion.wedding => wedding,
        MusicOccasion.memorial => inMemory,
        MusicOccasion.festival || MusicOccasion.custom => festival,
        MusicOccasion.brand => businessPromo,
        MusicOccasion.soundtrack => sportsRecap,
      };

  static MusicSongTemplate? fromId(String? id) {
    for (final template in MusicSongTemplate.values) {
      if (template.id == id) return template;
    }
    return null;
  }
}
