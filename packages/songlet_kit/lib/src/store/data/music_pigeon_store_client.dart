import 'dart:async';

import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter/services.dart';

import '../../platform/data/songlet_api.g.dart';
import '../domain/music_entitlement_sync.dart';
import '../domain/music_signed_transaction.dart';

/// commerce_kit's [StoreClient] over the Songlet Pigeon bridge (StoreKit 2 in
/// Swift) instead of the `in_app_purchase` plugin, so the whole purchase
/// orchestration — pending orders, the background reconciler, restore, the
/// funnel — is reused unchanged.
///
/// Differences the orchestrator never notices:
/// * [buy] returns only after StoreKit answered and has already emitted the
///   outcome on [purchaseStream] (the orchestrator registers its claim before
///   calling [buy]), so cancel/pending/error are explicit — the SK2
///   silent-cancel heuristic never has to fire;
/// * every verified JWS (purchase, update, restore) is put in the
///   [MusicSignedTransactionOutbox] before it is announced, so the entitlement sync
///   (`IapRepository.verify` / wallet refresh) always carries it;
/// * [complete] is a no-op: the fixed bridge (PRD §6.4) has no finish call, so
///   Swift finishes verified transactions itself (see StoreKitService.swift).
class MusicPigeonStoreClient implements StoreClient {
  MusicPigeonStoreClient({
    required SongletNativeApi api,
    required Stream<String> transactionUpdates,
    required MusicSignedTransactionOutbox outbox,
    required void Function(String alpha3) onStorefront,
  })  : _api = api,
        _outbox = outbox,
        _onStorefront = onStorefront {
    _updates = transactionUpdates.listen(_onUpdate);
  }

  final SongletNativeApi _api;
  final MusicSignedTransactionOutbox _outbox;
  final void Function(String alpha3) _onStorefront;
  final StreamController<List<StorePurchase>> _events =
      StreamController<List<StorePurchase>>.broadcast();
  late final StreamSubscription<String> _updates;

  void dispose() {
    _updates.cancel();
    _events.close();
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<StoreProductDetails>> queryProducts(Set<String> storeProductIds) async {
    final List<SKProductDto> dtos;
    try {
      dtos = await _api.fetchProducts(storeProductIds.toList(growable: false));
    } on PlatformException catch (e) {
      throw StoreUnavailableException(e.message ?? e.code);
    }
    final storefront = dtos
        .map((d) => d.storefrontCountryCode)
        .firstWhere((c) => c != null && c.isNotEmpty, orElse: () => null);
    if (storefront != null) _onStorefront(storefront);
    return dtos.map(storeProductDetailsFromDto).toList(growable: false);
  }

  @override
  Stream<List<StorePurchase>> get purchaseStream => _events.stream;

  @override
  Future<void> buy({
    required StoreProductDetails product,
    required bool isConsumable,
    String? appAccountToken,
  }) async {
    final PurchaseResultDto result;
    try {
      result = await _api.purchase(product.id, appAccountToken ?? '');
    } on PlatformException catch (e) {
      throw StoreUnavailableException(e.message ?? e.code);
    }
    final signed = result.signedTransaction;
    if (signed != null && signed.isNotEmpty) await _outbox.add(signed);
    _events.add([
      StorePurchase(
        productId: result.productId ?? product.id,
        transactionId: result.transactionId ??
            MusicSignedTransaction.tryParse(signed ?? '')?.transactionId ??
            '',
        status: switch (result.status) {
          'success' => StorePurchaseStatus.purchased,
          'pending' => StorePurchaseStatus.pending,
          'userCancelled' => StorePurchaseStatus.canceled,
          _ => StorePurchaseStatus.error,
        },
        error: result.errorMessage,
      ),
    ]);
  }

  @override
  Future<void> complete(StorePurchase purchase) async {}

  /// Restore = re-read `Transaction.currentEntitlements` (PRD §8.4) and hand
  /// each entitlement to the orchestrator's restore window.
  @override
  Future<void> restore() async {
    final List<String> signed;
    try {
      signed = await _api.currentSignedTransactions();
    } on PlatformException catch (e) {
      throw StoreUnavailableException(e.message ?? e.code);
    }
    final restored = <StorePurchase>[];
    for (final jws in signed) {
      final transaction = MusicSignedTransaction.tryParse(jws);
      if (transaction == null) continue;
      await _outbox.add(jws);
      restored.add(
        StorePurchase(
          productId: transaction.productId,
          transactionId: transaction.transactionId,
          status: StorePurchaseStatus.restored,
        ),
      );
    }
    if (restored.isNotEmpty) _events.add(restored);
  }

  /// `Transaction.updates`: already in the outbox (MusicNativeBridge). Announced as a
  /// purchase so the background reconciler refreshes the server entitlement —
  /// or, when the orchestrator is waiting on this product (Ask-to-Buy approval),
  /// completes its claim.
  void _onUpdate(String jws) {
    final transaction = MusicSignedTransaction.tryParse(jws);
    if (transaction == null) return;
    final storefront = transaction.storefront;
    if (storefront != null) _onStorefront(storefront);
    _events.add([
      StorePurchase(
        productId: transaction.productId,
        transactionId: transaction.transactionId,
        status: StorePurchaseStatus.purchased,
      ),
    ]);
  }
}

/// Maps the bridge's product DTO to commerce_kit's store details (period and
/// App Store Connect introductory offer included).
StoreProductDetails storeProductDetailsFromDto(SKProductDto dto) {
  final period = _period(dto.periodUnit, dto.periodValue);
  final introPeriod = _period(dto.introPeriodUnit, dto.introPeriodValue);
  final introMode = switch (dto.introPaymentMode) {
    'freeTrial' => OfferPaymentMode.freeTrial,
    'payAsYouGo' => OfferPaymentMode.payAsYouGo,
    'payUpFront' => OfferPaymentMode.payUpFront,
    _ => null,
  };
  return StoreProductDetails(
    id: dto.id,
    title: dto.displayName,
    description: dto.productDescription,
    price: dto.displayPrice,
    rawPrice: dto.price,
    currencyCode: dto.currencyCode,
    subscriptionPeriod: period,
    // Only surface an intro offer the user can still redeem (App Review: never
    // advertise a trial the purchase will not grant).
    introductoryOffer: introMode != null &&
            introPeriod != null &&
            dto.isEligibleForIntroOffer
        ? ProductOffer(
            type: OfferType.introductory,
            paymentMode: introMode,
            formattedPrice: introMode == OfferPaymentMode.freeTrial
                ? ''
                : (dto.introDisplayPrice ?? ''),
            rawPrice: 0,
            currencyCode: dto.currencyCode,
            numberOfPeriods: dto.introPeriodCount ?? 1,
            period: introPeriod,
          )
        : null,
  );
}

SubscriptionPeriodValue? _period(String? unit, int? value) {
  if (unit == null || value == null || value <= 0) return null;
  final periodUnit = switch (unit) {
    'day' => PeriodUnit.day,
    'week' => PeriodUnit.week,
    'month' => PeriodUnit.month,
    'year' => PeriodUnit.year,
    _ => null,
  };
  return periodUnit == null
      ? null
      : SubscriptionPeriodValue(numberOfUnits: value, unit: periodUnit);
}
