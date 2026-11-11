import 'package:meta/meta.dart';

/// A granted entitlement (e.g. `vip`, `no_watermark`). Shared by `/me` and
/// `/wallet`. A feature is active when it has no expiry or expires in the future.
@immutable
class WalletFeature {
  const WalletFeature({
    required this.code,
    required this.name,
    required this.source,
    this.grantedAt,
    this.expiresAt,
  });

  final String code;
  final String name;

  /// `iap_purchase` / `iap_subscription` / `admin_grant`, etc.
  final String source;
  final DateTime? grantedAt;
  final DateTime? expiresAt;

  bool isActiveAt(DateTime now) =>
      expiresAt == null || expiresAt!.isAfter(now);
}

/// Subscription summary from `/me`.
@immutable
class Subscription {
  const Subscription({
    required this.status,
    this.billingCycle,
    this.isAutoRenew = false,
    this.currentPeriodEnd,
    this.trialEndAt,
  });

  final String status;
  final String? billingCycle;
  final bool isAutoRenew;
  final DateTime? currentPeriodEnd;
  final DateTime? trialEndAt;

  bool get isActive => status == 'active' || status == 'trialing';
}

/// Wallet balances + active features from `/wallet` (and embedded in `/me`).
/// `balance` is the available balance (server returns `balance - frozen`).
@immutable
class WalletSnapshot {
  const WalletSnapshot({
    required this.balance,
    required this.frozen,
    required this.totalCredited,
    required this.totalDebited,
    this.features = const <WalletFeature>[],
  });

  static const WalletSnapshot empty = WalletSnapshot(
    balance: 0,
    frozen: 0,
    totalCredited: 0,
    totalDebited: 0,
  );

  final int balance;
  final int frozen;
  final int totalCredited;
  final int totalDebited;
  final List<WalletFeature> features;
}
