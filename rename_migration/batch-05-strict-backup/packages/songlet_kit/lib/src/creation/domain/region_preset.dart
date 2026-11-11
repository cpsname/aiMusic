import 'package:meta/meta.dart';

import '../../store/domain/music_catalog.dart';

/// A lyric language the preset can sing in (Lyria writes lyrics in the language
/// of the prompt — PRD §2.2 / §7.2). [code] is a BCP-47 tag.
enum LyricLanguage {
  en('en'),
  fr('fr'),
  de('de'),
  ja('ja'),
  ko('ko'),
  ptBR('pt-BR'),
  esMX('es-MX'),
  hi('hi'),
  id('id'),
  vi('vi'),
  tr('tr'),
  zhHans('zh-Hans'),
  zhHant('zh-Hant');

  const LyricLanguage(this.code);

  final String code;

  /// The base language subtag (`pt-BR` → `pt`).
  String get baseCode => code.split('-').first;

  bool get isCjk => this == ja || this == ko || this == zhHans || this == zhHant;

  static LyricLanguage? fromCode(String? code) {
    if (code == null) return null;
    for (final language in LyricLanguage.values) {
      if (language.code.toLowerCase() == code.toLowerCase()) return language;
    }
    return null;
  }

  /// Best match for a device locale (`pt_PT` → ptBR, `es_ES` → esMX,
  /// `zh_TW` / `zh-Hant` → zhHant).
  static LyricLanguage? forLocale(String languageCode, {String? scriptCode, String? countryCode}) {
    final lang = languageCode.toLowerCase();
    if (lang == 'zh') {
      final traditional = scriptCode?.toLowerCase() == 'hant' ||
          const {'TW', 'HK', 'MO'}.contains(countryCode?.toUpperCase());
      return traditional ? zhHant : zhHans;
    }
    for (final language in LyricLanguage.values) {
      if (language.baseCode == lang) return language;
    }
    return null;
  }
}

/// A launch-country preset (PRD F02 / §7.3): lyric language(s), three local
/// genres and the default instruments the backend folds into the prompt.
@immutable
class RegionPreset {
  const RegionPreset({
    required this.code,
    required this.alpha3,
    required this.flag,
    required this.languages,
    required this.genres,
    required this.instruments,
    required this.wave,
  });

  /// ISO 3166-1 alpha-2 — the `region` field of `/v1/generate`.
  final String code;

  /// ISO 3166-1 alpha-3, as StoreKit reports storefronts.
  final String alpha3;
  final String flag;
  final List<LyricLanguage> languages;

  /// Exactly three genres, in the PRD §7.3 order (vocabulary from the Lyria
  /// prompt guide, so they stay in English on every UI language).
  final List<String> genres;
  final String instruments;

  /// Launch wave (PRD §11.1): 1 = launch day, 2 = +4 weeks.
  final int wave;

  PricingTier get pricingTier => MusicCatalog.tierForStorefront(alpha3);

  LyricLanguage get primaryLanguage => languages.first;
}

/// The 14 launch presets (PRD §7.3), wave 1 first (PRD §11.1).
abstract final class RegionPresets {
  static const List<RegionPreset> all = [
    RegionPreset(
      code: 'US', alpha3: 'USA', flag: '🇺🇸', wave: 1,
      languages: [LyricLanguage.en],
      genres: ['Indie Pop', 'Contemporary R&B', 'Alternative Country'],
      instruments: 'Warm Acoustic Guitar, Rhodes Piano',
    ),
    RegionPreset(
      code: 'GB', alpha3: 'GBR', flag: '🇬🇧', wave: 1,
      languages: [LyricLanguage.en],
      genres: ['Indie Pop', 'Garage Rock', 'Grime'],
      instruments: 'Guitar, Synth Pads',
    ),
    RegionPreset(
      code: 'CA', alpha3: 'CAN', flag: '🇨🇦', wave: 1,
      languages: [LyricLanguage.en, LyricLanguage.fr],
      genres: ['Indie Folk', 'Synthpop', 'Piano Ballad'],
      instruments: 'Warm Acoustic Guitar',
    ),
    RegionPreset(
      code: 'AU', alpha3: 'AUS', flag: '🇦🇺', wave: 1,
      languages: [LyricLanguage.en],
      genres: ['Indie Pop', 'Surf Rock', 'Deep House'],
      instruments: 'Guitar',
    ),
    RegionPreset(
      code: 'DE', alpha3: 'DEU', flag: '🇩🇪', wave: 1,
      languages: [LyricLanguage.de],
      genres: ['Synthpop', 'Minimal Techno', 'Piano Ballad'],
      instruments: 'Synth Pads, Moog Oscillations',
    ),
    RegionPreset(
      code: 'FR', alpha3: 'FRA', flag: '🇫🇷', wave: 1,
      languages: [LyricLanguage.fr],
      genres: ['1960s French Yé-yé Pop', 'Chillout', 'Piano Ballad'],
      instruments: 'Smooth Pianos',
    ),
    RegionPreset(
      code: 'JP', alpha3: 'JPN', flag: '🇯🇵', wave: 1,
      languages: [LyricLanguage.ja],
      genres: ['J-pop Indie Pop', 'Piano Ballad', 'Chiptune'],
      instruments: 'Koto accents, Smooth Pianos',
    ),
    RegionPreset(
      code: 'KR', alpha3: 'KOR', flag: '🇰🇷', wave: 2,
      languages: [LyricLanguage.ko],
      genres: ['Synthpop', 'Contemporary R&B', 'Piano Ballad'],
      instruments: 'Synth Pads',
    ),
    RegionPreset(
      code: 'BR', alpha3: 'BRA', flag: '🇧🇷', wave: 2,
      languages: [LyricLanguage.ptBR],
      genres: ['Bossa Nova', 'Disco Funk', 'Reggaeton'],
      instruments: 'Warm Acoustic Guitar, Conga Drums',
    ),
    RegionPreset(
      code: 'MX', alpha3: 'MEX', flag: '🇲🇽', wave: 2,
      languages: [LyricLanguage.esMX],
      genres: ['Cumbia', 'Reggaeton', 'Latin Jazz'],
      instruments: 'Guitar, Trumpet, Maracas',
    ),
    RegionPreset(
      code: 'IN', alpha3: 'IND', flag: '🇮🇳', wave: 2,
      languages: [LyricLanguage.hi, LyricLanguage.en],
      genres: ['Bhangra', 'Indian Classical', 'Indie Pop'],
      instruments: 'Tabla, Sitar',
    ),
    RegionPreset(
      code: 'ID', alpha3: 'IDN', flag: '🇮🇩', wave: 2,
      languages: [LyricLanguage.id],
      genres: ['Indie Pop', 'Piano Ballad', 'Reggae'],
      instruments: 'Warm Acoustic Guitar',
    ),
    RegionPreset(
      code: 'VN', alpha3: 'VNM', flag: '🇻🇳', wave: 2,
      languages: [LyricLanguage.vi],
      genres: ['Piano Ballad', 'Indie Pop', 'Lo-Fi Hip Hop'],
      instruments: 'Smooth Pianos',
    ),
    RegionPreset(
      code: 'TR', alpha3: 'TUR', flag: '🇹🇷', wave: 2,
      languages: [LyricLanguage.tr],
      genres: ['Indie Pop', 'Piano Ballad', 'Deep House'],
      instruments: 'Guitar, Bouzouki',
    ),
  ];

  static RegionPreset? byCode(String? code) {
    if (code == null) return null;
    final upper = code.toUpperCase();
    for (final preset in all) {
      if (preset.code == upper || preset.alpha3 == upper) return preset;
    }
    return null;
  }

  /// The default preset: the App Store storefront country (PRD §11.3 "地区预设
  /// 跟随 App Store 国家"), else the device region, else the United States.
  static RegionPreset defaultFor({String? storefrontAlpha3, String? deviceRegion}) =>
      byCode(storefrontAlpha3) ?? byCode(deviceRegion) ?? all.first;
}
