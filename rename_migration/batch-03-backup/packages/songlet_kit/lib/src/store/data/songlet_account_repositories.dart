import 'package:commerce_kit/commerce_kit.dart';

import '../domain/entitlement_sync.dart';
import '../domain/songlet_entitlement.dart';

/// commerce_kit's [WalletRepository] over the Songlet ledger: the wallet
/// balance is the full-song allowance left (`songs_left`), and the tier is a
/// feature (`songlet.tier.<tier>`). Every refresh is a real sync, so the
/// reconciler's `refreshEntitlement()` pushes renewals / refunds to the ledger.
class SongletWalletRepository implements WalletRepository {
  SongletWalletRepository(this._sync);

  final EntitlementSync _sync;

  @override
  Future<WalletSnapshot> fetch() async => walletFromEntitlement(await _sync.sync());
}

/// commerce_kit's [AccountRepository]: Songlet has no accounts (PRD D5), so the
/// "current account" is the anonymous `app_account_token` holder whose
/// subscription state comes from the ledger — which is what
/// `subscriptionEntitlementProvider` (the orchestrator's already-subscribed
/// pre-gate) reads.
class SongletAccountRepository implements AccountRepository {
  SongletAccountRepository(this._sync, {required Future<String> Function() accountToken})
      : _accountToken = accountToken;

  final EntitlementSync _sync;
  final Future<String> Function() _accountToken;

  @override
  Future<CurrentAccount> currentAccount() async {
    final entitlement = await _sync.sync();
    final token = await _accountToken();
    return CurrentAccount(
      userId: token,
      nickname: '',
      accountType: 'guest',
      role: 'user',
      status: 'active',
      isGuest: true,
      guidance: Guidance(
        needsProfileComplete: false,
        hasActiveSubscription: entitlement.tier.hasSubscription,
        hasCredits: entitlement.songsLeft > 0,
      ),
      subscription: entitlement.tier.hasSubscription
          ? Subscription(
              status: 'active',
              billingCycle: 'monthly',
              isAutoRenew: true,
              currentPeriodEnd: entitlement.resetAt,
            )
          : null,
      wallet: walletFromEntitlement(entitlement),
    );
  }
}

WalletSnapshot walletFromEntitlement(SongletEntitlement e) => WalletSnapshot(
      balance: e.songsLeft,
      frozen: 0,
      totalCredited: 0,
      totalDebited: 0,
      features: [
        WalletFeature(
          code: 'songlet.tier.${e.tier.name}',
          name: e.tier.name,
          source: 'songlet_ledger',
        ),
      ],
    );
