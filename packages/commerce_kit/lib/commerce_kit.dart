/// commerce_kit — commercialization core.
///
/// Auth (guest-register HMAC chain, login/refresh/logout, `/me` aggregation),
/// IAP (`/app/init`, order create/verify, StoreKit 2 purchase orchestrator),
/// and wallet (balance + feature gating). Layered domain / data / application
/// with hand-written Riverpod providers. Depends only on infra_core.
///
/// The domain interfaces (auth / account / wallet / IAP repositories, the
/// store client) are exported so an app can bind its own backend or store
/// bridge through the provider overrides, reusing every controller unchanged.
///
/// Consumers import `package:commerce_kit/commerce_kit.dart`.
library;

export 'src/auth/application/auth_controller.dart' show AuthController;
export 'src/auth/application/auth_providers.dart';
export 'src/auth/domain/account_repository.dart';
export 'src/auth/domain/auth_phase.dart';
export 'src/auth/domain/auth_repository.dart';
export 'src/auth/domain/auth_session.dart';
export 'src/auth/domain/current_account.dart';
export 'src/auth/domain/jwt.dart' show JwtClaims, JwtUtils;
export 'src/common/billing.dart';
export 'src/iap/application/iap_background_reconciler.dart'
    show IapBackgroundReconciler;
export 'src/iap/application/iap_providers.dart';
export 'src/iap/application/iap_purchase_orchestrator.dart'
    show IapPurchaseOrchestrator;
export 'src/iap/application/iap_verifier.dart' show IapVerifier;
export 'src/iap/application/startup_controller.dart';
export 'src/iap/domain/iap_models.dart';
export 'src/iap/domain/iap_repository.dart';
export 'src/iap/domain/order_models.dart';
export 'src/iap/domain/product_merge_service.dart';
export 'src/iap/domain/product_query_result.dart';
export 'src/iap/domain/purchase_state.dart';
export 'src/iap/domain/store_client.dart';
export 'src/iap/domain/store_offer.dart';
export 'src/iap/domain/subscription_entitlement.dart';
export 'src/wallet/application/wallet_providers.dart';
export 'src/wallet/domain/wallet_repository.dart';
