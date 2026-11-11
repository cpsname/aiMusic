/// What to generate: the 30-second clip (lyria-3-clip-preview) or the
/// ≈2-minute full song (lyria-3.5) — PRD F05 / F06. Both cost credits.
enum MusicSongModel {
  clip('lyria-3-clip-preview'),
  fullSong('lyria-3.5');

  const MusicSongModel(this.wire);

  final String wire;

  static MusicSongModel fromWire(String value) =>
      value == fullSong.wire ? fullSong : clip;

  /// The model for a wire value, or null when it is not one of the two.
  static MusicSongModel? tryFromWire(String? value) {
    for (final model in values) {
      if (model.wire == value) return model;
    }
    return null;
  }
}

/// Vocal treatment (docs/ui P02b; ADR-0015).
enum MusicVocals {
  /// Let the prompt decide.
  custom('custom'),

  /// Sung lyrics.
  vocals('vocals'),

  /// No voice: the prompt drops the lyric section, the player hides lyrics.
  instrumental('instrumental');

  const MusicVocals(this.wire);

  final String wire;

  static MusicVocals fromWire(String? value) => MusicVocals.values.firstWhere(
        (v) => v.wire == value,
        orElse: () => MusicVocals.vocals,
      );
}

/// A music video made automatically once the song is ready (docs/ui P28,
/// ADR-0022): the length panel's "also make a video" toggle. Stored with the
/// work so the coordinator can still start it after a restart; never synced
/// (it is an intent of this device, not part of the song).
enum MusicAutoVideo {
  /// No automatic video.
  none('none'),

  /// The free lyric video (L2).
  lyric('lyric'),

  /// The chorus video (L3) — Premier's "song + chorus MV" bundle.
  chorus('chorus');

  const MusicAutoVideo(this.wire);

  final String wire;

  bool get isOn => this != none;

  static MusicAutoVideo fromWire(String? value) => MusicAutoVideo.values.firstWhere(
        (v) => v.wire == value,
        orElse: () => MusicAutoVideo.none,
      );
}
