/// Public-lyrics fingerprint index (PRD §7.4 / §9.1): user lyrics whose word
/// 3-gram shingles are > 80 % contained in a known song's shingles are blocked
/// before submission ('请原创').
///
/// Only shingle **hashes** are compared, so the production index (hashes
/// shipped by the backend config) never needs lyrics text on device. The
/// bundled seed covers public-domain songs.
class MusicLyricsFingerprintIndex {
  MusicLyricsFingerprintIndex(Iterable<Set<int>> fingerprints)
      : _fingerprints = List.unmodifiable(fingerprints);

  factory MusicLyricsFingerprintIndex.publicDomain() =>
      MusicLyricsFingerprintIndex(_publicDomainSongs.map(fingerprint));

  /// Minimum shingles before a comparison is meaningful (short lyrics like
  /// 'happy birthday Alex' must not be flagged).
  static const int minShingles = 6;

  final List<Set<int>> _fingerprints;

  /// Highest containment of [lyrics]' shingles in any indexed song, 0..1.
  double maxSimilarity(String lyrics) {
    final shingles = fingerprint(lyrics);
    if (shingles.length < minShingles) return 0;
    var best = 0.0;
    for (final song in _fingerprints) {
      final shared = shingles.where(song.contains).length;
      final score = shared / shingles.length;
      if (score > best) best = score;
    }
    return best;
  }

  /// FNV-1a 32-bit hashes of normalized word 3-grams.
  static Set<int> fingerprint(String text) {
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r"[^\p{L}\p{N}']+", unicode: true), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList(growable: false);
    final result = <int>{};
    for (var i = 0; i + 2 < words.length; i++) {
      result.add(_fnv1a('${words[i]} ${words[i + 1]} ${words[i + 2]}'));
    }
    return result;
  }

  static int _fnv1a(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  static const List<String> _publicDomainSongs = [
    'happy birthday to you happy birthday to you happy birthday dear friend '
        'happy birthday to you',
    'twinkle twinkle little star how I wonder what you are up above the world '
        'so high like a diamond in the sky',
    'dashing through the snow in a one horse open sleigh over the fields we go '
        'laughing all the way bells on bobtail ring making spirits bright what '
        'fun it is to ride and sing a sleighing song tonight jingle bells '
        'jingle bells jingle all the way',
    'should auld acquaintance be forgot and never brought to mind should auld '
        'acquaintance be forgot and auld lang syne for auld lang syne my dear '
        "for auld lang syne we'll take a cup of kindness yet for auld lang syne",
    'amazing grace how sweet the sound that saved a wretch like me I once was '
        'lost but now am found was blind but now I see',
    'silent night holy night all is calm all is bright round yon virgin mother '
        'and child holy infant so tender and mild sleep in heavenly peace',
    'row row row your boat gently down the stream merrily merrily merrily '
        'merrily life is but a dream',
    'mary had a little lamb its fleece was white as snow and everywhere that '
        'mary went the lamb was sure to go',
  ];
}
