import 'dart:async';

import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:songlet_kit/src/platform/data/songlet_api.g.dart';
import 'package:songlet_kit/src/store/data/pigeon_store_client.dart';

import '../../support/music_fakes.dart';

/// The generated host API with its StoreKit calls answered in Dart.
class FakeSongletNativeApi extends SongletNativeApi {
  FakeSongletNativeApi();

  List<SKProductDto> products = [];
  PurchaseResultDto purchaseResult = PurchaseResultDto(status: 'success');
  List<String> currentTransactions = [];
  PlatformException? error;

  final List<List<String>> fetched = [];
  final List<(String, String)> purchases = [];

  @override
  Future<List<SKProductDto>> fetchProducts(List<String> ids) async {
    fetched.add(ids);
    final failure = error;
    if (failure != null) throw failure;
    return products;
  }

  @override
  Future<PurchaseResultDto> purchase(String productId, String appAccountToken) async {
    purchases.add((productId, appAccountToken));
    final failure = error;
    if (failure != null) throw failure;
    return purchaseResult;
  }

  @override
  Future<List<String>> currentSignedTransactions() async {
    final failure = error;
    if (failure != null) throw failure;
    return currentTransactions;
  }
}

SKProductDto productDto({
  String id = MusicCatalog.proYearly,
  String? periodUnit = 'year',
  int? periodValue = 1,
  String? introPaymentMode,
  String? introDisplayPrice,
  String? introPeriodUnit,
  int? introPeriodValue,
  int? introPeriodCount,
  bool eligible = true,
  String? storefront,
}) =>
    SKProductDto(
      id: id,
      displayName: 'Pro Yearly',
      productDescription: 'All songs, all year',
      displayPrice: r'$59.99',
      price: 59.99,
      currencyCode: 'USD',
      type: 'autoRenewable',
      periodUnit: periodUnit,
      periodValue: periodValue,
      introPaymentMode: introPaymentMode,
      introDisplayPrice: introDisplayPrice,
      introPeriodUnit: introPeriodUnit,
      introPeriodValue: introPeriodValue,
      introPeriodCount: introPeriodCount,
      isEligibleForIntroOffer: eligible,
      storefrontCountryCode: storefront,
    );

const StoreProductDetails packDetails = StoreProductDetails(
  id: MusicCatalog.pack10,
  title: '10 Songs',
  description: '',
  price: r'$4.99',
  rawPrice: 4.99,
  currencyCode: 'USD',
);

void main() {
  late FakeSongletNativeApi api;
  late StreamController<String> updates;
  late FakeOutbox outbox;
  late List<String> storefronts;
  late PigeonStoreClient client;
  late List<List<StorePurchase>> events;
  late StreamSubscription<List<StorePurchase>> subscription;

  setUp(() {
    api = FakeSongletNativeApi();
    updates = StreamController<String>();
    outbox = FakeOutbox();
    storefronts = [];
    events = [];
    client = PigeonStoreClient(
      api: api,
      transactionUpdates: updates.stream,
      outbox: outbox,
      onStorefront: storefronts.add,
    );
    subscription = client.purchaseStream.listen(events.add);
  });

  tearDown(() async {
    await subscription.cancel();
    client.dispose();
    await updates.close();
  });

  test('is always available', () async {
    expect(await client.isAvailable(), isTrue);
  });

  group('buy', () {
    test('success: the JWS is queued, then `purchased` is emitted by the time buy returns', () async {
      final jws = jwsFor(MusicCatalog.pack10, 'tx-1');
      api.purchaseResult = PurchaseResultDto(
        status: 'success',
        signedTransaction: jws,
        transactionId: 'tx-1',
        productId: MusicCatalog.pack10,
      );
      List<String>? outboxAtEvent;
      final sub = client.purchaseStream.listen((_) => outboxAtEvent = outbox.pending());

      await client.buy(
        product: packDetails,
        isConsumable: true,
        appAccountToken: 'uuid-1',
      );
      // The broadcast stream delivers asynchronously: one event-loop turn and
      // the outcome is there — no further native callback is needed.
      await pumpEventQueue();

      expect(api.purchases.single, (MusicCatalog.pack10, 'uuid-1'));
      expect(outbox.items, [jws]);
      expect(events, hasLength(1), reason: 'added before buy() completed');
      final purchase = events.single.single;
      expect(purchase.status, StorePurchaseStatus.purchased);
      expect(purchase.productId, MusicCatalog.pack10);
      expect(purchase.transactionId, 'tx-1');
      expect(purchase.isSuccessful, isTrue);
      expect(outboxAtEvent, [jws], reason: 'outbox written before the announcement');
      await sub.cancel();
    });

    test('the transaction id falls back to the JWS payload, the product to the request', () async {
      api.purchaseResult = PurchaseResultDto(
        status: 'success',
        signedTransaction: jwsFor(MusicCatalog.pack10, 'tx-from-jws'),
      );

      await client.buy(product: packDetails, isConsumable: true);
      await pumpEventQueue();

      expect(api.purchases.single.$2, '', reason: 'no token → empty string');
      expect(events.single.single.transactionId, 'tx-from-jws');
      expect(events.single.single.productId, MusicCatalog.pack10);
    });

    test('pending (Ask-to-Buy / SCA) → pending, nothing queued', () async {
      api.purchaseResult = PurchaseResultDto(status: 'pending');

      await client.buy(product: packDetails, isConsumable: true);
      await pumpEventQueue();

      expect(events.single.single.status, StorePurchaseStatus.pending);
      expect(events.single.single.isTerminal, isFalse);
      expect(outbox.items, isEmpty);
    });

    test('userCancelled → canceled', () async {
      api.purchaseResult = PurchaseResultDto(status: 'userCancelled');

      await client.buy(product: packDetails, isConsumable: true);
      await pumpEventQueue();

      expect(events.single.single.status, StorePurchaseStatus.canceled);
      expect(events.single.single.transactionId, '');
      expect(outbox.items, isEmpty);
    });

    test('failed → error with the message', () async {
      api.purchaseResult = PurchaseResultDto(
        status: 'failed',
        errorMessage: 'verification failed',
      );

      await client.buy(product: packDetails, isConsumable: true);
      await pumpEventQueue();

      expect(events.single.single.status, StorePurchaseStatus.error);
      expect(events.single.single.error, 'verification failed');
    });

    test('any unknown status is an error', () async {
      api.purchaseResult = PurchaseResultDto(status: 'weird');
      await client.buy(product: packDetails, isConsumable: true);
      await pumpEventQueue();
      expect(events.single.single.status, StorePurchaseStatus.error);
    });

    test('a platform error becomes StoreUnavailableException, no event', () async {
      api.error = PlatformException(code: 'storekit', message: 'no network');

      await expectLater(
        client.buy(product: packDetails, isConsumable: true),
        throwsA(
          isA<StoreUnavailableException>().having((e) => e.message, 'message', 'no network'),
        ),
      );
      await pumpEventQueue();
      expect(events, isEmpty);
    });
  });

  group('restore', () {
    test('emits one `restored` batch and queues every valid JWS', () async {
      final pro = jwsFor(MusicCatalog.proYearly, 'tx-sub');
      final pack = jwsFor(MusicCatalog.pack50, 'tx-pack');
      api.currentTransactions = [pro, 'garbage', pack];

      await client.restore();
      await pumpEventQueue();

      expect(outbox.items, [pro, pack]);
      expect(events, hasLength(1));
      expect(
        events.single.map((p) => (p.productId, p.transactionId, p.status)),
        [
          (MusicCatalog.proYearly, 'tx-sub', StorePurchaseStatus.restored),
          (MusicCatalog.pack50, 'tx-pack', StorePurchaseStatus.restored),
        ],
      );
    });

    test('nothing to restore → no event', () async {
      await client.restore();
      await pumpEventQueue();
      expect(events, isEmpty);
    });

    test('a platform error becomes StoreUnavailableException', () async {
      api.error = PlatformException(code: 'x');
      await expectLater(client.restore(), throwsA(isA<StoreUnavailableException>()));
    });
  });

  group('transactionUpdates', () {
    test('an update becomes a `purchased` event and reports the storefront', () async {
      updates.add(jwsFor(MusicCatalog.proMonthly, 'tx-renew', storefront: 'BRA'));
      await pumpEventQueue();

      expect(events.single.single.status, StorePurchaseStatus.purchased);
      expect(events.single.single.productId, MusicCatalog.proMonthly);
      expect(events.single.single.transactionId, 'tx-renew');
      expect(storefronts, ['BRA']);
      expect(outbox.added, isEmpty, reason: 'NativeBridge already queued it');
    });

    test('an unparseable update is ignored', () async {
      updates.add('not-a-jws');
      await pumpEventQueue();
      expect(events, isEmpty);
      expect(storefronts, isEmpty);
    });

    test('no storefront in the payload → not reported', () async {
      updates.add(jwsFor(MusicCatalog.pack10, 'tx'));
      await pumpEventQueue();
      expect(events, hasLength(1));
      expect(storefronts, isEmpty);
    });
  });

  group('queryProducts', () {
    test('maps the DTOs and reports the storefront', () async {
      api.products = [
        productDto(storefront: 'USA'),
        productDto(
          id: MusicCatalog.pack10,
          periodUnit: null,
          periodValue: null,
          storefront: 'USA',
        ),
      ];

      final details = await client.queryProducts({
        MusicCatalog.proYearly,
        MusicCatalog.pack10,
      });

      expect(
        api.fetched.single.toSet(),
        {MusicCatalog.proYearly, MusicCatalog.pack10},
      );
      expect(storefronts, ['USA'], reason: 'reported once per query');
      expect(details.map((d) => d.id), [MusicCatalog.proYearly, MusicCatalog.pack10]);
      expect(
        details.first.subscriptionPeriod,
        const SubscriptionPeriodValue(numberOfUnits: 1, unit: PeriodUnit.year),
      );
      expect(details.last.subscriptionPeriod, isNull);
    });

    test('the first non-empty storefront wins; none → not reported', () async {
      api.products = [
        productDto(storefront: ''),
        productDto(storefront: 'JPN'),
        productDto(storefront: 'USA'),
      ];
      await client.queryProducts({MusicCatalog.proYearly});
      expect(storefronts, ['JPN']);

      api.products = [productDto()];
      await client.queryProducts({MusicCatalog.proYearly});
      expect(storefronts, ['JPN']);
    });

    test('an eligible free-trial intro offer is surfaced', () async {
      api.products = [
        productDto(
          introPaymentMode: 'freeTrial',
          introDisplayPrice: r'$0.00',
          introPeriodUnit: 'week',
          introPeriodValue: 1,
          introPeriodCount: 1,
        ),
      ];

      final offer = (await client.queryProducts({MusicCatalog.proYearly}))
          .single
          .introductoryOffer!;

      expect(offer.type, OfferType.introductory);
      expect(offer.paymentMode, OfferPaymentMode.freeTrial);
      expect(offer.isFreeTrial, isTrue);
      expect(offer.formattedPrice, '');
      expect(offer.period, const SubscriptionPeriodValue(numberOfUnits: 1, unit: PeriodUnit.week));
      expect(offer.numberOfPeriods, 1);
      expect(offer.currencyCode, 'USD');
    });

    test('an intro offer the user is not eligible for is hidden', () async {
      api.products = [
        productDto(
          introPaymentMode: 'freeTrial',
          introPeriodUnit: 'week',
          introPeriodValue: 1,
          eligible: false,
        ),
      ];
      final details = await client.queryProducts({MusicCatalog.proYearly});
      expect(details.single.introductoryOffer, isNull);
    });

    test('a platform error becomes StoreUnavailableException', () async {
      api.error = PlatformException(code: 'unavailable');
      await expectLater(
        client.queryProducts({MusicCatalog.pack10}),
        throwsA(
          isA<StoreUnavailableException>().having((e) => e.message, 'message', 'unavailable'),
        ),
      );
    });
  });

  test('complete is a no-op (StoreKit finishes natively)', () async {
    await client.complete(
      const StorePurchase(
        productId: MusicCatalog.pack10,
        transactionId: 'tx',
        status: StorePurchaseStatus.purchased,
      ),
    );
    expect(api.purchases, isEmpty);
    expect(outbox.items, isEmpty);
  });

  group('storeProductDetailsFromDto', () {
    test('copies the display fields', () {
      final details = storeProductDetailsFromDto(productDto());
      expect(details.id, MusicCatalog.proYearly);
      expect(details.title, 'Pro Yearly');
      expect(details.description, 'All songs, all year');
      expect(details.price, r'$59.99');
      expect(details.rawPrice, 59.99);
      expect(details.currencyCode, 'USD');
      expect(details.introductoryOffer, isNull);
      expect(details.promotionalOffers, isEmpty);
    });

    test('maps every period unit; invalid periods are dropped', () {
      SubscriptionPeriodValue? period(String? unit, int? value) =>
          storeProductDetailsFromDto(productDto(periodUnit: unit, periodValue: value))
              .subscriptionPeriod;

      expect(period('day', 3), const SubscriptionPeriodValue(numberOfUnits: 3, unit: PeriodUnit.day));
      expect(period('week', 1), const SubscriptionPeriodValue(numberOfUnits: 1, unit: PeriodUnit.week));
      expect(period('month', 6), const SubscriptionPeriodValue(numberOfUnits: 6, unit: PeriodUnit.month));
      expect(period('year', 1), const SubscriptionPeriodValue(numberOfUnits: 1, unit: PeriodUnit.year));
      expect(period('fortnight', 1), isNull);
      expect(period('month', 0), isNull);
      expect(period('month', null), isNull);
      expect(period(null, 1), isNull);
    });

    test('pay-as-you-go / pay-up-front offers keep their price and period count', () {
      final payAsYouGo = storeProductDetailsFromDto(
        productDto(
          introPaymentMode: 'payAsYouGo',
          introDisplayPrice: r'$0.99',
          introPeriodUnit: 'month',
          introPeriodValue: 1,
          introPeriodCount: 3,
        ),
      ).introductoryOffer!;
      expect(payAsYouGo.paymentMode, OfferPaymentMode.payAsYouGo);
      expect(payAsYouGo.formattedPrice, r'$0.99');
      expect(payAsYouGo.numberOfPeriods, 3);

      final upFront = storeProductDetailsFromDto(
        productDto(
          introPaymentMode: 'payUpFront',
          introPeriodUnit: 'month',
          introPeriodValue: 3,
        ),
      ).introductoryOffer!;
      expect(upFront.paymentMode, OfferPaymentMode.payUpFront);
      expect(upFront.formattedPrice, '', reason: 'missing display price → empty');
      expect(upFront.numberOfPeriods, 1, reason: 'missing count → 1');
      expect(upFront.period.numberOfUnits, 3);
    });

    test('an unknown mode or a missing intro period yields no offer', () {
      expect(
        storeProductDetailsFromDto(
          productDto(introPaymentMode: 'mystery', introPeriodUnit: 'week', introPeriodValue: 1),
        ).introductoryOffer,
        isNull,
      );
      expect(
        storeProductDetailsFromDto(productDto(introPaymentMode: 'freeTrial'))
            .introductoryOffer,
        isNull,
      );
    });
  });
}
