import 'package:meta/meta.dart';

import 'music_mv.dart';

/// A video the user asked for that the platform refused for credits
/// (`QUOTA_EXHAUSTED`, docs/ui P22; ADR-0023). Kept across the StoreKit sheet
/// — and an app restart in between — so the same request is sent again once
/// the recommended pack is bought, without the user re-entering anything.
///
/// A refused create charged nothing, so resending it can never double charge;
/// the same `client_ref` is still reused while the intent is fresh so a create
/// the platform did accept (the reply was lost) is returned, not made twice.
@immutable
class MusicMvIntent {
  const MusicMvIntent({required this.workId, required this.request, required this.createdAt});

  /// Past this age the intent is resent under a new `client_ref`: the
  /// refused attempt left nothing to deduplicate against, and the platform's
  /// idempotency window must not turn an old refusal into a stale answer.
  static const Duration freshFor = Duration(minutes: 60);

  final String workId;

  /// Photos already uploaded: the request carries their bids (valid 24 h).
  final MusicMvRequest request;
  final DateTime createdAt;

  bool isFresh(DateTime now) => now.difference(createdAt) <= freshFor;
}

/// The one pending [MusicMvIntent] of this device (a second refusal replaces it).
abstract interface class MusicMvIntentStore {
  MusicMvIntent? read();

  Future<void> save(MusicMvIntent intent);

  Future<void> clear();
}
