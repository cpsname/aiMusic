import 'package:infra_core/infra_core.dart';
import 'package:meta/meta.dart';

import '../../creation/domain/music_generation.dart';
import '../../store/domain/quota_offer.dart';

/// The three music-video levels (backend contract v1.1, PRD ch.15). The wire
/// value is the platform's `MvLevel` enum; the platform pipeline behind each
/// level is server data (segment lengths, models, prices) the client never sees.
enum MvLevel {
  /// A still scene with the lyrics burned in — free (0 credits).
  lyricVideo('lyric_video'),

  /// 30 seconds of the chorus, AI-shot.
  chorus('chorus_mv'),

  /// The whole song, scene by scene; priced by the song's length.
  full('full_mv');

  const MvLevel(this.wire);

  final String wire;

  static MvLevel? fromWire(String? value) {
    for (final level in values) {
      if (level.wire == value) return level;
    }
    return null;
  }
}

/// `aspect_ratio` (absent = the platform default, 9:16).
enum MvAspectRatio {
  portrait('9:16'),
  landscape('16:9'),
  square('1:1');

  const MvAspectRatio(this.wire);

  final String wire;

  static MvAspectRatio? fromWire(String? value) {
    for (final ratio in values) {
      if (ratio.wire == value) return ratio;
    }
    return null;
  }
}

/// `quality` (absent = the platform default, standard).
enum MvQuality {
  standard('standard'),
  high('high');

  const MvQuality(this.wire);

  final String wire;

  static MvQuality? fromWire(String? value) {
    for (final quality in values) {
      if (quality.wire == value) return quality;
    }
    return null;
  }
}

/// The chorus window (chorus videos only, 4–60 s; absent = the storyboard
/// model locates the chorus).
@immutable
class MvChorusWindow {
  const MvChorusWindow({required this.startMs, required this.endMs});

  /// Contract bounds: `end_ms - start_ms` within [minMs, maxMs].
  static const int minMs = 4000;
  static const int maxMs = 60000;

  /// Length of a chorus video whose window the platform locates (PRD §15.1).
  static const int defaultSeconds = 30;

  final int startMs;
  final int endMs;

  bool get isValid => startMs >= 0 && endMs > startMs && endMs - startMs >= minMs && endMs - startMs <= maxMs;

  Map<String, Object?> toJson() => {'start_ms': startMs, 'end_ms': endMs};

  @override
  bool operator ==(Object other) => other is MvChorusWindow && other.startMs == startMs && other.endMs == endMs;

  @override
  int get hashCode => Object.hash(startMs, endMs);
}

/// Where a video request came from (ADR-0028): the song page / library
/// (`library`), the creation toggle's automatic lyric video (`auto_l2`), or
/// the upgrade entry on a finished lyric video (`upgrade`). Recorded locally
/// on every video; sent as `source` only once the platform accepts it
/// (contract gap G6, [MvRequest.sendsSource]).
enum MvSource {
  library('library'),
  autoLyric('auto_l2'),
  upgrade('upgrade');

  const MvSource(this.wire);

  final String wire;

  static MvSource fromWire(String? value) => MvSource.values.firstWhere(
        (s) => s.wire == value,
        orElse: () => MvSource.library,
      );
}

/// `POST /v1/works/{job_id}/mv` body.
@immutable
class MvRequest {
  const MvRequest({
    required this.level,
    required this.clientRef,
    this.aspectRatio,
    this.quality,
    this.subtitles,
    this.photoBids = const <String>[],
    this.chorus,
    this.source = MvSource.library,
  });

  /// Contract cap on `photo_bids`.
  static const int maxPhotos = 10;

  /// Whether `source` travels on the wire. Contract v1.1 has no such field
  /// (gap G6, docs/songlet/backend-contract.md §7); flip once the platform
  /// accepts it. Until then it is recorded on the local video only.
  static const bool sendsSource = false;

  final MvLevel level;
  final MvAspectRatio? aspectRatio;
  final MvQuality? quality;

  /// Burn the timeline subtitles in (a lyric video always has them).
  final bool? subtitles;

  /// Upload bids of reference photos (style only, never face-driven in V1).
  final List<String> photoBids;
  final MvChorusWindow? chorus;

  /// Client UUID — the call is idempotent per `(account, client_ref)`, so a
  /// retried create never charges twice.
  final String clientRef;

  /// Local attribution; on the wire only when [sendsSource].
  final MvSource source;

  /// The same request with other photo bids or another `client_ref`.
  MvRequest copyWith({List<String>? photoBids, String? clientRef}) => MvRequest(
        level: level,
        clientRef: clientRef ?? this.clientRef,
        aspectRatio: aspectRatio,
        quality: quality,
        subtitles: subtitles,
        photoBids: photoBids ?? this.photoBids,
        chorus: chorus,
        source: source,
      );

  Map<String, Object?> toJson() => {
        'level': level.wire,
        if (aspectRatio != null) 'aspect_ratio': aspectRatio!.wire,
        if (quality != null) 'quality': quality!.wire,
        if (subtitles != null) 'subtitles': subtitles,
        if (photoBids.isNotEmpty) 'photo_bids': photoBids,
        if (chorus != null) 'chorus': chorus!.toJson(),
        if (sendsSource) 'source': source.wire,
        'client_ref': clientRef,
      };
}

/// `POST /v1/works/{job_id}/mv` response (`MvTicket`).
@immutable
class MvTicket {
  const MvTicket({required this.mvId, required this.etaSeconds, required this.creditsCharged});

  final String mvId;
  final int etaSeconds;

  /// The platform's estimate, already frozen; 0 for a lyric video.
  final int creditsCharged;
}

/// `balances` on a terminal MV (contract `Balances`).
@immutable
class MvBalances {
  const MvBalances({required this.songsLeft, required this.clipsLeft});

  final int songsLeft;
  final int clipsLeft;
}

/// `GET /v1/mv/{mv_id}` (`MvJob`). `progress` is the platform's real completion
/// (steps + segments, ADR-0020) — the client never interpolates it over time.
@immutable
class MvSnapshot {
  const MvSnapshot({
    required this.status,
    this.stage,
    this.progress,
    this.segmentsDone,
    this.segmentsTotal,
    this.cancelRequested = false,
    this.etaSeconds,
    this.videoUrl,
    this.durationMs,
    this.aiLabel,
    this.errorCode,
    this.balances,
  });

  final JobStatus status;

  /// The platform's stage name, passed through (`queued`, `slicing`,
  /// `storyboarding`, `keyframing`, `rendering`, `assembling`, `done`, or a
  /// value a newer platform adds); null while running without a snapshot.
  final String? stage;
  final double? progress;

  /// Scene progress during `rendering`; null on every other stage.
  final int? segmentsDone;
  final int? segmentsTotal;

  /// A cancel was requested and the worker has not yet confirmed it.
  final bool cancelRequested;
  final int? etaSeconds;

  /// MP4 pre-signed URL (1 h; the object is kept 24 h), `succeeded` only.
  final String? videoUrl;
  final int? durationMs;

  /// `burned_in` = the AI badge is in the pixels (the platform never omits it
  /// on a rendered video; the UI labels the video explicitly as well).
  final String? aiLabel;
  final String? errorCode;
  final MvBalances? balances;

  static const String burnedInLabel = 'burned_in';

  bool get badgeBurnedIn => aiLabel == burnedInLabel;
}

/// `DELETE /v1/mv/{mv_id}` — the two ways a cancel resolves (platform ADR-037).
enum MvCancelResult {
  /// Still queued: cancelled at once, everything refunded.
  cancelled('cancelled'),

  /// Already rendering: the worker stops at the next gap; scenes already
  /// made are charged, the rest refunded. The MV then reads
  /// `failed` / `USER_CANCELLED`, and only that terminal poll carries the
  /// refunded balances.
  cancelRequested('cancel_requested');

  const MvCancelResult(this.wire);

  final String wire;

  static MvCancelResult fromWire(String value) =>
      value == cancelRequested.wire ? cancelRequested : cancelled;
}

@immutable
class MvCancelOutcome {
  const MvCancelOutcome({required this.mvId, required this.result, required this.refunded, this.balances});

  final String mvId;
  final MvCancelResult result;
  final bool refunded;
  final MvBalances? balances;
}

/// `POST /v1/mv/estimate` (`MvEstimateResponse`): the price of one level for
/// one song, and whether the account can afford it. Estimating locks the song
/// (`song_locked`) — the platform prices only a saved song.
@immutable
class MvEstimate {
  const MvEstimate({
    required this.level,
    required this.credits,
    required this.availableCredits,
    required this.affordable,
    required this.gapCredits,
    required this.songLocked,
    this.recommendedProductId,
    this.offer,
  });

  final MvLevel level;
  final int credits;
  final int availableCredits;
  final bool affordable;
  final int gapCredits;

  /// The MV pack to buy when [affordable] is false; null when nothing is
  /// recommended (affordable, or no pack covers the level).
  final String? recommendedProductId;
  final bool songLocked;

  /// Which page to open when [affordable] is false (contract 02 v2.1).
  final QuotaOffer? offer;
}

/// The credit gap behind a `QUOTA_EXHAUSTED` (contract `QuotaExhaustedDetails`,
/// carried on every 49303 since v1.1): what it costs, what the account has,
/// and which consumable product to buy — the client purchases it directly and
/// retries (ADR-0020).
@immutable
class QuotaGap {
  const QuotaGap({
    required this.reason,
    required this.requiredCredits,
    required this.availableCredits,
    this.recommendedProductId,
    this.offer,
  });

  static const String reasonInsufficient = 'insufficient';
  static const String reasonPaywall = 'paywall';

  /// `insufficient` (credits) or `paywall` (a full song on a never-paid
  /// account).
  final String reason;
  final int requiredCredits;
  final int availableCredits;
  final String? recommendedProductId;

  /// Which page to open: plans or packs (contract 02 v2.1); null = plans, with
  /// the packs listed too.
  final QuotaOffer? offer;

  int get gapCredits => (requiredCredits - availableCredits).clamp(0, 1 << 30);

  /// The gap behind [failure], or null when the envelope carried none (a v1
  /// server, or a failure that is not `QUOTA_EXHAUSTED`).
  static QuotaGap? of(Failure failure) {
    if (failure.errorCode != 'QUOTA_EXHAUSTED') return null;
    return fromDetails(failure.details);
  }

  /// Parses the envelope `details` as the transport delivers them (every
  /// value stringified; a JSON `null` reads as `"null"`).
  static QuotaGap? fromDetails(Map<String, String> details) {
    final required = int.tryParse(details['required_credits'] ?? '');
    final available = int.tryParse(details['available_credits'] ?? '');
    if (required == null || available == null) return null;
    final product = details['recommended_product_id'];
    return QuotaGap(
      reason: details['reason'] ?? reasonInsufficient,
      requiredCredits: required,
      availableCredits: available,
      recommendedProductId: product == null || product.isEmpty || product == 'null' ? null : product,
      offer: QuotaOffer.fromWire(details['offer']),
    );
  }
}
