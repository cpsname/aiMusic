import 'package:infra_core/infra_core.dart';

/// PRD §6.5 error codes (+ `DOWNLOAD_LOCKED`, the license/download refusal of
/// PRD §8.4 refunds), with the monolith envelope `code` each travels with
/// (docs/songlet/backend-contract.md §4).
enum MusicErrorCode {
  safetyBlocked('SAFETY_BLOCKED', 45101),
  quotaExhausted('QUOTA_EXHAUSTED', 49303),
  upstreamTimeout('UPSTREAM_TIMEOUT', 50401),
  upstreamRateLimited('UPSTREAM_RATE_LIMITED', 42901),
  regionUnavailable('REGION_UNAVAILABLE', 45103),
  attestFailed('ATTEST_FAILED', 40140),
  imageRejected('IMAGE_REJECTED', 45102),
  networkOffline('NETWORK_OFFLINE', 0),
  downloadLocked('DOWNLOAD_LOCKED', 40310),

  /// `DELETE /v1/jobs/{id}` lost the race: the job already finished (contract
  /// v2 §3). Carried on HTTP 200 like every 49300–49349 business code, and
  /// matched by its string — its numeric class maps to no specific [ApiError].
  jobAlreadyFinished('JOB_ALREADY_FINISHED', 49309),

  // ── Music videos (contract v1.1 §4, PRD ch.15) ──────────────────────────

  /// The song is not `succeeded`, has no audio, or cannot be locked.
  mvSongNotReady('MV_SONG_NOT_READY', 49312),

  /// Over the full-video length cap (12 × 15 s + slack).
  mvSongTooLong('MV_SONG_TOO_LONG', 49313),

  /// The song's 24 h candidate expired before it was locked.
  mvSongExpired('MV_SONG_EXPIRED', 49314),

  /// Unknown, not ours, or not a music video (never distinguished).
  mvNotFound('MV_NOT_FOUND', 49315),

  /// A reference photo's 24 h upload expired.
  mvPhotosExpired('MV_PHOTOS_EXPIRED', 49316),

  /// Job-level: a rendering step failed on the platform side; credits are
  /// back (partial settlement of finished steps).
  mvRenderFailed('MV_RENDER_FAILED', 0),

  /// Job-level: stopped by the user (`DELETE`), refunded at once when queued,
  /// settled by finished steps when it was rendering (MV).
  userCancelled('USER_CANCELLED', 0);

  const MusicErrorCode(this.wire, this.envelopeCode);

  final String wire;
  final int envelopeCode;

  static MusicErrorCode? fromWire(String? value) {
    if (value == null) return null;
    for (final code in MusicErrorCode.values) {
      if (code.wire == value) return code;
    }
    return null;
  }

  /// The Songlet code behind a [Failure]: the envelope's `details.error_code`
  /// first, then the transport — an unreachable host is `NETWORK_OFFLINE`.
  static MusicErrorCode? of(Failure failure) {
    final explicit = fromWire(failure.errorCode);
    if (explicit != null) return explicit;
    if (failure is NetworkFailure &&
        failure.kind == NetworkFailureKind.offline) {
      return networkOffline;
    }
    return null;
  }

  /// A terminal job's `error_code` (no envelope around it) as the same typed
  /// [ApiError] the envelope interceptor would have produced, so it flows
  /// through the shared `ErrorHandler` → [Failure] mapping.
  ///
  /// [details] are the envelope's other detail fields (a `QUOTA_EXHAUSTED`'s
  /// `offer`, `recommended_product_id`…), stringified like the transport does.
  ApiError toApiError({Map<String, String> details = const {}}) =>
      ApiError.fromEnvelope(
        code: envelopeCode == 0 ? 50000 : envelopeCode,
        message: '',
        details: {...details, ApiError.errorCodeDetailKey: wire},
      );

  /// Generation must not be offered at all (PRD §6.5 "阻断生成"). Region is
  /// never a client-side block (ADR-0005).
  bool get blocksGeneration => this == attestFailed;

  /// The code whose copy the user sees. A server `REGION_UNAVAILABLE` is shown
  /// as the retryable upstream-timeout message — users are never told their
  /// country is excluded (ADR-0005).
  MusicErrorCode get presentedAs =>
      this == regionUnavailable ? upstreamTimeout : this;

  /// Not charged / refunded by the ledger.
  bool get isRefunded =>
      this == safetyBlocked ||
      this == imageRejected ||
      this == upstreamTimeout ||
      this == mvRenderFailed ||
      this == mvSongNotReady ||
      this == mvSongTooLong ||
      this == mvSongExpired ||
      this == mvPhotosExpired;

  /// A music-video code (contract v1.1); its copy talks about the video, not
  /// the song.
  bool get isMusicVideo => switch (this) {
    mvSongNotReady ||
    mvSongTooLong ||
    mvSongExpired ||
    mvNotFound ||
    mvPhotosExpired ||
    mvRenderFailed => true,
    _ => false,
  };
}
