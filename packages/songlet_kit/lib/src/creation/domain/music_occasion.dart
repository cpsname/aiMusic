/// MusicOccasion templates (PRD F01): each maps to a fixed server-side prompt
/// skeleton (PRD §7.2); the wire value is the `occasion` field of
/// `/v1/generate`.
enum MusicOccasion {
  birthday('birthday'),
  anniversary('anniversary'),
  confession('confession'),
  wedding('wedding'),
  memorial('memorial'),
  festival('festival'),
  brand('brand'),
  soundtrack('soundtrack'),

  /// Free-form song from the composer's prompt, no template (ADR-0015); the
  /// server uses its generic skeleton.
  custom('custom');

  const MusicOccasion(this.wire);

  final String wire;

  static MusicOccasion fromWire(String value) => MusicOccasion.values.firstWhere(
        (o) => o.wire == value,
        orElse: () => MusicOccasion.birthday,
      );

  /// Brand jingles and video soundtracks are often instrumental or slogan-only,
  /// so the recipient name is optional there (PRD §3 "小商家"); a free-form
  /// prompt names whoever it wants.
  bool get requiresRecipient =>
      this != brand && this != soundtrack && this != custom;

  /// Whether "also make a video" starts on when a card of this occasion is
  /// picked and the server says nothing (`default_on_video` absent; docs/ui
  /// P28, ADR-0022): songs made to be posted — soundtracks, brand and team
  /// songs, festivals.
  bool get videoByDefault => this == soundtrack || this == brand || this == festival;

  /// The eight PRD F01 occasions (the festival page's cards, docs/ui P16).
  static const List<MusicOccasion> templates = [
    birthday,
    anniversary,
    confession,
    wedding,
    memorial,
    festival,
    brand,
    soundtrack,
  ];
}

/// MusicFestival templates shown under [MusicOccasion.festival] (PRD §11.3: "节日模板按国家
/// 显示"). [regions] empty = offered everywhere; [uiLanguages] restricts a
/// festival to UI languages (Lunar New Year for zh interfaces).
enum MusicFestival {
  newYear('new_year', regions: {}),
  thanksgiving('thanksgiving', regions: {'US', 'CA'}),
  diwali('diwali', regions: {'IN'}),
  carnival('carnival', regions: {'BR'}),
  eid('eid', regions: {'ID', 'TR'}),
  lunarNewYear('lunar_new_year', regions: {}, uiLanguages: {'zh'});

  const MusicFestival(this.wire, {required this.regions, this.uiLanguages = const {}});

  final String wire;
  final Set<String> regions;
  final Set<String> uiLanguages;

  static MusicFestival? fromWire(String? value) {
    for (final festival in MusicFestival.values) {
      if (festival.wire == value) return festival;
    }
    return null;
  }

  /// Festivals to offer for a preset [region] and the UI [languageCode].
  static List<MusicFestival> available({
    required String region,
    required String languageCode,
  }) =>
      MusicFestival.values.where((f) {
        if (f.uiLanguages.isNotEmpty) {
          return f.uiLanguages.contains(languageCode);
        }
        return f.regions.isEmpty || f.regions.contains(region);
      }).toList(growable: false);
}
