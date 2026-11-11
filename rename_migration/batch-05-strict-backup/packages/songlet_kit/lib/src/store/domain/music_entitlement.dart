import 'package:meta/meta.dart';

/// Account tier as reported by `/v1/entitlements/sync`.
enum MusicTier {
  free,
  pack,
  pro,
  premier;

  static MusicTier fromWire(String value) => switch (value.toLowerCase()) {
    'pack' => MusicTier.pack,
    'pro' => MusicTier.pro,
    'premier' => MusicTier.premier,
    _ => MusicTier.free,
  };

  bool get hasSubscription => this == pro || this == premier;

  /// Paying user: downloads + commercial license are available (PRD F09).
  bool get isPaid => this != free;
}

/// Server-authoritative allowance (PRD §6.3 sync response): the client never
/// derives entitlement from local transactions.
@immutable
class MusicEntitlement {
  const MusicEntitlement({
    required this.tier,
    required this.songsLeft,
    required this.clipsLeft,
    this.resetAt,
    this.creditsAvailable,
  });

  static const MusicEntitlement unknown = MusicEntitlement(
    tier: MusicTier.free,
    songsLeft: 0,
    clipsLeft: 0,
  );

  final MusicTier tier;
  final int songsLeft;
  final int clipsLeft;
  final DateTime? resetAt;

  /// Music-video credits the account can spend (`credits_available`,
  /// contract gap G5). Optional: null while the platform does not send it —
  /// the settings row and the paywall line stay hidden, and the MV hub reads
  /// the balance from `POST /v1/mv/estimate` instead.
  final int? creditsAvailable;

  bool get canMakeClip => clipsLeft > 0;
  bool get canMakeSong => songsLeft > 0;

  @override
  bool operator ==(Object other) =>
      other is MusicEntitlement &&
      other.tier == tier &&
      other.songsLeft == songsLeft &&
      other.clipsLeft == clipsLeft &&
      other.resetAt == resetAt &&
      other.creditsAvailable == creditsAvailable;

  @override
  int get hashCode =>
      Object.hash(tier, songsLeft, clipsLeft, resetAt, creditsAvailable);

  @override
  String toString() =>
      'MusicEntitlement(${tier.name}, songs: $songsLeft, clips: $clipsLeft, '
      'resetAt: $resetAt, credits: $creditsAvailable)';
}
