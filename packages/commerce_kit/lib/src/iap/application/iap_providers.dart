import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';

import '../../auth/application/auth_providers.dart';
import '../../auth/domain/jwt.dart';
import '../data/app_init_cache.dart';
import '../data/iap_repository_impl.dart';
import '../data/pending_order_store.dart';
import '../data/product_cache.dart';
import '../data/store_client_impl.dart';
import '../domain/iap_models.dart';
import '../domain/iap_repository.dart';
import '../domain/pending_order_repository.dart';
import '../domain/product_merge_service.dart';
import '../domain/product_query_result.dart';
import '../domain/purchase_state.dart';
import '../domain/store_client.dart';
import '../domain/subscription_entitlement.dart';
import 'iap_background_reconciler.dart';
import 'iap_purchase_orchestrator.dart';
import 'iap_verifier.dart';
import 'startup_controller.dart';

final iapRepositoryProvider = Provider<IapRepository>(
  (ref) => IapRepositoryImpl(
    authDio: ref.watch(authDioProvider),
    apiDio: ref.watch(apiDioProvider),
    distributionCode: ref.watch(envConfigProvider).distributionCode,
  ),
);

final storeClientProvider = Provider<StoreClient>(
  (ref) => InAppPurchaseStoreClient(),
);

final pendingOrderRepositoryProvider = Provider<PendingOrderRepository>(
  (ref) => PendingOrderStore(ref.watch(keyValueStoreProvider)),
);

/// Verify back-off delays (1s → 2s → 4s). Overridable in tests.
final iapVerifyBackoffProvider = Provider<List<Duration>>(
  (ref) => const [Duration(seconds: 1), Duration(seconds: 2), Duration(seconds: 4)],
);

/// SK2 silent-cancel detection window. The locked plugin (`in_app_purchase_storekit`
/// 0.4.10) discards `SK2Product.purchase()`'s cancel result and returns true with
/// no `purchaseStream` event, so a user-cancel is invisible. If nothing arrives
/// within this window after `buy()` returns, the orchestrator treats it as a
/// cancel (retaining the pending order for reconciliation). Success/pending events
/// arrive in milliseconds, well inside it. Overridable in tests.
final sk2CancelDetectorWindowProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 3),
);

/// Upper bound on the native purchase call (`StoreClient.buy`). The App Store
/// sheet (sign-in, Face ID, confirmation) normally answers well within it; a
/// call that never returns (no sheet presented) must not leave the paywall
/// busy forever. On expiry the flow fails at `awaitingNative` with the pending
/// order **retained**, so a late success is still reconciled by
/// [IapBackgroundReconciler]. Overridable in tests.
final nativePurchaseTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(minutes: 5),
);

/// Drain window for an explicit restore. Restored transactions arrive on the
/// purchase stream **asynchronously** after `restore()` returns: the native
/// per-entitlement callbacks and the method-completion reply travel on separate
/// channels with no cross-channel ordering, so the events can land just after
/// the call resolves. The orchestrator waits this long to collect them before
/// verifying. Overridable in tests.
final restoreDrainWindowProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 3),
);

/// Injectable clock for order-expiry checks.
final iapClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Shared verify→finish kernel for the orchestrator + reconciler.
final iapVerifierProvider = Provider<IapVerifier>(
  (ref) => IapVerifier(
    repository: ref.watch(iapRepositoryProvider),
    backoff: ref.watch(iapVerifyBackoffProvider),
  ),
);

/// App-level long-lived reconciler. Reading it starts the persistent listener;
/// the startup sequence reads it so it is active for the whole app lifecycle.
final iapReconcilerProvider = Provider<IapBackgroundReconciler>((ref) {
  final reconciler = IapBackgroundReconciler(ref)..start();
  return reconciler;
});

/// Server-authoritative subscription entitlement (from `/me`). UI gates on this,
/// never on local transactions.
final subscriptionEntitlementProvider = Provider<SubscriptionEntitlement>((ref) {
  final account = ref.watch(currentAccountProvider).value;
  return SubscriptionEntitlement.fromSubscription(account?.subscription);
});

/// Persistent `/app/init` cache (products + legal), invalidated on a device
/// reboot or app upgrade. See [AppInitCache].
final appInitCacheProvider = Provider<AppInitCache>(
  (ref) => AppInitCache(
    store: ref.watch(keyValueStoreProvider),
    bootClock: ref.watch(deviceBootClockProvider),
  ),
);

/// `/app/init` result, cache-first: served from the persistent cache within a
/// boot session; fetched (and cached) on the first launch after a reboot/upgrade
/// or on a cache miss. The single source for startup + the paywall, so
/// `/app/init` is hit at most once per language per boot session.
final appInitProvider = FutureProvider<AppInitData>((ref) async {
  final languageTag = ref.watch(languageTagProvider);
  final profile = await ref.watch(deviceProfileProvider.future);
  if (!ref.mounted) throw StateError('Obsolete app-init request');
  final cache = ref.read(appInitCacheProvider);
  final cached = await cache.read(appVersion: profile.appVersion, languageTag: languageTag);
  if (!ref.mounted) throw StateError('Obsolete app-init request');
  if (cached != null) return cached;
  final fresh = await ref
      .read(iapRepositoryProvider)
      .appInit(clientVersion: profile.appVersion);
  if (!ref.mounted) throw StateError('Obsolete app-init response');
  await cache.write(fresh, appVersion: profile.appVersion, languageTag: languageTag);
  return fresh;
});

/// Backend product catalog (visible + active, in display order).
final iapCatalogProvider = Provider<List<Product>>(
  (ref) {
    final init = ref.watch(appInitProvider);
    return init.isLoading ? const <Product>[] : init.value?.visibleProducts ?? const <Product>[];
  },
);

/// Legal links (privacy / terms / subscription terms) from `/app/init`, exposed
/// for consumers (paywall footer / settings). Null until init resolves.
final legalInfoProvider = Provider<LegalInfo?>(
  (ref) {
    final init = ref.watch(appInitProvider);
    return init.isLoading ? null : init.value?.legal;
  },
);

/// Pure merge of the backend catalog with live store details.
final productMergeServiceProvider = Provider<ProductMergeService>(
  (ref) => const ProductMergeService(),
);

/// Persistent cache of merged products — the offline / query-failure fallback.
final productCacheProvider = Provider<ProductCache>(
  (ref) => ProductCache(store: ref.watch(keyValueStoreProvider)),
);

/// Catalog ∩ live, localized store details (StoreKit / Play). The store is the
/// authoritative source for names, prices, and App Store Connect offers (intro /
/// promo / free trial). A catalog product the store can't resolve is reported in
/// `unavailableIds` and **not shown** — an unpurchasable product is never faked
/// with a backend price. On a store-query failure the last good cache is served
/// (flagged stale); with no cache the error surfaces so the paywall offers retry.
final storeCatalogQueryProvider =
    FutureProvider<ProductQueryResult>((ref) async {
  final languageTag = ref.watch(languageTagProvider);
  final init = await ref.watch(appInitProvider.future);
  if (!ref.mounted) throw StateError('Obsolete store-catalog request');
  final catalog = init.visibleProducts;
  if (catalog.isEmpty) return const ProductQueryResult(products: []);

  final cache = ref.read(productCacheProvider);
  final merge = ref.read(productMergeServiceProvider);
  try {
    final ids = catalog.map((p) => p.storeProductId).toSet();
    final details = await ref.watch(storeClientProvider).queryProducts(ids);
    if (!ref.mounted) throw StateError('Obsolete store-catalog response');
    final result = merge.merge(
      catalog: catalog,
      storeDetails: details,
      queriedAt: ref.read(iapClockProvider)(),
    );
    if (result.products.isNotEmpty) {
      unawaited(cache.write(result.products, languageTag: languageTag));
    }
    return result;
  } on Object {
    final cached = cache.read(languageTag: languageTag);
    if (cached != null && cached.products.isNotEmpty) return cached;
    rethrow;
  }
});

/// Products to render on the paywall (merged catalog ∩ store, display order).
final storeProductsProvider = FutureProvider<List<StoreProduct>>(
  (ref) async => (await ref.watch(storeCatalogQueryProvider.future)).products,
);

/// Catalog `storeProductId`s the store couldn't resolve (dropped from the list).
final unavailableProductIdsProvider = Provider<List<String>>(
  (ref) =>
      ref.watch(storeCatalogQueryProvider).value?.unavailableIds ?? const [],
);

/// The account BID (a UUID) attached to a purchase as StoreKit's
/// `appAccountToken` and sent as the create-order `push_token`, so Apple echoes
/// it on every S2S notification and the backend maps the transaction to the
/// account directly (instead of reverse-looking-up by `originalTransactionId`).
///
/// Resolved from the authenticated session's `abid` claim; **null** when there is
/// no token or it is not a valid UUID — StoreKit silently drops a non-UUID
/// `appAccountToken`, so we omit it rather than send a useless value. Rebuilds on
/// account switch (login / logout / guest upgrade). Overridable in tests.
final appAccountTokenProvider = Provider<String?>((ref) {
  ref.watch(authControllerProvider); // re-resolve when the account changes
  return appAccountTokenFromAccessToken(ref.read(authGatewayProvider).accessToken);
});

/// The account BID (`abid` claim) from an access [token], or null when there is
/// no token or the id is not a valid UUID. Reads `abid` **specifically** (not the
/// `subject`'s `sub` fallback): the backend maps the webhook `appAccountToken`
/// directly to the account by `abid` (BACKEND_COORDINATION §3.1), so a standard
/// `sub` is not interchangeable — when `abid` is absent we send nothing and let
/// the backend fall back to its `originalTransactionId` reverse-lookup. Pure +
/// testable; backs [appAccountTokenProvider].
String? appAccountTokenFromAccessToken(String? token) {
  if (token == null || token.isEmpty) return null;
  final abid = JwtUtils.decode(token).abid;
  return (abid != null && _isUuid(abid)) ? abid : null;
}

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool _isUuid(String value) => _uuidPattern.hasMatch(value);

final iapPurchaseOrchestratorProvider =
    NotifierProvider<IapPurchaseOrchestrator, IapPurchaseState>(
  IapPurchaseOrchestrator.new,
);

final startupControllerProvider =
    NotifierProvider<StartupController, StartupState>(StartupController.new);
