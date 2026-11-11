import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

void main() {
  group('Weekly Pro (contract 02 v2.1)', () {
    test('is the recommended subscription and leads the catalog', () {
      expect(SongletCatalog.proWeekly, 'com.songlet.pro.weekly');
      expect(SongletCatalog.recommendedSubscription, SongletCatalog.proWeekly);
      expect(SongletCatalog.subscriptionIds.first, SongletCatalog.proWeekly);
      expect(SongletCatalog.isSubscription(SongletCatalog.proWeekly), isTrue);
      expect(SongletCatalog.isWeekly(SongletCatalog.proWeekly), isTrue);
      expect(SongletCatalog.isWeekly(SongletCatalog.proMonthly), isFalse);
      final weekly = SongletCatalog.products().firstWhere((p) => p.storeProductId == SongletCatalog.proWeekly);
      expect(weekly.billingCycle, 'weekly');
      expect(weekly.isSubscription, isTrue);
      expect(weekly.sortOrder, -1, reason: 'first, wherever the list is sorted');
    });

    test('has no first-week discount of its own: the App Store\'s introductory offer is read, never typed', () {
      final weekly = SongletCatalog.products().firstWhere((p) => p.storeProductId == SongletCatalog.proWeekly);
      expect(weekly.trialDays, 0);
    });
  });

  group('allowance', () {
    void expectAllowance(Allowance a, int songs, int clips) {
      expect(a.songs, songs);
      expect(a.clips, clips);
    }

    test('Pro in T1: 40 songs + 100 clips', () {
      for (final id in [SongletCatalog.proMonthly, SongletCatalog.proYearly]) {
        expectAllowance(SongletCatalog.allowance(id, PricingTier.t1), 40, 100);
      }
    });

    test('Pro in T2 / T3: 25 songs + 60 clips', () {
      for (final id in [SongletCatalog.proMonthly, SongletCatalog.proYearly]) {
        expectAllowance(SongletCatalog.allowance(id, PricingTier.t2), 25, 60);
        expectAllowance(SongletCatalog.allowance(id, PricingTier.t3), 25, 60);
      }
    });

    test('Premier: 120 songs + 200 clips in every tier', () {
      for (final tier in PricingTier.values) {
        expectAllowance(
          SongletCatalog.allowance(SongletCatalog.premierMonthly, tier),
          120,
          200,
        );
      }
    });
  });

  group('tierForStorefront', () {
    test('T3 = India', () {
      expect(SongletCatalog.tierForStorefront('IND'), PricingTier.t3);
    });

    test('T2 = Brazil, Mexico, Indonesia, Vietnam, Turkey', () {
      for (final code in ['BRA', 'MEX', 'IDN', 'VNM', 'TUR']) {
        expect(SongletCatalog.tierForStorefront(code), PricingTier.t2, reason: code);
      }
    });

    test('T1 for the rest, unknown and null; case-insensitive', () {
      for (final code in ['USA', 'GBR', 'CAN', 'AUS', 'DEU', 'FRA', 'JPN', 'KOR', 'ESP']) {
        expect(SongletCatalog.tierForStorefront(code), PricingTier.t1, reason: code);
      }
      expect(SongletCatalog.tierForStorefront(null), PricingTier.t1);
      expect(SongletCatalog.tierForStorefront('bra'), PricingTier.t2);
      expect(SongletCatalog.tierForStorefront('ind'), PricingTier.t3);
    });
  });

  test('packSongs', () {
    expect(SongletCatalog.packSongs(SongletCatalog.pack10), 10);
    expect(SongletCatalog.packSongs(SongletCatalog.pack50), 50);
    expect(SongletCatalog.packSongs(SongletCatalog.proMonthly), 0);
    expect(SongletCatalog.packSongs('unknown'), 0);
  });

  test('isSubscription / isPremier', () {
    expect(SongletCatalog.isSubscription(SongletCatalog.proYearly), isTrue);
    expect(SongletCatalog.isSubscription(SongletCatalog.premierMonthly), isTrue);
    expect(SongletCatalog.isSubscription(SongletCatalog.pack10), isFalse);
    expect(SongletCatalog.isPremier(SongletCatalog.premierMonthly), isTrue);
    expect(SongletCatalog.isPremier(SongletCatalog.proMonthly), isFalse);
  });

  test('product ids match PRD §8.1', () {
    expect(SongletCatalog.allIds, [
      'com.songlet.pro.weekly', // contract 02 v2.1
      'com.songlet.pro.yearly',
      'com.songlet.pro.monthly',
      'com.songlet.premier.monthly',
      'com.songlet.pack.10',
      'com.songlet.pack.50',
      // Music-video packs (PRD ch.15, platform 20260928e).
      'com.songlet.mv.chorus',
      'com.songlet.mv.full',
    ]);
    expect(SongletCatalog.mvPackCredits('com.songlet.mv.chorus'), 2395);
    expect(SongletCatalog.mvPackCredits('com.songlet.mv.full'), 12779);
    // PRD §15.4: T2/T3 grant in proportion to the local price.
    expect(SongletCatalog.mvPackCredits('com.songlet.mv.chorus', PricingTier.t2), 1196);
    expect(SongletCatalog.mvPackCredits('com.songlet.mv.chorus', PricingTier.t3), 1139);
    expect(SongletCatalog.mvPackCredits('com.songlet.mv.full', PricingTier.t2), 6384);
    expect(SongletCatalog.mvPackCredits('com.songlet.mv.full', PricingTier.t3), 6077);
    expect(SongletCatalog.mvPackCredits('com.songlet.pack.10', PricingTier.t2), 0);
    expect(SongletCatalog.isMvPack('com.songlet.pack.10'), isFalse);
    expect(SongletCatalog.trialSongCap, 10);
  });

  group('products()', () {
    final products = SongletCatalog.products();

    test('eight products in paywall order', () {
      expect(products.map((p) => p.productCode), SongletCatalog.allIds);
      expect(
        products.map((p) => p.sortOrder).toList(),
        [-1, 0, 1, 2, 3, 4, 5, 6],
      );
    });

    test('product code == store product id', () {
      for (final p in products) {
        expect(p.storeProductId, p.productCode);
      }
    });

    test('subscriptions are auto-renewable in one group; packs are consumable', () {
      expect(
        products.map((p) => p.kind),
        [
          ProductKind.autoRenewable,
          ProductKind.autoRenewable,
          ProductKind.autoRenewable,
          ProductKind.autoRenewable,
          ProductKind.consumable,
          ProductKind.consumable,
          ProductKind.consumable,
          ProductKind.consumable,
        ],
      );
      expect(
        products.where((p) => p.isSubscription).map((p) => p.subscriptionGroup).toSet(),
        {'songlet'},
      );
      expect(
        products.where((p) => p.isConsumable).map((p) => p.productCode),
        [...SongletCatalog.packIds, ...SongletCatalog.mvPackIds],
      );
    });

    test('only Pro yearly has the 7-day trial', () {
      expect(
        products.where((p) => p.trialDays > 0).map((p) => (p.productCode, p.trialDays)),
        [(SongletCatalog.proYearly, 7)],
      );
      final yearly = products.firstWhere((p) => p.productCode == SongletCatalog.proYearly);
      expect(yearly.billingCycle, 'annual');
      expect(yearly.highlightTag, 'best_value');
    });

    test('visibleProducts keeps the order through AppInitData', () {
      final init = AppInitData(products: products, legal: const LegalInfo());
      expect(init.visibleProducts.map((p) => p.productCode), SongletCatalog.allIds);
    });
  });
}
