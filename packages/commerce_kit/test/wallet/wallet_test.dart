import 'package:commerce_kit/commerce_kit.dart';
import 'package:commerce_kit/src/wallet/data/wallet_dtos.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WalletResponseDto', () {
    test('parses balances and features', () {
      final snapshot = WalletResponseDto.fromJson({
        'balance': 49800,
        'frozen': 200,
        'total_credited': 100000,
        'total_debited': 50200,
        'features': [
          {
            'feature_code': 'vip',
            'feature_name': 'VIP',
            'source': 'iap_subscription',
            'expires_at': 1893456000,
          },
        ],
      }).toDomain();

      expect(snapshot.balance, 49800);
      expect(snapshot.frozen, 200);
      expect(snapshot.features.single.code, 'vip');
    });

    test('a new guest wallet (empty) yields zeros, not an error', () {
      final snapshot = WalletResponseDto.fromJson(<String, dynamic>{}).toDomain();
      expect(snapshot.balance, 0);
      expect(snapshot.features, isEmpty);
    });
  });

  group('feature gating', () {
    test('activeFeatures excludes expired and keeps no-expiry', () {
      final now = DateTime.utc(2026);
      final result = activeFeatures(
        [
          WalletFeature(
            code: 'vip',
            name: '',
            source: '',
            expiresAt: DateTime.utc(2030),
          ),
          WalletFeature(
            code: 'expired',
            name: '',
            source: '',
            expiresAt: DateTime.utc(2020),
          ),
          const WalletFeature(code: 'forever', name: '', source: ''),
        ],
        now,
      );
      expect(result.map((f) => f.code), ['vip', 'forever']);
    });

    test('derived providers read from the snapshot', () async {
      const snapshot = WalletSnapshot(
        balance: 4980,
        frozen: 20,
        totalCredited: 5000,
        totalDebited: 0,
        features: [
          WalletFeature(code: 'vip', name: 'VIP', source: 'iap_subscription'),
        ],
      );
      final container = ProviderContainer(
        overrides: [walletSnapshotProvider.overrideWith((ref) => snapshot)],
      );
      addTearDown(container.dispose);

      await container.read(walletSnapshotProvider.future);

      expect(container.read(walletBalanceProvider), 4980);
      expect(container.read(hasFeatureProvider('vip')), isTrue);
      expect(container.read(hasFeatureProvider('missing')), isFalse);
    });
  });
}
