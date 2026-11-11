import 'package:meta/meta.dart';

import 'iap_models.dart';

enum StorePurchaseStatus { pending, purchased, restored, canceled, error }

/// A normalized purchase event from the native store.
@immutable
class StorePurchase {
  const StorePurchase({
    required this.productId,
    required this.transactionId,
    required this.status,
    this.error,
  });

  final String productId;
  final String transactionId;
  final StorePurchaseStatus status;
  final String? error;

  bool get isTerminal => status != StorePurchaseStatus.pending;

  bool get isSuccessful =>
      status == StorePurchaseStatus.purchased ||
      status == StorePurchaseStatus.restored;
}

/// Forward-compat signal for a native cancel. **Not thrown on the locked plugin
/// (`in_app_purchase_storekit` 0.4.10)** — it discards SK2's `.userCancelled` and
/// returns true with no stream event, so the orchestrator detects a cancel via a
/// stream-silence window. Kept for plugin versions that surface the cancel as
/// `PlatformException(storekit2_purchase_cancelled)`; if/when they do,
/// `InAppPurchaseStoreClient.buy` re-throws this and the orchestrator routes to
/// `cancelled`. See `store_client_impl.dart` for the full rationale.
class StorePurchaseCancelledException implements Exception {
  const StorePurchaseCancelledException();
}

class StoreUnavailableException implements Exception {
  const StoreUnavailableException(this.message);
  final String message;

  @override
  String toString() => 'StoreUnavailableException: $message';
}

/// Abstraction over `in_app_purchase` so the orchestrator is testable and the
/// SK2-cancel handling lives in the data layer.
abstract interface class StoreClient {
  Future<bool> isAvailable();

  Future<List<StoreProductDetails>> queryProducts(Set<String> storeProductIds);

  /// Broadcast stream of purchase updates (including re-delivered unfinished
  /// transactions on startup).
  Stream<List<StorePurchase>> get purchaseStream;

  /// Initiates a purchase. Results arrive via [purchaseStream]; an SK2 cancel is
  /// silent on 0.4.10 (see [StorePurchaseCancelledException]).
  ///
  /// [appAccountToken] (a UUID) is attached to the StoreKit 2 purchase as its
  /// `appAccountToken`, which Apple echoes on the transaction and every S2S
  /// notification so the backend can map it straight to the account. It MUST be a
  /// valid UUID — StoreKit silently drops a non-UUID — so callers pass the account
  /// BID (or null to omit).
  Future<void> buy({
    required StoreProductDetails product,
    required bool isConsumable,
    String? appAccountToken,
  });

  /// Finishes a transaction. Call **only** after server verification succeeds.
  Future<void> complete(StorePurchase purchase);

  Future<void> restore();
}
