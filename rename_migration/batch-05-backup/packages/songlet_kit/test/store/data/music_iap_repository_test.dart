import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:songlet_kit/src/store/data/music_iap_repository.dart';
import 'package:songlet_kit/src/store/domain/entitlement_sync.dart';

import '../../support/music_fakes.dart';

void main() {
  late FakeEntitlementRemote remote;
  late FakeOutbox outbox;
  late MusicIapRepository repository;
  final now = DateTime.utc(2026, 9, 24, 10);
  const legal = LegalInfo(
    termsUrl: 'https://songlet.app/terms',
    privacyUrl: 'https://r2.showsapp.org/Songlet/privacy_policy.html',
  );

  setUp(() {
    remote = FakeEntitlementRemote();
    outbox = FakeOutbox();
    repository = MusicIapRepository(
      sync: EntitlementSync(
        remote: remote,
        source: FakeSignedTransactionSource(),
        outbox: outbox,
        appAccountToken: () async => 'token',
      ),
      legal: legal,
      now: () => now,
    );
  });

  group('appInit', () {
    test('returns the fixed 8-product catalog and the legal links, offline', () async {
      final init = await repository.appInit(clientVersion: '1.0.0');

      expect(init.products.map((p) => p.productCode), MusicCatalog.allIds);
      expect(init.products, hasLength(8));
      expect(init.legal, same(legal));
      expect(init.update, isNull);
      expect(remote.calls, isEmpty);
    });
  });

  group('createOrder', () {
    test('is local, keyed by the product, and valid for an hour', () async {
      final order = await repository.createOrder(
        distributionCode: 'ignored',
        productCode: MusicCatalog.proMonthly,
        pushToken: 'uuid',
      );

      expect(order.orderNo, startsWith('local-'));
      expect(order.productCode, MusicCatalog.proMonthly);
      expect(order.storeProductId, MusicCatalog.proMonthly);
      expect(order.expiresAt, now.add(MusicIapRepository.orderValidity));
      expect(order.isExpired(now), isFalse);
      expect(order.isExpired(now.add(const Duration(hours: 2))), isTrue);
      expect(remote.calls, isEmpty, reason: 'no order endpoint on the Songlet backend');
    });

    test('every order gets a fresh number', () async {
      final a = await repository.createOrder(distributionCode: '', productCode: 'p');
      final b = await repository.createOrder(distributionCode: '', productCode: 'p');
      expect(a.orderNo, isNot(b.orderNo));
    });
  });

  group('verify', () {
    test('triggers an entitlement sync carrying the queued JWS', () async {
      final jws = jwsFor(MusicCatalog.pack10, 'tx-1');
      outbox.items.add(jws);

      final result = await repository.verify(orderNo: 'local-1', transactionId: 'tx-1');

      expect(remote.calls, hasLength(1));
      expect(remote.calls.single.signedTransactions, [jws]);
      expect(result.orderNo, 'local-1');
      expect(result.isCompleted, isTrue);
      expect(result.isGranted, isTrue);
      expect(outbox.items, isEmpty);
    });

    test('a failed sync fails the verify (the orchestrator retries)', () async {
      remote.error = StateError('ledger down');
      await expectLater(
        repository.verify(orderNo: 'local-1', transactionId: 'tx-1'),
        throwsStateError,
      );
    });
  });
}
