import 'package:infra_core/infra_core.dart';
import 'package:meta/meta.dart';

import 'order_models.dart';

/// The stage at which a purchase is, or at which it failed.
enum PurchaseStage {
  creatingOrder,
  orderCreated,
  expiryCheck,
  awaitingNative,
  verifying,
  restoring,
}

/// User purchase-session state machine:
/// `idle → creatingOrder → orderCreated → [expiryCheck] → awaitingNative →
/// verifying(1s→2s→4s) → completed`, with `cancelled` / `deferred` /
/// `alreadySubscribed` / `failed(stage)` branches, plus a `restoring` flow.
///
/// Long-lived events (renewal / revocation / Ask-to-Buy approval / re-delivery)
/// are handled by [IapBackgroundReconciler], not here.
@immutable
sealed class IapPurchaseState {
  const IapPurchaseState();

  String? get productCode => switch (this) {
        IapIdle() => null,
        IapRestoring() => null,
        IapRestored() => null,
        IapCreatingOrder(:final productCode) => productCode,
        IapOrderCreated(:final productCode) => productCode,
        IapAwaitingNative(:final productCode) => productCode,
        IapVerifying(:final productCode) => productCode,
        IapCompleted(:final productCode) => productCode,
        IapDeferred(:final productCode) => productCode,
        IapAlreadySubscribed(:final productCode) => productCode,
        IapCancelled(:final productCode) => productCode,
        IapFailed(:final productCode) => productCode,
      };

  /// Actively in flight (drives per-tile button spinners + disables others).
  /// `deferred`/`alreadySubscribed`/`cancelled`/`completed`/`failed` are not.
  bool get isInProgress => switch (this) {
        IapCreatingOrder() ||
        IapOrderCreated() ||
        IapAwaitingNative() ||
        IapVerifying() ||
        IapRestoring() =>
          true,
        _ => false,
      };

  bool isBusyFor(String code) => isInProgress && productCode == code;

  /// Deferred (Ask to Buy / SCA) for [code] — show a "pending approval" hint,
  /// not a spinner or an error.
  bool isDeferredFor(String code) => this is IapDeferred && productCode == code;
}

final class IapIdle extends IapPurchaseState {
  const IapIdle();
}

final class IapRestoring extends IapPurchaseState {
  const IapRestoring();
}

/// Terminal outcome of an explicit, user-initiated restore: [restoredCount]
/// entitlements were restored (0 → "nothing to restore"). Not in progress, so
/// the paywall can surface a clear result instead of silently returning to idle.
final class IapRestored extends IapPurchaseState {
  const IapRestored(this.restoredCount);
  final int restoredCount;
}

final class IapCreatingOrder extends IapPurchaseState {
  const IapCreatingOrder(this.productCode);
  @override
  final String productCode;
}

final class IapOrderCreated extends IapPurchaseState {
  const IapOrderCreated(this.productCode, this.order);
  @override
  final String productCode;
  final CreateOrderResult order;
}

final class IapAwaitingNative extends IapPurchaseState {
  const IapAwaitingNative(this.productCode, this.order);
  @override
  final String productCode;
  final CreateOrderResult order;
}

final class IapVerifying extends IapPurchaseState {
  const IapVerifying(this.productCode, this.order, this.attempt);
  @override
  final String productCode;
  final CreateOrderResult order;
  final int attempt;
}

final class IapCompleted extends IapPurchaseState {
  const IapCompleted(this.productCode, {this.subscription});
  @override
  final String productCode;
  final OrderSubscription? subscription;
}

/// Native purchase is pending external approval (Ask to Buy / family / SCA).
/// Loading is released; the [IapBackgroundReconciler] completes it later.
final class IapDeferred extends IapPurchaseState {
  const IapDeferred(this.productCode);
  @override
  final String productCode;
}

/// Pre-purchase gate: the subscription group is already active — route the user
/// to "manage subscription" instead of creating a duplicate order.
final class IapAlreadySubscribed extends IapPurchaseState {
  const IapAlreadySubscribed(this.productCode);
  @override
  final String productCode;
}

/// User cancellation — **not** an error (no dialog; restore the button).
final class IapCancelled extends IapPurchaseState {
  const IapCancelled(this.productCode);
  @override
  final String productCode;
}

final class IapFailed extends IapPurchaseState {
  const IapFailed({
    required this.productCode,
    required this.stage,
    required this.failure,
  });
  @override
  final String productCode;
  final PurchaseStage stage;
  final Failure failure;
}
