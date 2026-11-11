import 'package:meta/meta.dart';

import 'creation_draft.dart';
import 'prompt_block.dart';

/// `POST /v1/generate` body (contract 02 v2.1 §2.1): exactly these eight
/// fields; everything the user filled in travels inside [prompt]
/// (`PromptBlock`). The server ignores any other field silently.
@immutable
class GenerationRequest {
  const GenerationRequest({
    required this.model,
    required this.occasion,
    required this.region,
    required this.prompt,
    required this.clientRef,
    this.inspiration,
    this.lyrics,
    this.images = const <String>[],
  });

  /// The request for [draft]: the scene's slug as `inspiration` (also the
  /// prompt block's first line — the two must match), its occasion, the
  /// block, own lyrics and photo bids.
  factory GenerationRequest.fromDraft(
    CreationDraft draft, {
    required String clientRef,
    String note = '',
  }) =>
      GenerationRequest(
        model: draft.model,
        occasion: draft.occasion.wire,
        inspiration: PromptBlock.inspirationOf(draft),
        region: draft.region.code,
        prompt: PromptBlock.build(draft, note: note),
        lyrics: draft.hasUserLyrics ? draft.userLyrics : null,
        images: draft.imageBids,
        clientRef: clientRef,
      );

  final SongModel model;
  final String occasion;

  /// The scene's slug (never its `id`); null = free input.
  final String? inspiration;
  final String region;

  /// The user-side block (see `PromptBlock`).
  final String prompt;
  final String? lyrics;

  /// Upload bids of the picked photos.
  final List<String> images;

  /// Client UUID — `/v1/generate` is idempotent per `client_ref`, so a retried
  /// submit can never double-charge.
  final String clientRef;

  /// The JSON body.
  Map<String, Object?> toJson() => <String, Object?>{
        'model': model.wire,
        'occasion': occasion,
        if (inspiration != null) 'inspiration': inspiration,
        'region': region,
        'prompt': prompt,
        if (lyrics != null) 'lyrics': lyrics,
        if (images.isNotEmpty) 'images': images,
        'client_ref': clientRef,
      };
}

/// `DELETE /v1/jobs/{job_id}` outcome (ADR-0012): a job cancelled while
/// queued is refunded; once started it is not (PRD §8.4).
@immutable
class CancelOutcome {
  const CancelOutcome({required this.refunded});

  final bool refunded;
}

/// `POST /v1/generate` response.
@immutable
class GenerationTicket {
  const GenerationTicket({
    required this.jobId,
    required this.etaSeconds,
    required this.creditsCharged,
  });

  final String jobId;
  final int etaSeconds;
  final int creditsCharged;
}

enum JobStatus {
  queued,
  running,
  succeeded,
  failed;

  static JobStatus fromWire(String value) => switch (value.toLowerCase()) {
        'running' => running,
        'succeeded' || 'success' || 'completed' => succeeded,
        'failed' || 'error' => failed,
        _ => queued,
      };

  bool get isTerminal => this == succeeded || this == failed;
}

/// A timed section of the generated song (`structure`), for lyric sync.
@immutable
class LyricSection {
  const LyricSection({required this.label, required this.start, required this.end});

  final String label;
  final double start;
  final double end;

  Map<String, Object?> toJson() => {'section': label, 'start': start, 'end': end};
}

/// `GET /v1/jobs/{job_id}` (PRD §6.3, with the ADR-0012 progress fields —
/// all optional; older servers omit them and the client falls back to the
/// ETA).
@immutable
class JobSnapshot {
  const JobSnapshot({
    required this.status,
    this.audioUrl,
    this.wavUrl,
    this.lyrics,
    this.structure = const <LyricSection>[],
    this.errorCode,
    this.progress,
    this.queuePosition,
    this.etaSeconds,
    this.lyricsPreview = const <String>[],
  });

  final JobStatus status;
  final String? audioUrl;

  /// Lossless render, Premier full songs only (ADR-0010). Re-signed on every
  /// call, so it is fetched when the user asks for WAV.
  final String? wavUrl;

  /// 0–1 server estimate.
  final double? progress;

  /// Place in the queue while `queued` (1 = next).
  final int? queuePosition;

  /// Remaining seconds, server estimate.
  final int? etaSeconds;

  /// Up to four lyric lines as soon as they are written ("A glimpse of your
  /// song", docs/ui P05).
  final List<String> lyricsPreview;
  final String? lyrics;
  final List<LyricSection> structure;

  /// PRD §6.5 code: the failure reason on `failed`, or a progress hint while
  /// queued / running (`UPSTREAM_RATE_LIMITED`, `UPSTREAM_TIMEOUT`).
  final String? errorCode;
}
