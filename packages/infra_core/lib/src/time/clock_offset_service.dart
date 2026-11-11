/// In-process clock-skew correction for request signing.
///
/// HMAC request signatures are computed over `timestamp + nonce +
/// canonicalJson(body)`, so a device clock that is off by minutes makes **every**
/// signed request fall outside the server's time window — a failure that is
/// invisible offline (dev machines have accurate clocks) and only erupts in the
/// field. This service holds the offset between the device clock and authoritative
/// server time (learned from the `X-Server-Time` response header) and hands the
/// signer a corrected [now].
///
/// The offset is **never persisted**: a stale offset is worse than none, so it is
/// recomputed from the first server response of each session. Before the first
/// sync the offset is zero (local time) — correct for a healthy clock, and
/// repaired in-flight by the cold-start re-sign-once path (see
/// `ClockSyncInterceptor`).
class ClockOffsetService {
  ClockOffsetService({DateTime Function()? deviceClock})
      : _deviceClock = deviceClock ?? DateTime.now;

  final DateTime Function() _deviceClock;

  Duration _offset = Duration.zero;
  bool _hasOffset = false;

  /// Whether an authoritative server time has been observed this session.
  bool get hasOffset => _hasOffset;

  /// The current device→server offset (zero until the first sync).
  Duration get offset => _offset;

  /// The raw, uncorrected device clock.
  DateTime deviceNow() => _deviceClock();

  /// Server-corrected wall clock: device now + learned offset. This is what the
  /// signer must use for the request timestamp.
  DateTime now() => _deviceClock().add(_offset);

  /// Learns the offset from one server timestamp using the NTP single-sample
  /// estimate, which folds in RTT/2 compensation:
  ///
  ///     offset = serverTime − midpoint(sentAt, receivedAt)
  ///
  /// [serverEpochMillis] is the server's wall clock (Unix ms, UTC). [sentAt] and
  /// [receivedAt] are device-clock instants bracketing the round trip. A later
  /// call slides the offset to the newest observation.
  void syncFromRoundTrip({
    required int serverEpochMillis,
    required DateTime sentAt,
    required DateTime receivedAt,
  }) {
    final deviceMidpoint = sentAt.add(receivedAt.difference(sentAt) ~/ 2);
    final serverTime = DateTime.fromMillisecondsSinceEpoch(
      serverEpochMillis,
      isUtc: true,
    );
    _offset = serverTime.difference(deviceMidpoint);
    _hasOffset = true;
  }
}
