/// The 18 genres offered in every region (docs/ui P02c; ADR-0005). Labels are
/// Lyria prompt vocabulary, so they stay in English on every UI language, like
/// the region preset genres (PRD §7.3).
enum Genre {
  pop('Pop'),
  hipHop('Hip-Hop & Rap'),
  rock('Rock'),
  kPop('K-Pop'),
  latin('Latin'),
  electronic('Electronic'),
  rnb('R&B'),
  country('Country'),
  afrobeats('Afrobeats'),
  reggae('Reggae'),
  jazzBlues('Jazz & Blues'),
  classical('Classical'),
  folk('Folk'),
  lofi('Lo-Fi'),
  acoustic('Acoustic'),
  cinematic('Cinematic'),
  ambient('Ambient'),
  bossaNova('Bossa Nova');

  const Genre(this.label);

  /// The `genre` value sent in the prompt block.
  final String label;

  static Genre? fromLabel(String? label) {
    for (final genre in Genre.values) {
      if (genre.label == label) return genre;
    }
    return null;
  }
}
