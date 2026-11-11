import 'package:meta/meta.dart';

import 'mv.dart';

/// A video the user asked for that the platform refused for credits
/// (`QUOTA_EXHAUSTED`, docs/ui P22; ADR-0023). Kept across the StoreKit sheet
/// — and an app restart in between — so the same request is sent again once
/// the recommended pack is bought, without the user re-entering anything.
///
/// A refused create charged nothing, so resending it can never double charge;
/// the same `client_ref` is still reused while the intent is fresh so a create
/// the platform did accept (the reply was lost) is returned, not made twice.
@immutable
class MvIntent {
  const MvIntent({required this.workId, required this.request, required this.createdAt});

  /// Past this age the intent is resent under a new `client_ref`: the
  /// refused attempt left nothing to deduplicate against, and the platform's
  /// idempotency window must not turn an old refusal into a stale answer.
  static const Duration freshFor = Duration(minutes: 60);

  final String workId;

  /// Photos already uploaded: the request carries their bids (valid 24 h).
  final MvRequest request;
  final DateTime createdAt;

  bool isFresh(DateTime now) => now.difference(createdAt) <= freshFor;
}

/// The one pending [MvIntent] of this device (a second refusal replaces it).
abstract interface class MvIntentStore {
  MvIntent? read();

  Future<void> save(MvIntent intent);

  Future<void> clear();
}
