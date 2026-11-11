import 'package:infra_core/infra_core.dart';

/// Which page a `QUOTA_EXHAUSTED` asks the client to open (contract 02 v2.1:
/// `details.offer`, and `offer` on the music-video estimate). Everything costs
/// credits; the server knows whether the account should be offered a plan or a
/// pack.
enum QuotaOffer {
  /// A subscription: the paywall leads with the plans, Weekly Pro preselected,
  /// the packs listed below.
  subscription('subscription'),

  /// Credit packs: the paywall leads with the packs (the recommended one
  /// preselected) and keeps a "see subscriptions" entry at the bottom.
  packs('packs');

  const QuotaOffer(this.wire);

  final String wire;

  static QuotaOffer? fromWire(String? value) {
    for (final offer in values) {
      if (offer.wire == value) return offer;
    }
    return null;
  }

  /// The offer a `QUOTA_EXHAUSTED` [failure] carries, or null when the
  /// envelope has only the error code (the paywall then opens on the plans,
  /// with the packs listed too).
  static QuotaOffer? of(Failure failure) {
    if (failure.errorCode != 'QUOTA_EXHAUSTED') return null;
    return fromWire(failure.details['offer']);
  }
}
