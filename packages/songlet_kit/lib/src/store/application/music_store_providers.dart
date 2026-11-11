import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:commerce_kit/commerce_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../identity/data/music_attest_auth_repository.dart';
import '../../platform/application/music_platform_providers.dart';
import '../data/music_entitlement_remote_impl.dart';
import '../data/music_kv_signed_transaction_outbox.dart';
import '../data/music_pigeon_store_client.dart';
import '../data/music_account_repositories.dart';
import '../data/music_iap_repository.dart';
import '../data/music_storefront_store.dart';
import '../domain/music_entitlement_sync.dart';
import '../domain/music_catalog.dart';
import '../domain/music_entitlement.dart';
import 'music_storefront_controller.dart';

/// Songlet's entitlement composition root. Everything commerce-related runs on
/// commerce_kit's controllers (purchase orchestrator, background reconciler,
/// auth controller, wallet/account providers); [songletKitOverrides] binds them
/// to Songlet's store bridge and backend.

final signedTransactionOutboxProvider = Provider<MusicSignedTransactionOutbox>(
  (ref) => MusicKvSignedTransactionOutbox(ref.watch(keyValueStoreProvider)),
);

final storefrontStoreProvider = Provider<MusicStorefrontStore>(
  (ref) => MusicStorefrontStore(ref.watch(keyValueStoreProvider)),
);

final storefrontProvider = NotifierProvider<MusicStorefrontController, String?>(
  MusicStorefrontController.new,
);

/// Device region (ISO alpha-2) — the iOS Region setting (`NSLocale.current`,
/// e.g. `en_RU`), independent of the language list — the second half of the
/// region double-check (PRD §11.3). Overridable in tests.
final deviceRegionProvider = Provider<String?>((ref) {
  final parts = Platform.localeName.split('@').first.split(RegExp('[_-]'));
  final region = parts.length > 1 && parts.last.length == 2
      ? parts.last.toUpperCase()
      : null;
  return region ?? PlatformDispatcher.instance.locale.countryCode;
});

/// Pricing tier of the current storefront (PRD §8.3 allowances).
final pricingTierProvider = Provider<MusicPricingTier>(
  (ref) => MusicCatalog.tierForStorefront(ref.watch(storefrontProvider)),
);

/// `app_account_token`: the persistent Keychain device UUID.
final appAccountTokenSourceProvider = Provider<Future<String> Function()>((
  ref,
) {
  final deviceInfo = ref.watch(deviceInfoServiceProvider);
  return () async => (await deviceInfo.load()).deviceId;
});

final entitlementSyncProvider = Provider<MusicEntitlementSync>(
  (ref) => MusicEntitlementSync(
    remote: MusicEntitlementRemoteImpl(ref.watch(apiDioProvider)),
    source: ref.watch(nativeBridgeProvider),
    outbox: ref.watch(signedTransactionOutboxProvider),
    appAccountToken: ref.watch(appAccountTokenSourceProvider),
  ),
);

/// Server-authoritative allowance (tier, songs / clips left, reset). Refreshes
/// with commerce_kit's wallet snapshot — i.e. on startup, purchase / restore,
/// `Transaction.updates`, app foreground and after every generation.
///
/// Waits for the device to be attested (the shell is shown before startup's
/// network half finishes, PRD §6.5 offline library): until then it stays
/// loading, and an attestation failure surfaces as its error.
final musicEntitlementProvider = FutureProvider<MusicEntitlement>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (auth is AuthError) throw auth.failure;
  if (auth is! AuthAuthenticated) return Completer<MusicEntitlement>().future;
  // A snapshot fetched before the device token existed failed terminally
  // (errors are not auto-retried); fetch again now that it can succeed.
  if (ref.read(walletSnapshotProvider).hasError)
    ref.invalidate(walletSnapshotProvider);
  await ref.watch(walletSnapshotProvider.future);
  return ref.read(entitlementSyncProvider).latest ?? MusicEntitlement.unknown;
});

/// Riverpod overrides songlet_kit contributes to the root `ProviderScope`
/// (includes commerce_kit's own [commerceKitOverrides]).
/// Paths the client calls on the platform (`PLATFORM_BASE_URL`, falling back
/// to `BASE_URL`); everything else goes to the product backend at `BASE_URL`.
const List<String> songletPlatformPaths = ['/app/config'];

List<Override> songletKitOverrides() => <Override>[
  ...commerceKitOverrides(),
  endpointRoutesProvider.overrideWith((ref) {
    final platform = ref.watch(envConfigProvider).effectivePlatformBaseUrl;
    return [for (final p in songletPlatformPaths) EndpointRoute(p, platform)];
  }),
  storeClientProvider.overrideWith((ref) {
    final bridge = ref.watch(nativeBridgeProvider);
    final client = MusicPigeonStoreClient(
      api: bridge.api,
      transactionUpdates: bridge.transactionUpdates,
      outbox: ref.watch(signedTransactionOutboxProvider),
      onStorefront: (alpha3) =>
          ref.read(storefrontProvider.notifier).remember(alpha3),
    );
    ref.onDispose(client.dispose);
    return client;
  }),
  iapRepositoryProvider.overrideWith((ref) {
    final env = ref.watch(envConfigProvider);
    return MusicIapRepository(
      sync: ref.watch(entitlementSyncProvider),
      legal: LegalInfo(termsUrl: env.termsUrl, privacyUrl: env.privacyUrl),
    );
  }),
  walletRepositoryProvider.overrideWith(
    (ref) => MusicWalletRepository(ref.watch(entitlementSyncProvider)),
  ),
  accountRepositoryProvider.overrideWith(
    (ref) => MusicAccountRepository(
      ref.watch(entitlementSyncProvider),
      accountToken: ref.watch(appAccountTokenSourceProvider),
    ),
  ),
  authRepositoryProvider.overrideWith(
    (ref) => MusicAttestAuthRepository(
      authDio: ref.watch(authDioProvider),
      attestation: ref.watch(attestationProvider),
      deviceInfo: ref.watch(deviceInfoServiceProvider),
    ),
  ),
  // Restored entitlements are emitted before `restore()` returns.
  restoreDrainWindowProvider.overrideWithValue(
    const Duration(milliseconds: 300),
  ),
  requestMetaHeadersProvider.overrideWith(
    (ref) => <String, String>{
      'X-Storefront': ref.watch(storefrontProvider) ?? '',
      'X-Device-Region': ref.watch(deviceRegionProvider) ?? '',
    },
  ),
];
