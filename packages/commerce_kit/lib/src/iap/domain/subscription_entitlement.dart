import 'package:meta/meta.dart';

import '../../common/billing.dart';

/// Server-reported renewal state. The **server is the source of truth** for
/// entitlement; the client never derives entitlement from local transactions.
enum SubscriptionRenewalState {
  none,
  subscribed,
  trialing,
  inGracePeriod,
  inBillingRetryPeriod,
  expired,
  revoked,
}

/// Entitlement derived from the `/me` subscription section. Gates UI: grace
/// period still grants access; billing-retry prompts to update payment rather
/// than locking out.
@immutable
class SubscriptionEntitlement {
  const SubscriptionEntitlement({
    required this.renewalState,
    this.isAutoRenew = false,
    this.currentPeriodEnd,
  });

  factory SubscriptionEntitlement.fromSubscription(Subscription? subscription) {
    if (subscription == null) {
      return const SubscriptionEntitlement(
        renewalState: SubscriptionRenewalState.none,
      );
    }
    return SubscriptionEntitlement(
      renewalState: _map(subscription.status),
      isAutoRenew: subscription.isAutoRenew,
      currentPeriodEnd: subscription.currentPeriodEnd,
    );
  }

  static const SubscriptionEntitlement none = SubscriptionEntitlement(
    renewalState: SubscriptionRenewalState.none,
  );

  final SubscriptionRenewalState renewalState;
  final bool isAutoRenew;
  final DateTime? currentPeriodEnd;

  /// Access should be granted: active, in trial, or in grace period.
  bool get isEntitled =>
      renewalState == SubscriptionRenewalState.subscribed ||
      renewalState == SubscriptionRenewalState.trialing ||
      renewalState == SubscriptionRenewalState.inGracePeriod;

  /// Prompt the user to update their payment method (do not lock out).
  bool get needsBillingAttention =>
      renewalState == SubscriptionRenewalState.inBillingRetryPeriod;

  static SubscriptionRenewalState _map(String status) =>
      switch (status.toLowerCase()) {
        'active' || 'subscribed' => SubscriptionRenewalState.subscribed,
        'trialing' || 'trial' => SubscriptionRenewalState.trialing,
        'in_grace_period' ||
        'grace' ||
        'grace_period' =>
          SubscriptionRenewalState.inGracePeriod,
        'in_billing_retry' ||
        'billing_retry' ||
        'billing_retry_period' =>
          SubscriptionRenewalState.inBillingRetryPeriod,
        'revoked' => SubscriptionRenewalState.revoked,
        'expired' || 'canceled' || 'cancelled' =>
          SubscriptionRenewalState.expired,
        _ => SubscriptionRenewalState.none,
      };
}
