import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';

void main() {
  group('Weekly Pro (contract 02 v2.1)', () {
    test('is the recommended subscription and leads the catalog', () {
      expect(MusicCatalog.proWeekly, 'com.songlet.pro.weekly');
      expect(MusicCatalog.recommendedSubscription, MusicCatalog.proWeekly);
      expect(MusicCatalog.subscriptionIds.first, MusicCatalog.proWeekly);
      expect(MusicCatalog.isSubscription(MusicCatalog.proWeekly), isTrue);
      expect(MusicCatalog.isWeekly(MusicCatalog.proWeekly), isTrue);
      expect(MusicCatalog.isWeekly(MusicCatalog.proMonthly), isFalse);
      final weekly = MusicCatalog.products().firstWhere((p) => p.storeProductId == MusicCatalog.proWeekly);
      expect(weekly.billingCycle, 'weekly');
      expect(weekly.isSubscription, isTrue);
      expect(weekly.sortOrder, -1, reason: 'first, wherever the list is sorted');
    });

    test('has no first-week discount of its own: the App Store\'s introductory offer is read, never typed', () {
      final weekly = MusicCatalog.products().firstWhere((p) => p.storeProductId == MusicCatalog.proWeekly);
      expect(weekly.trialDays, 0);
    });
  });

  group('allowance', () {
    void expectAllowance(MusicAllowance a, int songs, int clips) {
      expect(a.songs, songs);
      expect(a.clips, clips);
    }

    test('Pro in T1: 40 songs + 100 clips', () {
      for (final id in [MusicCatalog.proMonthly, MusicCatalog.proYearly]) {
        expectAllowance(MusicCatalog.allowance(id, MusicPricingTier.t1), 40, 100);
      }
    });

    test('Pro in T2 / T3: 25 songs + 60 clips', () {
      for (final id in [MusicCatalog.proMonthly, MusicCatalog.proYearly]) {
        expectAllowance(MusicCatalog.allowance(id, MusicPricingTier.t2), 25, 60);
        expectAllowance(MusicCatalog.allowance(id, MusicPricingTier.t3), 25, 60);
      }
    });

    test('Premier: 120 songs + 200 clips in every tier', () {
      for (final tier in MusicPricingTier.values) {
        expectAllowance(
          MusicCatalog.allowance(MusicCatalog.premierMonthly, tier),
          120,
          200,
        );
      }
    });
  });

  group('tierForStorefront', () {
    test('T3 = India', () {
      expect(MusicCatalog.tierForStorefront('IND'), MusicPricingTier.t3);
    });

    test('T2 = Brazil, Mexico, Indonesia, Vietnam, Turkey', () {
      for (final code in ['BRA', 'MEX', 'IDN', 'VNM', 'TUR']) {
        expect(MusicCatalog.tierForStorefront(code), MusicPricingTier.t2, reason: code);
      }
    });

    test('T1 for the rest, unknown and null; case-insensitive', () {
      for (final code in ['USA', 'GBR', 'CAN', 'AUS', 'DEU', 'FRA', 'JPN', 'KOR', 'ESP']) {
        expect(MusicCatalog.tierForStorefront(code), MusicPricingTier.t1, reason: code);
      }
      expect(MusicCatalog.tierForStorefront(null), MusicPricingTier.t1);
      expect(MusicCatalog.tierForStorefront('bra'), MusicPricingTier.t2);
      expect(MusicCatalog.tierForStorefront('ind'), MusicPricingTier.t3);
    });
  });

  test('packSongs', () {
    expect(MusicCatalog.packSongs(MusicCatalog.pack10), 10);
    expect(MusicCatalog.packSongs(MusicCatalog.pack50), 50);
    expect(MusicCatalog.packSongs(MusicCatalog.proMonthly), 0);
    expect(MusicCatalog.packSongs('unknown'), 0);
  });

  test('isSubscription / isPremier', () {
    expect(MusicCatalog.isSubscription(MusicCatalog.proYearly), isTrue);
    expect(MusicCatalog.isSubscription(MusicCatalog.premierMonthly), isTrue);
    expect(MusicCatalog.isSubscription(MusicCatalog.pack10), isFalse);
    expect(MusicCatalog.isPremier(MusicCatalog.premierMonthly), isTrue);
    expect(MusicCatalog.isPremier(MusicCatalog.proMonthly), isFalse);
  });

  test('product ids match PRD §8.1', () {
    expect(MusicCatalog.allIds, [
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
    expect(MusicCatalog.mvPackCredits('com.songlet.mv.chorus'), 2395);
    expect(MusicCatalog.mvPackCredits('com.songlet.mv.full'), 12779);
    // PRD §15.4: T2/T3 grant in proportion to the local price.
    expect(MusicCatalog.mvPackCredits('com.songlet.mv.chorus', MusicPricingTier.t2), 1196);
    expect(MusicCatalog.mvPackCredits('com.songlet.mv.chorus', MusicPricingTier.t3), 1139);
    expect(MusicCatalog.mvPackCredits('com.songlet.mv.full', MusicPricingTier.t2), 6384);
    expect(MusicCatalog.mvPackCredits('com.songlet.mv.full', MusicPricingTier.t3), 6077);
    expect(MusicCatalog.mvPackCredits('com.songlet.pack.10', MusicPricingTier.t2), 0);
    expect(MusicCatalog.isMvPack('com.songlet.pack.10'), isFalse);
    expect(MusicCatalog.trialSongCap, 10);
  });

  group('products()', () {
    final products = MusicCatalog.products();

    test('eight products in paywall order', () {
      expect(products.map((p) => p.productCode), MusicCatalog.allIds);
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
        [...MusicCatalog.packIds, ...MusicCatalog.mvPackIds],
      );
    });

    test('only Pro yearly has the 7-day trial', () {
      expect(
        products.where((p) => p.trialDays > 0).map((p) => (p.productCode, p.trialDays)),
        [(MusicCatalog.proYearly, 7)],
      );
      final yearly = products.firstWhere((p) => p.productCode == MusicCatalog.proYearly);
      expect(yearly.billingCycle, 'annual');
      expect(yearly.highlightTag, 'best_value');
    });

    test('visibleProducts keeps the order through AppInitData', () {
      final init = AppInitData(products: products, legal: const LegalInfo());
      expect(init.visibleProducts.map((p) => p.productCode), MusicCatalog.allIds);
    });
  });
}
