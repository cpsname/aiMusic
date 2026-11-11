import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:songlet_kit/src/store/data/music_account_repositories.dart';
import 'package:songlet_kit/src/store/domain/entitlement_sync.dart';

import '../../support/songlet_fakes.dart';

void main() {
  group('walletFromEntitlement', () {
    test('balance = songs left; the tier is a ledger feature', () {
      final wallet = walletFromEntitlement(
        const SongletEntitlement(tier: SongletTier.pro, songsLeft: 38, clipsLeft: 90),
      );

      expect(wallet.balance, 38);
      expect(wallet.frozen, 0);
      expect(wallet.totalCredited, 0);
      expect(wallet.totalDebited, 0);
      expect(wallet.features, hasLength(1));
      final feature = wallet.features.single;
      expect(feature.code, 'songlet.tier.pro');
      expect(feature.name, 'pro');
      expect(feature.source, 'songlet_ledger');
      expect(feature.isActiveAt(DateTime.utc(2030)), isTrue);
    });

    test('free tier', () {
      final wallet = walletFromEntitlement(SongletEntitlement.unknown);
      expect(wallet.balance, 0);
      expect(wallet.features.single.code, 'songlet.tier.free');
    });
  });

  group('repositories', () {
    late FakeEntitlementRemote remote;
    late EntitlementSync sync;

    setUp(() {
      remote = FakeEntitlementRemote();
      sync = EntitlementSync(
        remote: remote,
        source: FakeSignedTransactionSource(),
        outbox: FakeOutbox(),
        appAccountToken: () async => 'device-uuid',
      );
    });

    test('every wallet fetch is a real ledger sync', () async {
      final repo = SongletWalletRepository(sync);

      final wallet = await repo.fetch();
      await repo.fetch();

      expect(wallet.balance, 40);
      expect(remote.calls, hasLength(2));
    });

    test('a subscriber account reports an active subscription', () async {
      remote.result = SongletEntitlement(
        tier: SongletTier.premier,
        songsLeft: 120,
        clipsLeft: 200,
        resetAt: DateTime.utc(2026, 10),
      );

      final account = await SongletAccountRepository(
        sync,
        accountToken: () async => 'device-uuid',
      ).currentAccount();

      expect(account.userId, 'device-uuid');
      expect(account.isGuest, isTrue);
      expect(account.subscription, isNotNull);
      expect(account.subscription!.isActive, isTrue);
      expect(account.subscription!.currentPeriodEnd, DateTime.utc(2026, 10));
      expect(account.guidance.hasActiveSubscription, isTrue);
      expect(account.guidance.hasCredits, isTrue);
      expect(account.wallet!.balance, 120);
    });

    test('a pack / free account has no subscription', () async {
      remote.result = const SongletEntitlement(
        tier: SongletTier.pack,
        songsLeft: 0,
        clipsLeft: 0,
      );

      final account = await SongletAccountRepository(
        sync,
        accountToken: () async => 'device-uuid',
      ).currentAccount();

      expect(account.subscription, isNull);
      expect(account.guidance.hasActiveSubscription, isFalse);
      expect(account.guidance.hasCredits, isFalse);
    });
  });
}
