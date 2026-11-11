import 'package:commerce_kit/commerce_kit.dart';
import 'package:meta/meta.dart';

/// App Store pricing tier of a storefront (PRD §8.3).
enum PricingTier { t1, t2, t3 }

/// Monthly allowance of a plan (PRD §8.1 / §8.3) — "songs a month", never
/// "credits" (PRD §8.5 / App Review 3.1.1).
@immutable
class Allowance {
  const Allowance({required this.songs, required this.clips});

  final int songs;
  final int clips;
}

/// The Songlet product catalog (PRD §8.1) — fixed product ids, fed to
/// commerce_kit as its backend catalog (Songlet has no `/app/init`; the store
/// stays authoritative for names and prices).
abstract final class SongletCatalog {
  /// Weekly Pro (contract 02 v2.1): the subscription the paywall recommends,
  /// with the App Store's introductory offer (50 % off the first week) read
  /// from StoreKit, never typed here.
  static const String proWeekly = 'com.songlet.pro.weekly';
  static const String proMonthly = 'com.songlet.pro.monthly';
  static const String proYearly = 'com.songlet.pro.yearly';
  static const String premierMonthly = 'com.songlet.premier.monthly';
  static const String pack10 = 'com.songlet.pack.10';
  static const String pack50 = 'com.songlet.pack.50';

  /// Music-video credit packs (PRD ch.15; platform 20260928e). Consumable,
  /// never expire; the one a `QUOTA_EXHAUSTED` recommends for its level.
  static const String mvChorusPack = 'com.songlet.mv.chorus';
  static const String mvFullPack = 'com.songlet.mv.full';

  static const List<String> subscriptionIds = [proWeekly, proYearly, proMonthly, premierMonthly];

  /// The subscription a credit paywall preselects when nothing else is
  /// recommended.
  static const String recommendedSubscription = proWeekly;
  static const List<String> packIds = [pack10, pack50];
  static const List<String> mvPackIds = [mvChorusPack, mvFullPack];
  static const List<String> allIds = [...subscriptionIds, ...packIds, ...mvPackIds];

  /// Full-song cap during the Pro yearly free trial (PRD §8.2).
  static const int trialSongCap = 10;

  /// Songs per pack product (never expire).
  static int packSongs(String productId) => switch (productId) {
        pack10 => 10,
        pack50 => 50,
        _ => 0,
      };

  static bool isSubscription(String productId) =>
      subscriptionIds.contains(productId);

  static bool isMvPack(String productId) => mvPackIds.contains(productId);

  /// Credits an MV pack grants in a pricing tier (platform
  /// `grant_config.quota_amount`, PRD §15.4: price × 0.85 ÷ 0.036, T2/T3 in
  /// proportion to the local price). In T1 enough for one video of its
  /// level; in T2/T3 one purchase may not cover it (the quota sheet says so).
  /// A hint only — the ledger is the server's.
  static int mvPackCredits(String productId, [PricingTier tier = PricingTier.t1]) => switch ((productId, tier)) {
        (mvChorusPack, PricingTier.t1) => 2395,
        (mvChorusPack, PricingTier.t2) => 1196,
        (mvChorusPack, PricingTier.t3) => 1139,
        (mvFullPack, PricingTier.t1) => 12779,
        (mvFullPack, PricingTier.t2) => 6384,
        (mvFullPack, PricingTier.t3) => 6077,
        _ => 0,
      };

  static bool isPremier(String productId) => productId == premierMonthly;

  /// Weekly Pro renews on credits, not on a monthly songs allowance.
  static bool isWeekly(String productId) => productId == proWeekly;

  /// Monthly allowance for a subscription in a pricing tier: Pro drops to
  /// 25 songs + 60 clips in T2/T3 (PRD §8.3); Premier is 120 + 200.
  static Allowance allowance(String productId, PricingTier tier) {
    if (isPremier(productId)) return const Allowance(songs: 120, clips: 200);
    return tier == PricingTier.t1
        ? const Allowance(songs: 40, clips: 100)
        : const Allowance(songs: 25, clips: 60);
  }

  /// Pricing tier of an App Store storefront (ISO alpha-3), T1 by default.
  static PricingTier tierForStorefront(String? alpha3) =>
      switch (alpha3?.toUpperCase()) {
        'IND' => PricingTier.t3,
        'BRA' || 'MEX' || 'IDN' || 'VNM' || 'TUR' => PricingTier.t2,
        _ => PricingTier.t1,
      };

  /// The catalog as commerce_kit [Product]s, in paywall display order.
  static List<Product> products() => const [
        Product(
          productCode: proWeekly,
          storeProductId: proWeekly,
          productName: 'Pro Weekly',
          kind: ProductKind.autoRenewable,
          // Catalog placeholder: the displayed price is the store's.
          priceCents: 499,
          currency: 'USD',
          billingCycle: 'weekly',
          subscriptionGroup: 'songlet',
          sortOrder: -1,
        ),
        Product(
          productCode: proYearly,
          storeProductId: proYearly,
          productName: 'Pro Yearly',
          kind: ProductKind.autoRenewable,
          priceCents: 5999,
          currency: 'USD',
          billingCycle: 'annual',
          trialDays: 7,
          subscriptionGroup: 'songlet',
          highlightTag: 'best_value',
        ),
        Product(
          productCode: proMonthly,
          storeProductId: proMonthly,
          productName: 'Pro Monthly',
          kind: ProductKind.autoRenewable,
          priceCents: 999,
          currency: 'USD',
          billingCycle: 'monthly',
          subscriptionGroup: 'songlet',
          sortOrder: 1,
        ),
        Product(
          productCode: premierMonthly,
          storeProductId: premierMonthly,
          productName: 'Premier Monthly',
          kind: ProductKind.autoRenewable,
          priceCents: 2499,
          currency: 'USD',
          billingCycle: 'monthly',
          subscriptionGroup: 'songlet',
          sortOrder: 2,
        ),
        Product(
          productCode: pack10,
          storeProductId: pack10,
          productName: '10 Songs',
          kind: ProductKind.consumable,
          priceCents: 499,
          currency: 'USD',
          sortOrder: 3,
        ),
        Product(
          productCode: pack50,
          storeProductId: pack50,
          productName: '50 Songs',
          kind: ProductKind.consumable,
          priceCents: 1999,
          currency: 'USD',
          sortOrder: 4,
        ),
        Product(
          productCode: mvChorusPack,
          storeProductId: mvChorusPack,
          productName: 'Chorus music video',
          kind: ProductKind.consumable,
          priceCents: 1499,
          currency: 'USD',
          sortOrder: 5,
        ),
        Product(
          productCode: mvFullPack,
          storeProductId: mvFullPack,
          productName: 'Full-song music video',
          kind: ProductKind.consumable,
          priceCents: 7999,
          currency: 'USD',
          sortOrder: 6,
        ),
      ];
}
