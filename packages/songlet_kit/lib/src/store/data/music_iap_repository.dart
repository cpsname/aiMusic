import 'package:commerce_kit/commerce_kit.dart';
import 'package:uuid/uuid.dart';

import '../domain/music_entitlement_sync.dart';
import '../domain/music_catalog.dart';

/// commerce_kit's [IapRepository] for Songlet's backend (PRD §6.3), which has
/// no order endpoints — the ledger is fed by `/v1/entitlements/sync`:
/// * [appInit] → the fixed PRD §8.1 catalog + the legal links (no network);
/// * [createOrder] → a **local** order, so the orchestrator's invariant
///   "persist the pending order before the native purchase" still protects an
///   interrupted purchase;
/// * [verify] → an entitlement sync carrying the transaction's JWS (already in
///   the outbox); success = the ledger accepted it.
class MusicIapRepository implements IapRepository {
  MusicIapRepository({
    required MusicEntitlementSync sync,
    required LegalInfo legal,
    DateTime Function()? now,
    Uuid uuid = const Uuid(),
  }) : _sync = sync,
       _legal = legal,
       _now = now ?? DateTime.now,
       _uuid = uuid;

  /// A local order stays valid this long before the orchestrator refuses it.
  static const Duration orderValidity = Duration(hours: 1);

  final MusicEntitlementSync _sync;
  final LegalInfo _legal;
  final DateTime Function() _now;
  final Uuid _uuid;

  @override
  Future<AppInitData> appInit({String? clientVersion}) async =>
      AppInitData(products: MusicCatalog.products(), legal: _legal);

  @override
  Future<CreateOrderResult> createOrder({
    required String distributionCode,
    required String productCode,
    String? pushToken,
  }) async => CreateOrderResult(
    orderNo: 'local-${_uuid.v4()}',
    productCode: productCode,
    storeProductId: productCode,
    amountCents: 0,
    currency: '',
    expiresAt: _now().toUtc().add(orderValidity),
  );

  @override
  Future<VerifyResult> verify({
    required String orderNo,
    required String transactionId,
  }) async {
    await _sync.sync();
    return VerifyResult(
      orderNo: orderNo,
      status: 'completed',
      grantStatus: 'granted',
    );
  }
}
