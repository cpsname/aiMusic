import 'dart:convert';
import 'dart:typed_data';

import 'core.dart';
import 'demo.dart';
import 'ledger.dart';

/// Admin-tunable knobs (`POST /__admin/config`).
class MockConfig {
  int clipDelayMs = 8000;
  int songDelayMs = 15000;

  /// Wall-clock length of a music video run (all levels; the plan spreads
  /// the stages over it).
  int mvDelayMs = 12000;

  /// Wall-clock length of a song job under the `demo` profile (the preview
  /// recordings compress the wait; the reply still announces the real ETA).
  int demoDelayMs = 4000;

  /// The lossless render is offered (`wav_url` on Premier full songs). Off by
  /// default, like the platform until its lyria-3.5 WAV probe passes.
  bool wavEnabled = false;

  /// `inspirations` on `GET /v1/templates` (contract 02 v1.2). On by default;
  /// off reproduces an older server (the field absent).
  bool inspirationsEnabled = true;
  bool attestFail = false;
  int tokenTtlSeconds = 86400;

  /// `GET /v1/app/config` payload pieces.
  Map<String, Object?> maintenance = {'active': false};
  List<String> killSwitches = [];
  Map<String, Object?> remoteConfig = {};

  /// Applies an admin patch; unknown keys → 40001.
  void apply(Map<String, Object?> patch) {
    for (final MapEntry(:key, :value) in patch.entries) {
      switch (key) {
        case 'clip_delay_ms':
          clipDelayMs = _nonNegativeInt(key, value);
        case 'song_delay_ms':
          songDelayMs = _nonNegativeInt(key, value);
        case 'mv_delay_ms':
          mvDelayMs = _nonNegativeInt(key, value);
        case 'demo_delay_ms':
          demoDelayMs = _nonNegativeInt(key, value);
        case 'wav_enabled':
          if (value is! bool) {
            throw ApiException.validation(key, 'must be bool');
          }
          wavEnabled = value;
        case 'inspirations_enabled':
          if (value is! bool) {
            throw ApiException.validation(key, 'must be bool');
          }
          inspirationsEnabled = value;
        case 'token_ttl_seconds':
          tokenTtlSeconds = _nonNegativeInt(key, value);
        case 'attest_fail':
          if (value is! bool) {
            throw ApiException.validation(key, 'must be bool');
          }
          attestFail = value;
        case 'maintenance':
          maintenance = switch (value) {
            final bool active => {'active': active},
            final Map<String, Object?> m => {
              'active': m['active'] == true,
              ...m,
            },
            _ => throw ApiException.validation(key, 'must be bool or object'),
          };
        case 'kill_switches':
          if (value is! List || value.any((e) => e is! String)) {
            throw ApiException.validation(key, 'must be a list of strings');
          }
          killSwitches = value.cast<String>().toList();
        case 'remote_config':
          if (value is! Map<String, Object?>) {
            throw ApiException.validation(key, 'must be an object');
          }
          remoteConfig = value;
        default:
          throw ApiException.validation(key, 'is not a config key');
      }
    }
  }

  static int _nonNegativeInt(String key, Object? value) {
    if (value is num && value >= 0) return value.toInt();
    throw ApiException.validation(key, 'must be a non-negative number');
  }

  Map<String, Object?> toJson() => {
    'clip_delay_ms': clipDelayMs,
    'song_delay_ms': songDelayMs,
    'mv_delay_ms': mvDelayMs,
    'demo_delay_ms': demoDelayMs,
    'wav_enabled': wavEnabled,
    'inspirations_enabled': inspirationsEnabled,
    'attest_fail': attestFail,
    'token_ttl_seconds': tokenTtlSeconds,
    'maintenance': maintenance,
    'kill_switches': killSwitches,
    'remote_config': remoteConfig,
  };
}

/// One scheduled status transition, [atMs] real milliseconds after creation.
class JobStep {
  const JobStep(this.atMs, this.status, [this.errorCode]);

  factory JobStep.fromJson(Map<String, Object?> j) => JobStep(
    j['at_ms']! as int,
    j['status']! as String,
    j['error_code'] as String?,
  );

  final int atMs;
  final String status;
  final String? errorCode;

  bool get terminal => status == 'succeeded' || status == 'failed';

  Map<String, Object?> toJson() => {
    'at_ms': atMs,
    'status': status,
    'error_code': errorCode,
  };
}

class Job {
  Job({
    required this.id,
    required this.accountId,
    required this.token,
    required this.clientRef,
    required this.model,
    required this.occasion,
    this.template,
    required this.region,
    required this.prompt,
    required this.images,
    required this.isSong,
    required this.charge,
    required this.plan,
    required this.createdAtMs,
    required this.createdRealMs,
    required this.etaSeconds,
    this.userLyrics,
    this.status = 'queued',
    this.errorCode,
    this.lyrics,
    this.structure,
    this.mediaFile,
    this.videoFile,
    this.fixedStructure,
    this.completedAtMs,
    this.refunded = false,
    this.draftLyrics,
  });

  factory Job.fromJson(Map<String, Object?> j) => Job(
    id: j['job_id']! as String,
    accountId: j['account_id']! as String,
    token: j['token']! as String,
    clientRef: j['client_ref']! as String,
    model: j['model']! as String,
    occasion: j['occasion']! as String,
    template: j['template'] as String?,
    region: j['region']! as String,
    prompt: j['prompt']! as String,
    userLyrics: j['user_lyrics'] as String?,
    images: ((j['images'] as List?) ?? const []).cast<String>(),
    isSong: j['is_song']! as bool,
    charge: Charge.fromJson((j['charge']! as Map).cast<String, Object?>()),
    plan: [
      for (final s in (j['plan']! as List))
        JobStep.fromJson((s as Map).cast<String, Object?>()),
    ],
    createdAtMs: j['created_at_ms']! as int,
    createdRealMs: j['created_real_ms']! as int,
    etaSeconds: j['eta_seconds']! as int,
    status: j['status']! as String,
    errorCode: j['error_code'] as String?,
    lyrics: j['lyrics'] as String?,
    structure: (j['structure'] as List?)
        ?.map((e) => (e as Map).cast<String, Object>())
        .toList(),
    mediaFile: j['media_file'] as String?,
    videoFile: j['video_file'] as String?,
    fixedStructure: (j['fixed_structure'] as List?)
        ?.map((e) => (e as Map).cast<String, Object>())
        .toList(),
    completedAtMs: j['completed_at_ms'] as int?,
    refunded: (j['refunded'] as bool?) ?? false,
    draftLyrics: j['draft_lyrics'] as String?,
  );

  final String id;

  /// Account charged at creation (resolve through the ledger's links).
  final String accountId;

  /// The `app_account_token` that created the job.
  final String token;
  final String clientRef;
  final String model;
  final String occasion;

  /// Create-home template id, when the song came from one (ADR-0008).
  final String? template;
  final String region;
  final String prompt;
  final String? userLyrics;
  final List<String> images;

  /// Full song (`lyria-3.5`, with or without photos) vs 30 s clip.
  final bool isSong;
  final Charge charge;
  final List<JobStep> plan;
  final int createdAtMs;
  final int createdRealMs;
  final int etaSeconds;

  String status;
  String? errorCode;
  String? lyrics;
  List<Map<String, Object>>? structure;
  int? completedAtMs;
  bool refunded;

  /// Lyrics written ahead of the audio, the source of `lyrics_preview`
  /// (ADR-0012).
  String? draftLyrics;

  /// `demo` profile (demo.dart): the song's own audio, the lyric video made
  /// from it, and its section timing — instead of the fixtures.
  final String? mediaFile;
  final String? videoFile;
  final List<Map<String, Object>>? fixedStructure;

  /// Index of the next plan step to apply.
  int nextStep = 0;

  bool get terminal => status == 'succeeded' || status == 'failed';

  /// Delay from creation to success in the plan (ms).
  int get _totalMs => plan.isEmpty ? 1 : plan.last.atMs.clamp(1, 1 << 31);

  /// `GET /v1/jobs/{id}` `data` (optional keys omitted when absent), with
  /// the ADR-0012 progress fields. `queue_position` is never sent (the
  /// platform does not expose it); [wav] = the lossless render is offered to
  /// this account (Premier, and the WAV switch on).
  Map<String, Object?> toApiJson(
    String baseUrl, {
    bool wav = false,
    int? nowRealMs,
  }) {
    final elapsed = (nowRealMs ?? DateTime.now().millisecondsSinceEpoch) - createdRealMs;
    final fraction = (elapsed / _totalMs).clamp(0.0, 1.0);
    final preview = (draftLyrics ?? '')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('['))
        .take(12)
        .toList();
    return {
      'job_id': id,
      'status': status,
      'progress': switch (status) {
        'succeeded' => 1.0,
        'queued' => 0.02,
        'failed' => fraction,
        _ => (0.1 + fraction * 0.85).clamp(0.1, 0.95),
      },
      if (!terminal) 'eta_seconds': ((_totalMs - elapsed) / 1000).ceil().clamp(1, 1 << 20),
      if (status == 'running' && fraction >= 0.3 || status == 'succeeded') 'lyrics_preview': preview,
      if (status == 'succeeded') 'audio_url': '$baseUrl/files/$id.mp3',
      if (status == 'succeeded' && isSong && wav) 'wav_url': '$baseUrl/files/$id.wav',
      if (status == 'succeeded') 'lyrics': lyrics,
      if (status == 'succeeded') 'structure': structure,
      if (errorCode != null) 'error_code': errorCode,
    };
  }

  Map<String, Object?> toJson() => {
    'job_id': id,
    'account_id': accountId,
    'token': token,
    'client_ref': clientRef,
    'model': model,
    'occasion': occasion,
    'template': template,
    'region': region,
    'prompt': prompt,
    'user_lyrics': userLyrics,
    'images': images,
    'is_song': isSong,
    'charge': charge.toJson(),
    'plan': [for (final s in plan) s.toJson()],
    'created_at_ms': createdAtMs,
    'created_real_ms': createdRealMs,
    'eta_seconds': etaSeconds,
    'status': status,
    'error_code': errorCode,
    'lyrics': lyrics,
    'structure': structure,
    'completed_at_ms': completedAtMs,
    'refunded': refunded,
    'draft_lyrics': draftLyrics,
    'media_file': mediaFile,
    'video_file': videoFile,
    'fixed_structure': fixedStructure,
  };
}

/// One scheduled music-video transition (contract v1.1 §3 `MvJob`): the
/// stage that starts at [atMs] and the completed steps / scenes reported
/// from then on.
class MvStep {
  const MvStep({
    required this.atMs,
    required this.status,
    required this.stage,
    required this.stepsDone,
    required this.stepsTotal,
    this.segmentsDone,
    this.segmentsTotal,
    this.errorCode,
  });

  factory MvStep.fromJson(Map<String, Object?> j) => MvStep(
    atMs: j['at_ms']! as int,
    status: j['status']! as String,
    stage: j['stage']! as String,
    stepsDone: j['steps_done']! as int,
    stepsTotal: j['steps_total']! as int,
    segmentsDone: j['segments_done'] as int?,
    segmentsTotal: j['segments_total'] as int?,
    errorCode: j['error_code'] as String?,
  );

  final int atMs;
  final String status;
  final String stage;
  final int stepsDone;
  final int stepsTotal;
  final int? segmentsDone;
  final int? segmentsTotal;
  final String? errorCode;

  Map<String, Object?> toJson() => {
    'at_ms': atMs,
    'status': status,
    'stage': stage,
    'steps_done': stepsDone,
    'steps_total': stepsTotal,
    'segments_done': segmentsDone,
    'segments_total': segmentsTotal,
    'error_code': errorCode,
  };
}

/// A music video being made from a finished song (`POST /v1/works/{id}/mv`).
/// `mv_id` is this id: the mock, like the platform, keeps the MV as a task.
class MvJob {
  MvJob({
    required this.id,
    required this.accountId,
    required this.token,
    required this.clientRef,
    required this.jobId,
    required this.level,
    required this.credits,
    required this.plan,
    required this.createdAtMs,
    required this.createdRealMs,
    required this.etaSeconds,
    required this.durationMs,
    this.aspectRatio = '9:16',
    this.quality = 'standard',
    this.subtitles = false,
    this.photoBids = const [],
    this.chorus,
    this.status = 'queued',
    this.stage = 'queued',
    this.stepsDone = 0,
    this.stepsTotal = 0,
    this.segmentsDone,
    this.segmentsTotal,
    this.cancelRequested = false,
    this.errorCode,
    this.completedAtMs,
    this.refunded = false,
    this.videoFile,
  });

  factory MvJob.fromJson(Map<String, Object?> j) => MvJob(
    id: j['mv_id']! as String,
    accountId: j['account_id']! as String,
    token: j['token']! as String,
    clientRef: j['client_ref']! as String,
    jobId: j['job_id']! as String,
    level: j['level']! as String,
    credits: j['credits']! as int,
    plan: [
      for (final s in (j['plan']! as List)) MvStep.fromJson((s as Map).cast<String, Object?>()),
    ],
    createdAtMs: j['created_at_ms']! as int,
    createdRealMs: j['created_real_ms']! as int,
    etaSeconds: j['eta_seconds']! as int,
    durationMs: j['duration_ms']! as int,
    aspectRatio: (j['aspect_ratio'] as String?) ?? '9:16',
    quality: (j['quality'] as String?) ?? 'standard',
    subtitles: (j['subtitles'] as bool?) ?? false,
    photoBids: ((j['photo_bids'] as List?) ?? const []).cast<String>(),
    chorus: (j['chorus'] as Map?)?.cast<String, int>(),
    status: j['status']! as String,
    stage: j['stage']! as String,
    stepsDone: (j['steps_done'] as int?) ?? 0,
    stepsTotal: (j['steps_total'] as int?) ?? 0,
    segmentsDone: j['segments_done'] as int?,
    segmentsTotal: j['segments_total'] as int?,
    cancelRequested: (j['cancel_requested'] as bool?) ?? false,
    errorCode: j['error_code'] as String?,
    completedAtMs: j['completed_at_ms'] as int?,
    refunded: (j['refunded'] as bool?) ?? false,
    videoFile: j['video_file'] as String?,
  )..nextStep = (j['next_step'] as int?) ?? 0;

  final String id;
  final String accountId;
  final String token;
  final String clientRef;

  /// The song job the video was made from.
  final String jobId;
  final String level;

  /// Credits frozen at creation (the platform's estimate).
  final int credits;
  final List<MvStep> plan;
  final int createdAtMs;
  final int createdRealMs;
  final int etaSeconds;

  /// Length of the finished video.
  final int durationMs;
  final String aspectRatio;
  final String quality;
  final bool subtitles;
  final List<String> photoBids;
  final Map<String, int>? chorus;

  String status;
  String stage;
  int stepsDone;
  int stepsTotal;
  int? segmentsDone;
  int? segmentsTotal;
  bool cancelRequested;
  String? errorCode;
  int? completedAtMs;
  bool refunded;
  int nextStep = 0;

  /// `demo` profile: the platform-rendered video served instead of the
  /// fixture (demo.dart).
  final String? videoFile;

  bool get terminal => status == 'succeeded' || status == 'failed';

  /// Completed work as a fraction of all steps, the rendering step counting
  /// its scenes — the platform's `percent / 100`.
  double get completedFraction {
    if (status == 'succeeded') return 1;
    if (status == 'queued' || stepsTotal == 0) return 0;
    final total = segmentsTotal;
    final inStep = total == null || total == 0 ? 0.0 : (segmentsDone ?? 0) / total;
    return ((stepsDone + inStep) / stepsTotal).clamp(0.0, 1.0);
  }

  /// `GET /v1/mv/{id}` `data` (contract v1.1 `MvJob`).
  Map<String, Object?> toApiJson(String baseUrl, {int? nowRealMs}) {
    final elapsed = (nowRealMs ?? DateTime.now().millisecondsSinceEpoch) - createdRealMs;
    final totalMs = plan.isEmpty ? 1 : plan.last.atMs.clamp(1, 1 << 31);
    final progress = switch (status) {
      'succeeded' => 1.0,
      'queued' => 0.02,
      _ => (0.1 + 0.85 * completedFraction).clamp(0.1, 0.95),
    };
    return {
      'mv_id': id,
      'level': level,
      'status': status == 'succeeded'
          ? 'succeeded'
          : status == 'failed'
              ? 'failed'
              : status == 'queued'
                  ? 'queued'
                  : 'running',
      'stage': stage,
      'progress': double.parse(progress.toStringAsFixed(3)),
      if (segmentsTotal != null && stage == 'rendering') 'segments': {'done': segmentsDone ?? 0, 'total': segmentsTotal},
      'cancel_requested': cancelRequested && !terminal,
      if (!terminal) 'eta_seconds': ((totalMs - elapsed) / 1000).ceil().clamp(1, 1 << 20),
      if (status == 'succeeded') 'video_url': '$baseUrl/files/$id.mp4',
      if (status == 'succeeded') 'duration_ms': durationMs,
      if (status == 'succeeded') 'ai_label': 'burned_in',
      if (errorCode != null) 'error_code': errorCode,
    };
  }

  Map<String, Object?> toJson() => {
    'mv_id': id,
    'account_id': accountId,
    'token': token,
    'client_ref': clientRef,
    'job_id': jobId,
    'level': level,
    'credits': credits,
    'plan': [for (final s in plan) s.toJson()],
    'created_at_ms': createdAtMs,
    'created_real_ms': createdRealMs,
    'eta_seconds': etaSeconds,
    'duration_ms': durationMs,
    'aspect_ratio': aspectRatio,
    'quality': quality,
    'subtitles': subtitles,
    'photo_bids': photoBids,
    'chorus': chorus,
    'status': status,
    'stage': stage,
    'steps_done': stepsDone,
    'steps_total': stepsTotal,
    'segments_done': segmentsDone,
    'segments_total': segmentsTotal,
    'cancel_requested': cancelRequested,
    'error_code': errorCode,
    'completed_at_ms': completedAtMs,
    'refunded': refunded,
    'next_step': nextStep,
    'video_file': videoFile,
  };
}

/// A presigned upload (`/v1/uploads/sign` → `PUT /r2/{bid}` → finalize).
class Upload {
  Upload({
    required this.bid,
    required this.token,
    required this.mimeType,
    required this.size,
    required this.filename,
    required this.fileHash,
    required this.accessLevel,
    required this.createdAtMs,
    this.contentType,
    this.bytes,
    this.finalized = false,
  });

  factory Upload.fromJson(Map<String, Object?> j) => Upload(
    bid: j['bid']! as String,
    token: j['token']! as String,
    mimeType: j['mime_type']! as String,
    size: j['size']! as int,
    filename: j['filename']! as String,
    fileHash: j['file_hash']! as String,
    accessLevel: j['access_level']! as String,
    contentType: j['content_type'] as String?,
    createdAtMs: j['created_at_ms']! as int,
    bytes: j['bytes_b64'] == null
        ? null
        : base64.decode(j['bytes_b64']! as String),
    finalized: (j['finalized'] as bool?) ?? false,
  );

  final String bid;
  final String token;
  final String mimeType;
  final int size;
  final String filename;
  final String fileHash;
  final String accessLevel;
  final String? contentType;
  final int createdAtMs;
  Uint8List? bytes;
  bool finalized;

  String get key => 'uploads/$token/$bid/$filename';

  Map<String, Object?> assetJson(String baseUrl) => {
    'bid': bid,
    'url': '$baseUrl/files/uploads/$bid',
    'file_name': filename,
    'file_size': bytes?.length ?? size,
    'mime_type': mimeType,
    'content_type': contentType ?? mimeType.split('/').first,
    'access_level': accessLevel,
    'tags': <String>[],
    'group_name': '',
    'dedup_hit': false,
    'expires_at':
        (createdAtMs + const Duration(hours: 24).inMilliseconds) ~/ 1000,
    'created_at': createdAtMs ~/ 1000,
  };

  Map<String, Object?> toJson({bool withBytes = true}) => {
    'bid': bid,
    'token': token,
    'mime_type': mimeType,
    'size': size,
    'filename': filename,
    'file_hash': fileHash,
    'access_level': accessLevel,
    'content_type': contentType,
    'created_at_ms': createdAtMs,
    'finalized': finalized,
    if (withBytes && bytes != null) 'bytes_b64': base64.encode(bytes!),
    if (!withBytes) 'received_bytes': bytes?.length,
  };
}

/// Everything the mock remembers (optionally persisted to `--state-file`).
class MockState {
  MockState({MockClock? clock}) : clock = clock ?? MockClock();

  final MockClock clock;
  MockConfig config = MockConfig();
  final Ledger ledger = Ledger();
  final Map<String, Job> jobs = {};

  /// Music videos by `mv_id` (contract v1.1).
  final Map<String, MvJob> mvJobs = {};

  /// `'$token|$clientRef'` → job id (idempotent `/v1/generate`).
  final Map<String, String> idempotency = {};

  /// `'$token|$clientRef'` → mv id (idempotent `POST /v1/works/{id}/mv`).
  final Map<String, String> mvIdempotency = {};

  /// Used attest challenges → unix ms after which they may be forgotten.
  final Map<String, int> usedChallenges = {};
  final Map<String, Upload> uploads = {};

  /// Error code the next job (or `/v1/generate` call) is forced into.
  String? failNext;

  /// The `demo` profile (demo.dart), when switched on. A server setting:
  /// [reset] keeps it, so a recording can reset between takes.
  DemoProfile? demo;

  void reset() {
    clock.offset = Duration.zero;
    config = MockConfig();
    ledger.clear();
    jobs.clear();
    mvJobs.clear();
    idempotency.clear();
    mvIdempotency.clear();
    usedChallenges.clear();
    uploads.clear();
    failNext = null;
  }

  Map<String, Object?> toJson() => {
    'clock_offset_ms': clock.offset.inMilliseconds,
    'config': config.toJson(),
    'fail_next': failNext,
    'ledger': ledger.toJson(),
    'jobs': [for (final j in jobs.values) j.toJson()],
    'mv_jobs': [for (final j in mvJobs.values) j.toJson()],
    'idempotency': idempotency,
    'mv_idempotency': mvIdempotency,
    'used_challenges': usedChallenges,
    'uploads': [for (final u in uploads.values) u.toJson()],
  };

  void loadJson(Map<String, Object?> j) {
    reset();
    clock.offset = Duration(milliseconds: (j['clock_offset_ms'] as int?) ?? 0);
    final cfg = j['config'];
    if (cfg is Map<String, Object?>) config.apply(cfg);
    failNext = j['fail_next'] as String?;
    final ledgerJson = j['ledger'];
    if (ledgerJson is Map<String, Object?>) ledger.loadJson(ledgerJson);
    for (final raw in (j['jobs'] as List?) ?? const []) {
      final job = Job.fromJson((raw as Map).cast<String, Object?>());
      jobs[job.id] = job;
    }
    for (final raw in (j['mv_jobs'] as List?) ?? const []) {
      final mv = MvJob.fromJson((raw as Map).cast<String, Object?>());
      mvJobs[mv.id] = mv;
    }
    idempotency.addAll(
      ((j['idempotency'] as Map?) ?? const {}).cast<String, String>(),
    );
    mvIdempotency.addAll(
      ((j['mv_idempotency'] as Map?) ?? const {}).cast<String, String>(),
    );
    usedChallenges.addAll(
      ((j['used_challenges'] as Map?) ?? const {}).cast<String, int>(),
    );
    for (final raw in (j['uploads'] as List?) ?? const []) {
      final upload = Upload.fromJson((raw as Map).cast<String, Object?>());
      uploads[upload.bid] = upload;
    }
  }
}
