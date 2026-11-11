import 'package:commerce_kit/src/auth/data/account_dtos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrentAccountDto', () {
    test('parses a fully populated /me payload', () {
      final account = CurrentAccountDto.fromJson({
        'user_id': 'u1',
        'nickname': 'alice',
        'avatar_url': 'https://img/a',
        'account_type': 'personal',
        'email': 'a***@example.com',
        'phone': '138****5678',
        'role': 'user',
        'tenant_id': 0,
        'created_at': 1730000000,
        'status': 'active',
        'is_guest': false,
        'email_verified': true,
        'profile_complete': true,
        'subscription': {
          'status': 'active',
          'billing_cycle': 'monthly',
          'is_auto_renew': true,
          'current_period_end': 1735689600,
        },
        'wallet': {
          'balance': 50000,
          'frozen': 200,
          'total_credited': 100000,
          'total_debited': 50200,
        },
        'features': [
          {
            'feature_code': 'vip',
            'feature_name': 'VIP',
            'source': 'iap_subscription',
            'granted_at': 1730000000,
            'expires_at': 1735689600,
          },
        ],
        'session': {
          'login_time': 1730000000,
          'login_ip': '1.2.3.4',
          'device_id': 'd1',
          'active_session_count': 2,
        },
        'permissions': ['p1', 'p2'],
        'guidance': {
          'needs_profile_complete': false,
          'has_active_subscription': true,
          'has_credits': true,
        },
      }).toDomain();

      expect(account.userId, 'u1');
      expect(account.nickname, 'alice');
      expect(account.isGuest, isFalse);
      expect(account.subscription?.isActive, isTrue);
      expect(account.wallet?.balance, 50000);
      expect(account.features.single.code, 'vip');
      expect(account.session?.activeSessionCount, 2);
      expect(account.permissions, ['p1', 'p2']);
      expect(account.guidance.hasActiveSubscription, isTrue);
    });

    test('degrades gracefully when optional sections are absent', () {
      final account = CurrentAccountDto.fromJson({
        'user_id': 'g1',
        'nickname': 'guest',
        'account_type': 'guest',
        'role': 'user',
        'status': 'active',
        'is_guest': true,
      }).toDomain();

      expect(account.subscription, isNull);
      expect(account.wallet, isNull);
      expect(account.session, isNull);
      expect(account.features, isEmpty);
      // Guidance is derived from the parsed sections when not provided.
      expect(account.guidance.hasActiveSubscription, isFalse);
      expect(account.guidance.hasCredits, isFalse);
    });
  });
}
