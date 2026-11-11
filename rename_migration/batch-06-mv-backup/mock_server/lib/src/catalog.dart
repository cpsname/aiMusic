/// Static Songlet business tables (PRD §7.3, §8.1–8.3, contract §3/§5).
library;

enum ProductKind { subscription, pack, mvPack }

enum SubscriptionPlan { proMonthly, proYearly, premierMonthly }

class ProductSpec {
  const ProductSpec.subscription(this.id, this.plan, this.rank)
    : kind = ProductKind.subscription,
      packSongs = 0,
      credits = 0;

  const ProductSpec.pack(this.id, this.packSongs)
    : kind = ProductKind.pack,
      plan = null,
      rank = 0,
      credits = 0;

  /// A music-video credit pack (contract v1.1 §5; platform 20260928e).
  const ProductSpec.mvPack(this.id, this.credits)
    : kind = ProductKind.mvPack,
      plan = null,
      rank = 0,
      packSongs = 0;

  final String id;
  final ProductKind kind;
  final SubscriptionPlan? plan;

  /// Higher wins when several subscriptions are active at once.
  final int rank;
  final int packSongs;

  /// Credits granted by an MV pack (never expire).
  final int credits;

  bool get isYearly => plan == SubscriptionPlan.proYearly;

  String get tier => switch (plan) {
    SubscriptionPlan.premierMonthly => 'premier',
    SubscriptionPlan.proMonthly || SubscriptionPlan.proYearly => 'pro',
    null => 'pack',
  };

  /// Monthly allowance `(songs, clips)` for [storefront] (ISO alpha-3).
  ({int songs, int clips}) allowance(String? storefront) => switch (plan) {
    SubscriptionPlan.premierMonthly => (songs: 120, clips: 200),
    SubscriptionPlan.proMonthly || SubscriptionPlan.proYearly =>
      Catalog.isReducedTierStorefront(storefront)
          ? (songs: 25, clips: 60)
          : (songs: 40, clips: 100),
    null => (songs: 0, clips: 0),
  };
}

abstract final class Catalog {
  static const String clipModel = 'lyria-3-clip-preview';
  static const String songModel = 'lyria-3.5';
  static const Set<String> models = {clipModel, songModel};

  static const Set<String> occasions = {
    'birthday',
    'anniversary',
    'confession',
    'wedding',
    'memorial',
    'festival',
    'brand',
    'soundtrack',
    // A composer prompt without a template (ADR-0015).
    'custom',
  };

  /// Create-home templates (docs/ui P01; contract `template`, ADR-0008).
  static const List<String> templates = [
    'birthday_wish', 'birthday_party', 'love_story', 'thank_a_friend', //
    'party_invite', 'wedding', 'in_memory', 'festival', 'ringtone',
    'team_anthem', 'sports_recap', 'rap_battle', 'comedy', 'pet_anthem',
    'hometown', 'business_promo',
  ];

  /// PRD §7.3 launch presets (ISO alpha-2).
  static const Set<String> presetRegions = {
    'US', 'GB', 'CA', 'AU', 'DE', 'FR', 'JP', //
    'KR', 'BR', 'MX', 'IN', 'ID', 'VN', 'TR',
  };

  /// Gemini API unavailable / sanctioned regions, alpha-2 and alpha-3 forms.
  static const Set<String> unsupportedRegions = {
    'CN', 'CHN', 'HK', 'HKG', 'MO', 'MAC', 'RU', 'RUS', 'BY', 'BLR', //
    'IR', 'IRN', 'KP', 'PRK', 'SY', 'SYR', 'CU', 'CUB',
  };

  /// T2 (BRA MEX IDN VNM TUR) and T3 (IND) storefronts get the reduced Pro
  /// allowance (25 songs + 60 clips).
  static const Set<String> reducedTierStorefronts = {
    'BRA', 'MEX', 'IDN', 'VNM', 'TUR', 'IND', //
  };

  static bool isReducedTierStorefront(String? storefront) =>
      storefront != null &&
      reducedTierStorefronts.contains(storefront.toUpperCase());

  /// Yearly free-trial cap on full songs (PRD §8.2, anti-abuse).
  static const int trialSongCap = 10;

  /// Lifetime free clips per account (PRD §8.2).
  static const int freeLifetimeClips = 3;

  // ── Music videos (contract v1.1, PRD ch.15; platform 20260928d/e) ──

  /// The free monthly credit pocket every account has (66 = 3 clips), also
  /// the only credits a never-paid account can spend on a music video.
  static const int freeCredits = 66;

  /// Platform prices of a clip / full song and the pack recommended for
  /// songs (`QuotaExhaustedDetails` on `/v1/generate`).
  static const int clipCredits = 22;
  static const int songCredits = 49;
  static const String songPack = 'com.songlet.pack.10';

  static const String mvChorusPack = 'com.songlet.mv.chorus';
  static const String mvFullPack = 'com.songlet.mv.full';

  /// Price of one chorus video (per request).
  static const int chorusMvCredits = 2169;

  /// Full-song video: per second of song, with the platform's minimum.
  static const int fullMvCreditsPerSecond = 69;
  static const int fullMvMinCredits = 4140;

  /// Songs longer than this cannot become a full video (12 × 15 s + 10 s).
  static const int mvMaxSongMs = 190000;

  /// Credits for [level] on a song of [songSeconds].
  static int mvCredits(String level, int songSeconds) => switch (level) {
    'lyric_video' => 0,
    'chorus_mv' => chorusMvCredits,
    _ => fullMvCreditsPerSecond * songSeconds < fullMvMinCredits
        ? fullMvMinCredits
        : fullMvCreditsPerSecond * songSeconds,
  };

  /// The pack the platform recommends for [level]; none for the free level.
  static String? mvPackFor(String level) => switch (level) {
    'chorus_mv' => mvChorusPack,
    'full_mv' => mvFullPack,
    _ => null,
  };

  static const Set<String> mvLevels = {'lyric_video', 'chorus_mv', 'full_mv'};
  static const Set<String> mvAspectRatios = {'9:16', '16:9', '1:1'};
  static const Set<String> mvQualities = {'standard', 'high'};
  static const int mvMaxPhotos = 10;
  static const int mvMinChorusWindowMs = 4000;
  static const int mvMaxChorusWindowMs = 60000;

  static const Map<String, ProductSpec> products = {
    'com.songlet.pro.monthly': ProductSpec.subscription(
      'com.songlet.pro.monthly',
      SubscriptionPlan.proMonthly,
      1,
    ),
    'com.songlet.pro.yearly': ProductSpec.subscription(
      'com.songlet.pro.yearly',
      SubscriptionPlan.proYearly,
      1,
    ),
    'com.songlet.premier.monthly': ProductSpec.subscription(
      'com.songlet.premier.monthly',
      SubscriptionPlan.premierMonthly,
      2,
    ),
    'com.songlet.pack.10': ProductSpec.pack('com.songlet.pack.10', 10),
    'com.songlet.pack.50': ProductSpec.pack('com.songlet.pack.50', 50),
    mvChorusPack: ProductSpec.mvPack(mvChorusPack, 2395),
    mvFullPack: ProductSpec.mvPack(mvFullPack, 12779),
  };
}

/// Adds [months] calendar months to a UTC instant, clamping the day of month
/// (Jan 31 + 1 month → Feb 28/29), like App Store monthly billing.
DateTime addMonths(DateTime from, int months) {
  final utc = from.toUtc();
  final totalMonths = utc.year * 12 + (utc.month - 1) + months;
  final year = totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  final lastDay = DateTime.utc(year, month + 1, 0).day;
  final day = utc.day > lastDay ? lastDay : utc.day;
  return DateTime.utc(
    year,
    month,
    day,
    utc.hour,
    utc.minute,
    utc.second,
    utc.millisecond,
  );
}
