import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SubscriptionEntitlement of(String status) =>
      SubscriptionEntitlement.fromSubscription(Subscription(status: status));

  group('SubscriptionEntitlement', () {
    test('active / trialing / grace period are entitled', () {
      expect(of('active').renewalState, SubscriptionRenewalState.subscribed);
      expect(of('active').isEntitled, isTrue);
      expect(of('trialing').isEntitled, isTrue);
      expect(of('in_grace_period').renewalState,
          SubscriptionRenewalState.inGracePeriod);
      expect(of('in_grace_period').isEntitled, isTrue); // grace still grants access
    });

    test('billing-retry prompts but is not entitled', () {
      final e = of('in_billing_retry');
      expect(e.renewalState, SubscriptionRenewalState.inBillingRetryPeriod);
      expect(e.needsBillingAttention, isTrue);
      expect(e.isEntitled, isFalse);
    });

    test('expired / revoked / none are not entitled', () {
      expect(of('expired').isEntitled, isFalse);
      expect(of('revoked').renewalState, SubscriptionRenewalState.revoked);
      expect(of('revoked').isEntitled, isFalse);
      expect(SubscriptionEntitlement.fromSubscription(null).renewalState,
          SubscriptionRenewalState.none);
      expect(SubscriptionEntitlement.none.isEntitled, isFalse);
    });
  });
}
