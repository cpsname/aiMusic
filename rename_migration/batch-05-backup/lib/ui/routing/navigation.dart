import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:songlet_kit/songlet_kit.dart';

import 'routes.dart';

/// Typed navigation on top of go_router (ADR-0003).
extension AppNavigation on BuildContext {
  /// Replaces the current location (tab-level and deep-link navigation).
  void goTo(AppRoute route) => go(route.location);

  /// Pushes a page without waiting for its result.
  void open(AppRoute route) => unawaited(push<void>(route.location));

  /// Pushes a page; resolves with the value it pops.
  Future<T?> pushTo<T extends Object?>(AppRoute route) =>
      push<T>(route.location);

  /// Opens the paywall (P08); true when a purchase or restore completed.
  /// [productId] preselects a product (the pack a credit gap recommended);
  /// [offer] says whether the plans or the credit packs lead (a
  /// `QUOTA_EXHAUSTED`'s `offer`; null = the plans).
  Future<bool> openPaywall(
    PaywallReason reason, {
    String? productId,
    QuotaOffer? offer,
  }) async =>
      await push<bool>(
        PaywallRoute(
          reason: reason,
          productId: productId,
          offer: offer,
        ).location,
      ) ??
      false;
}
