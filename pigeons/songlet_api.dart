// Pigeon source of the Songlet native bridge — PRD §6.4, verbatim.
//
// Regenerate (from the repo root):
//   dart run pigeon --input pigeons/songlet_api.dart
//
// The two host/flutter API surfaces below are copied from PRD §6.4 without
// change (method names, parameter names/types, @async markers). PRD §6.4 names
// `SKProductDto` / `PurchaseResultDto` without spelling out their fields; they
// are defined here. Semantics the fixed signatures cannot express are pinned in
// the doc comments (and mirrored in the Swift implementation):
//
// * `playAudio(path, loop)` is the only playback call: a new `path` starts it
//   from 0; the currently loaded `path` toggles pause/resume; an empty `path`
//   stops and releases the player.
// * `onPlaybackProgress(seconds)` reports the position (≥ 0) while playing,
//   plus two sentinels: -1 (paused) and -2 (ended) — the
//   lock-screen / Control Center commands change state natively, so Flutter
//   learns about them only through this callback.
// * `appAttestAssertion(challenge)` returns a JSON object string
//   `{"key_id","attestation"}` on the first call for a key,
//   `{"key_id","assertion"}` afterwards, or `{"unsupported":true}` where App
//   Attest is unavailable (simulator).
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'packages/songlet_kit/lib/src/platform/data/songlet_api.g.dart',
    dartOptions: DartOptions(),
    swiftOut: 'ios/Runner/SongletApi.g.swift',
    swiftOptions: SwiftOptions(),
    dartPackageName: 'songlet_kit',
  ),
)

/// A StoreKit 2 `Product` flattened for Dart.
class SKProductDto {
  SKProductDto({
    required this.id,
    required this.displayName,
    required this.productDescription,
    required this.displayPrice,
    required this.price,
    required this.currencyCode,
    required this.type,
    required this.isEligibleForIntroOffer,
  });

  String id;
  String displayName;
  String productDescription;

  /// Localized, formatted price (`Product.displayPrice`).
  String displayPrice;
  double price;
  String currencyCode;

  /// `autoRenewable` | `consumable` | `nonConsumable` | `nonRenewable`.
  String type;

  /// Subscription period (`day`|`week`|`month`|`year` × value), null otherwise.
  String? periodUnit;
  int? periodValue;

  /// Introductory offer: `freeTrial` | `payAsYouGo` | `payUpFront`.
  String? introPaymentMode;
  String? introDisplayPrice;
  String? introPeriodUnit;
  int? introPeriodValue;
  int? introPeriodCount;

  /// `Product.SubscriptionInfo.isEligibleForIntroOffer` (false when unknown).
  bool isEligibleForIntroOffer;

  /// App Store storefront country, ISO 3166-1 alpha-3 (`Storefront.current`).
  String? storefrontCountryCode;
}

/// Outcome of `Product.purchase(options: [.appAccountToken(...)])`.
class PurchaseResultDto {
  PurchaseResultDto({required this.status});

  /// `success` | `pending` | `userCancelled` | `failed`.
  String status;

  /// The verified transaction's JWS (`VerificationResult.jwsRepresentation`).
  String? signedTransaction;
  String? transactionId;
  String? productId;

  /// Diagnostic only (never user copy).
  String? errorMessage;
}

@HostApi()
abstract class SongletNativeApi {
  @async List<SKProductDto> fetchProducts(List<String> ids);
  @async PurchaseResultDto purchase(String productId, String appAccountToken);
  @async List<String> currentSignedTransactions();
  @async String appAttestAssertion(String challenge);
  @async List<Uint8List> pickPhotos(int max);           // 已压缩 JPEG
  @async void playAudio(String path, bool loop);
  @async void exportToFiles(String path, String name);
  @async String polishPrompt(String raw, String locale); // SystemLanguageModel
}

@FlutterApi()
abstract class SongletFlutterApi {
  void onPlaybackProgress(double seconds);
  void onTransactionUpdated(String signedTransaction);
}
