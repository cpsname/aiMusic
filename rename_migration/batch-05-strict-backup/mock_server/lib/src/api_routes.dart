import 'dart:io';

import 'catalog.dart';
import 'core.dart';
import 'demo.dart';
import 'http_support.dart';
import 'inspirations.dart';
import 'job_runner.dart';
import 'jws.dart';
import 'jwt.dart';
import 'license_pdf.dart';
import 'lyrics.dart';
import 'mv_runner.dart';
import 'safety.dart';
import 'state.dart';

/// The `/v1/*` Songlet + monolith endpoints (contract §2–§4). The app
/// signature is verified by the server before any handler runs.
class ApiRoutes {
  ApiRoutes({
    required this.state,
    required this.tokens,
    required this.runner,
    required this.mvRunner,
  });

  final MockState state;
  final DeviceTokenIssuer tokens;
  final JobRunner runner;
  final MvRunner mvRunner;

  /// Song candidates are kept 24 h (contract §3 `audio_url`); a song older
  /// than that can no longer be locked for a video.
  static const Duration _songRetention = Duration(hours: 24);

  static const Duration _challengeWindow = Duration(minutes: 5);
  static const int _maxUploadBytes = 50 * 1024 * 1024;
  static const Set<String> _uploadMimes = {
    'image/png', 'image/jpeg', 'image/webp', 'image/gif', 'image/heic', //
    'image/heif', 'video/mp4', 'video/quicktime', 'video/webm', 'audio/mpeg',
    'audio/wav', 'audio/x-wav', 'audio/mp4', 'application/pdf', 'text/plain',
    'text/markdown',
  };

  Future<Reply> handle(RequestContext ctx) async {
    final rest = ctx.segments.sublist(1);
    return switch ((ctx.method, rest)) {
      ('GET', ['app', 'config']) => _appConfig(),
      ('POST', ['attest']) => _attest(ctx),
      ('POST', ['generate']) => _generate(ctx),
      ('GET', ['jobs', final String id]) => _job(ctx, id),
      ('DELETE', ['jobs', final String id]) => _cancel(ctx, id),
      ('GET', ['templates']) => _templates(ctx),
      ('POST', ['entitlements', 'sync']) => _sync(ctx),
      ('GET', ['license', final String id]) => _license(ctx, id),
      ('POST', ['uploads', 'sign']) => _uploadSign(ctx),
      ('POST', ['uploads', 'finalize']) => _uploadFinalize(ctx),
      // Music videos (contract v1.1).
      ('POST', ['mv', 'estimate']) => _mvEstimate(ctx),
      ('POST', ['works', final String id, 'mv']) => _mvCreate(ctx, id),
      ('GET', ['mv', final String id]) => _mv(ctx, id),
      ('DELETE', ['mv', final String id]) => _mvCancel(ctx, id),
      _ => throw ApiException(
        ApiCodes.notFound,
        'no route ${ctx.method} '
        '${ctx.request.uri.path}',
      ),
    };
  }

  /// Verified bearer → the normalized (lowercase) `app_account_token`.
  String _account(RequestContext ctx) =>
      tokens.verifyBearer(ctx.header('Authorization')).toLowerCase();

  // ── /v1/app/config ────────────────────────────────────────────────────────

  Reply _appConfig() => JsonReply({
    'maintenance': state.config.maintenance,
    'kill_switches': state.config.killSwitches,
    'config': state.config.remoteConfig,
  });

  // ── /v1/attest ────────────────────────────────────────────────────────────

  Reply _attest(RequestContext ctx) {
    final body = ctx.jsonMap;
    final token = requireString(body, 'app_account_token');
    final challenge = requireString(body, 'challenge');
    if (state.config.attestFail) {
      throw ApiException.songlet(SongletErrors.attestFailed);
    }
    _checkChallenge(token, challenge);
    final unsupported = body['unsupported'] == true;
    if (!unsupported) {
      final keyId = optionalString(body, 'key_id') ?? '';
      final proof =
          (optionalString(body, 'attestation') ?? '').isNotEmpty ||
          (optionalString(body, 'assertion') ?? '').isNotEmpty;
      if (keyId.isEmpty || !proof) {
        throw ApiException.songlet(
          SongletErrors.attestFailed,
          message: 'attestation/assertion and key_id are required',
        );
      }
    }
    final nowMs = state.clock.nowMs();
    state.usedChallenges
      ..removeWhere((_, expiry) => expiry < nowMs)
      ..[challenge] = nowMs + 2 * _challengeWindow.inMilliseconds;
    state.ledger.accountFor(token.toLowerCase());
    final ttl = state.config.tokenTtlSeconds;
    return JsonReply({
      'device_token': tokens.issue(appAccountToken: token, ttlSeconds: ttl),
      'expires_in': ttl,
    });
  }

  /// `challenge = <app_account_token>.<unix_ms>.<uuid>`, single use, ±5 min
  /// of the mock clock (or of the real clock, so a client that has not yet
  /// learned an advanced mock clock can still attest).
  void _checkChallenge(String token, String challenge) {
    final parts = challenge.split('.');
    Never fail(String why) => throw ApiException.songlet(
      SongletErrors.attestFailed,
      message: 'challenge rejected: $why',
    );
    if (parts.length != 3 || parts[2].isEmpty) fail('malformed');
    if (parts[0].toLowerCase() != token.toLowerCase()) {
      fail('bound to another app_account_token');
    }
    final ms = int.tryParse(parts[1]);
    if (ms == null) fail('bad timestamp');
    final window = _challengeWindow.inMilliseconds;
    final mockSkew = (state.clock.nowMs() - ms).abs();
    final realSkew = (state.clock.realNow().millisecondsSinceEpoch - ms).abs();
    if (mockSkew > window && realSkew > window) fail('outside ±5 min');
    final used = state.usedChallenges[challenge];
    if (used != null && used >= state.clock.nowMs()) fail('already used');
  }

  // ── /v1/generate ──────────────────────────────────────────────────────────

  Reply _generate(RequestContext ctx) {
    final account = _account(ctx);
    final body = ctx.jsonMap;
    final model = requireString(body, 'model');
    if (!Catalog.models.contains(model)) {
      throw ApiException.validation(
        'model',
        'must be one of ${Catalog.models}',
      );
    }
    final occasion = requireString(body, 'occasion');
    if (!Catalog.occasions.contains(occasion)) {
      throw ApiException.validation(
        'occasion',
        'must be one of ${Catalog.occasions}',
      );
    }
    // Contract 02 v2.1 §2: the scene travels as its slug, at the top level
    // and as the prompt block's first line (the same value); fields outside
    // the eight are ignored silently, as the product BFF does.
    final region = requireString(body, 'region').toUpperCase();
    final prompt = requireString(body, 'prompt');
    final fields = _promptFields(prompt);
    final topInspiration = optionalString(body, 'inspiration');
    final lineInspiration = fields['inspiration'];
    if (topInspiration != null && topInspiration.isNotEmpty && lineInspiration != null && lineInspiration != topInspiration) {
      throw ApiException.validation('inspiration', 'inspiration differs from the prompt block');
    }
    final slug = (topInspiration == null || topInspiration.isEmpty) ? lineInspiration : topInspiration;
    InspirationSeed? scene;
    if (slug != null) {
      scene = inspirationBySlug(slug);
      if (scene == null) throw ApiException.validation('inspiration', 'unknown inspiration');
      if (scene.occasion != occasion) {
        throw ApiException.validation('inspiration', 'inspiration does not belong to the occasion');
      }
    }
    final template = scene?.slug;
    for (final key in ['vocals', 'lyric_language']) {
      if ((fields[key] ?? '').isEmpty) throw ApiException.validation('prompt.$key', 'required');
    }
    if (!const {'custom', 'vocals', 'instrumental'}.contains(fields['vocals'])) {
      throw ApiException.validation('prompt.vocals', 'must be custom, vocals or instrumental');
    }
    final lyrics = optionalString(body, 'lyrics');
    final images = optionalStringList(body, 'images');
    final clientRef = requireString(body, 'client_ref');
    _checkLyrics(lyrics);
    final hasLyrics = lyrics != null && lyrics.trim().isNotEmpty;
    if (hasLyrics && fields['vocals'] == 'instrumental') {
      throw ApiException.validation('lyrics', 'an instrumental takes no lyrics');
    }
    if (scene != null && scene.inputRequired && (fields['description'] ?? '').isEmpty && !hasLyrics) {
      throw ApiException.validation('prompt.description', "this inspiration needs the user's words");
    }
    if (scene == null && !hasLyrics && images.isEmpty && !['keywords', 'description', 'note'].any((k) => (fields[k] ?? '').isNotEmpty)) {
      throw ApiException.validation('prompt.description', 'a name alone does not make a song');
    }
    if (images.length > 10) {
      throw ApiException.validation('images', 'accepts at most 10 bids');
    }

    // Idempotent per (app_account_token, client_ref): a replay returns the
    // original job and never charges twice.
    final idemKey = '$account|$clientRef';
    final existing = state.jobs[state.idempotency[idemKey]];
    if (existing != null) return _generateReply(existing);

    _checkRegion(ctx, account, region);
    for (final bid in images) {
      final upload = state.uploads[bid];
      if (upload == null ||
          !upload.finalized ||
          state.ledger.resolve(upload.token) != state.ledger.resolve(account)) {
        throw ApiException.validation(
          'images',
          'unknown or unfinalized bid $bid',
        );
      }
    }
    if (safetyViolation([prompt, lyrics]) != null) {
      throw ApiException.songlet(SongletErrors.safetyBlocked);
    }
    final forced = state.failNext;
    if (forced != null && SongletErrors.requestLevel.contains(forced)) {
      state.failNext = null;
      throw ApiException.songlet(forced);
    }

    final isSong = model == Catalog.songModel;
    final nowMs = state.clock.nowMs();
    final charge = state.ledger.charge(
      account,
      isSong ? 'song' : 'clip',
      nowMs,
    );
    final jobForced = forced != null && SongletErrors.jobLevel.contains(forced)
        ? forced
        : null;
    if (jobForced != null) state.failNext = null;
    final demoSong = state.demo?.selectedSong;
    final delay = demoSong != null
        ? state.config.demoDelayMs
        : isSong
            ? state.config.songDelayMs
            : state.config.clipDelayMs;
    final job = Job(
      id: 'job_${randomHex(24)}',
      accountId: state.ledger.resolve(account),
      token: account,
      clientRef: clientRef,
      model: model,
      occasion: occasion,
      template: template,
      region: region,
      prompt: prompt,
      userLyrics: lyrics,
      images: images,
      isSong: isSong,
      charge: charge,
      plan: JobRunner.planFor(delayMs: delay, forced: demoSong != null ? JobRunner.demo : jobForced),
      createdAtMs: nowMs,
      createdRealMs: DateTime.now().millisecondsSinceEpoch,
      etaSeconds: demoSong != null ? DemoProfile.etaSeconds : (delay / 1000).ceil(),
      draftLyrics: demoSong?.lyrics ??
          generateLyrics(
            prompt: PromptBlock.parse(prompt),
            isSong: isSong,
            userLyrics: lyrics,
          ),
      mediaFile: demoSong?.audioPath,
      videoFile: state.demo?.selectedVideo?.videoPath,
      fixedStructure: demoSong?.structure,
    );
    state.jobs[job.id] = job;
    state.idempotency[idemKey] = job.id;
    runner.start(job);
    return _generateReply(job);
  }

  /// The prompt block's `key: value` lines (§2.2); a key given twice is
  /// rejected.
  static Map<String, String> _promptFields(String prompt) {
    final fields = <String, String>{};
    for (final line in prompt.split('\n')) {
      final i = line.indexOf(':');
      if (i <= 0) continue;
      final key = line.substring(0, i).trim().toLowerCase();
      if (fields.containsKey(key)) throw ApiException.validation('prompt.$key', 'duplicate key');
      fields[key] = line.substring(i + 1).trim();
    }
    return fields;
  }

  Reply _generateReply(Job job) => JsonReply({
    'job_id': job.id,
    'eta_seconds': job.etaSeconds,
    'credits_charged': 1,
  });

  static void _checkLyrics(String? lyrics) {
    if (lyrics == null) return;
    final runes = lyrics.runes.toList();
    final hasCjk = runes.any(
      (r) =>
          (r >= 0x3040 && r <= 0x30FF) || // kana
          (r >= 0x3400 && r <= 0x4DBF) ||
          (r >= 0x4E00 && r <= 0x9FFF) ||
          (r >= 0xAC00 && r <= 0xD7AF), // hangul
    );
    final limit = hasCjk ? 600 : 1200;
    if (runes.length > limit) {
      throw ApiException.validation('lyrics', 'exceeds $limit characters');
    }
  }

  /// REGION_UNAVAILABLE when the device region or storefront is unsupported,
  /// or the requested preset is not one of the 14 launch regions.
  void _checkRegion(RequestContext ctx, String account, String region) {
    final deviceRegion = (ctx.header('X-Device-Region') ?? '').toUpperCase();
    var storefront = (ctx.header('X-Storefront') ?? '').toUpperCase();
    if (storefront.isEmpty) {
      storefront = state.ledger.accountFor(account).lastStorefront ?? '';
    }
    if (!Catalog.presetRegions.contains(region) ||
        Catalog.unsupportedRegions.contains(deviceRegion) ||
        Catalog.unsupportedRegions.contains(storefront)) {
      throw ApiException.songlet(SongletErrors.regionUnavailable);
    }
  }

  // ── /v1/jobs/{id} ─────────────────────────────────────────────────────────

  Reply _job(RequestContext ctx, String id) {
    final account = _account(ctx);
    final job = _ownedJob(account, id);
    final status = state.ledger.status(account, state.clock.nowMs());
    return JsonReply(
      {
        ...job.toApiJson(
          ctx.baseUrl,
          wav: status.tier == 'premier' && state.config.wavEnabled,
        ),
        // Balances after a terminal state (ADR-0011): the client never
        // counts locally.
        if (job.terminal) 'balances': {'songs_left': status.songsLeft, 'clips_left': status.clipsLeft},
      },
      logNote: job.errorCode,
    );
  }

  /// `DELETE /v1/jobs/{id}` (ADR-0012): cancelled while queued → refunded;
  /// once running → the charge stays (PRD §8.4). A finished job →
  /// JOB_ALREADY_FINISHED (49309).
  Reply _cancel(RequestContext ctx, String id) {
    final account = _account(ctx);
    final job = _ownedJob(account, id);
    if (job.terminal) throw ApiException.songlet(SongletErrors.jobAlreadyFinished);
    final refund = job.status == 'queued';
    runner.cancel(job);
    job
      ..status = 'failed'
      ..errorCode = 'USER_CANCELLED'
      ..completedAtMs = state.clock.nowMs();
    if (refund && !job.refunded) {
      state.ledger.refund(job.accountId, job.charge);
      job.refunded = true;
    }
    final status = state.ledger.status(account, state.clock.nowMs());
    return JsonReply({
      'job_id': job.id,
      'refunded': refund,
      'balances': {'songs_left': status.songsLeft, 'clips_left': status.clipsLeft},
    });
  }

  // ── /v1/templates ─────────────────────────────────────────────────────────

  /// Template sample clips for the create home's play buttons (ADR-0008).
  Reply _templates(RequestContext ctx) {
    _account(ctx);
    return JsonReply({
      'templates': [
        for (final id in Catalog.templates)
          {'id': id, 'sample_url': '${ctx.baseUrl}/files/samples/$id.mp3', 'duration': 30},
      ],
      // Contract 02 v2.1: the create home's single list (absent when switched off).
      if (state.config.inspirationsEnabled)
        'inspirations': [for (final (i, seed) in inspirations.indexed) seed.toJson(i + 1)],
    });
  }

  // ── Music videos (contract v1.1 §3; platform ADR-037/038/043) ─────────────

  /// `POST /v1/mv/estimate {job_id, level}`: the price of one level for one
  /// song. Estimating locks the song (the platform prices a saved song only):
  /// `song_locked` is always true once this returns.
  Reply _mvEstimate(RequestContext ctx) {
    final account = _account(ctx);
    final body = ctx.jsonMap;
    final level = _mvLevel(body);
    final song = _mvSong(account, requireString(body, 'job_id'));
    _forceMvRequestFailure();
    final credits = MvRunner.creditsFor(level, song);
    final available = state.ledger.creditsAvailable(account);
    final affordable = available >= credits;
    return JsonReply({
      'level': level,
      'credits': credits,
      'available_credits': available,
      'affordable': affordable,
      'gap_credits': affordable ? 0 : credits - available,
      'recommended_product_id': affordable ? null : Catalog.mvPackFor(level),
      'song_locked': true,
    });
  }

  /// `POST /v1/works/{job_id}/mv`: validate → lock the song → price → charge
  /// (QUOTA_EXHAUSTED carries the gap) → start the video.
  Reply _mvCreate(RequestContext ctx, String jobId) {
    final account = _account(ctx);
    final body = ctx.jsonMap;
    final level = _mvLevel(body);
    final clientRef = requireString(body, 'client_ref');
    final aspectRatio = optionalString(body, 'aspect_ratio') ?? '9:16';
    if (!Catalog.mvAspectRatios.contains(aspectRatio)) {
      throw ApiException.validation('aspect_ratio', 'must be 9:16|16:9|1:1');
    }
    final quality = optionalString(body, 'quality') ?? 'standard';
    if (!Catalog.mvQualities.contains(quality)) {
      throw ApiException.validation('quality', 'must be standard|high');
    }
    final subtitles = body['subtitles'];
    if (subtitles != null && subtitles is! bool) {
      throw ApiException.validation('subtitles', 'must be boolean');
    }
    final photoBids = optionalStringList(body, 'photo_bids');
    if (photoBids.length > Catalog.mvMaxPhotos) {
      throw ApiException.validation('photo_bids', 'accepts at most ${Catalog.mvMaxPhotos} bids');
    }
    if (photoBids.toSet().length != photoBids.length) {
      throw ApiException.validation('photo_bids', 'duplicate photo');
    }
    final chorus = _mvChorus(body, level);

    // Idempotent per (account, client_ref): a replay returns the original
    // video and never charges twice.
    final idemKey = '$account|$clientRef';
    final existing = state.mvJobs[state.mvIdempotency[idemKey]];
    if (existing != null) return _mvTicket(existing);

    final song = _mvSong(account, jobId);
    for (final bid in photoBids) {
      final upload = state.uploads[bid];
      if (upload == null ||
          !upload.finalized ||
          state.ledger.resolve(upload.token) != state.ledger.resolve(account)) {
        throw ApiException.validation('photo_bids', 'unknown or unfinalized bid $bid');
      }
      if (state.clock.nowMs() - upload.createdAtMs > _songRetention.inMilliseconds) {
        throw ApiException.songlet(SongletErrors.mvPhotosExpired);
      }
    }
    _forceMvRequestFailure();

    final credits = MvRunner.creditsFor(level, song);
    state.ledger.chargeCredits(account, credits, recommendedProductId: Catalog.mvPackFor(level));
    final forced = state.failNext;
    final jobForced = forced != null && SongletErrors.mvJobLevel.contains(forced) ? forced : null;
    if (jobForced != null) state.failNext = null;
    final nowMs = state.clock.nowMs();
    final delay = state.config.mvDelayMs;
    final songSeconds = MvRunner.songSecondsOf(song);
    final mv = MvJob(
      id: 'mv_${randomHex(24)}',
      accountId: state.ledger.resolve(account),
      token: account,
      clientRef: clientRef,
      jobId: song.id,
      level: level,
      credits: credits,
      plan: MvRunner.planFor(level: level, songSeconds: songSeconds, delayMs: delay, forced: jobForced),
      createdAtMs: nowMs,
      createdRealMs: DateTime.now().millisecondsSinceEpoch,
      etaSeconds: (delay / 1000).ceil(),
      durationMs: switch (level) {
        'lyric_video' when song.videoFile != null =>
          DemoVideo(videoPath: song.videoFile!).probeDurationMs() ?? songSeconds * 1000,
        'chorus_mv' => 30000,
        _ => songSeconds * 1000,
      },
      aspectRatio: aspectRatio,
      quality: quality,
      subtitles: subtitles == true || level == 'lyric_video',
      photoBids: photoBids,
      chorus: chorus,
      // Demo profile: a lyric video of a storefront song is that storefront's
      // platform-rendered video (demo.dart).
      videoFile: level == 'lyric_video' ? song.videoFile : null,
    );
    state.mvJobs[mv.id] = mv;
    state.mvIdempotency[idemKey] = mv.id;
    mvRunner.start(mv);
    return _mvTicket(mv);
  }

  Reply _mvTicket(MvJob mv) => JsonReply({
    'mv_id': mv.id,
    'eta_seconds': mv.etaSeconds,
    'credits_charged': mv.credits,
  });

  /// `GET /v1/mv/{id}`: the platform's real progress snapshot; a terminal
  /// video carries the balances.
  Reply _mv(RequestContext ctx, String id) {
    final account = _account(ctx);
    final mv = _ownedMv(account, id);
    final status = state.ledger.status(account, state.clock.nowMs());
    return JsonReply(
      {
        ...mv.toApiJson(ctx.baseUrl),
        if (mv.terminal) 'balances': {'songs_left': status.songsLeft, 'clips_left': status.clipsLeft},
      },
      logNote: mv.errorCode ?? mv.stage,
    );
  }

  /// `DELETE /v1/mv/{id}` (platform ADR-037): queued → `cancelled`, refunded
  /// now; running → `cancel_requested`, honoured at the next step boundary
  /// (finished steps stay charged, the rest is refunded on the terminal poll).
  Reply _mvCancel(RequestContext ctx, String id) {
    final account = _account(ctx);
    final mv = _ownedMv(account, id);
    if (mv.terminal) throw ApiException.songlet(SongletErrors.jobAlreadyFinished);
    final String outcome;
    if (mv.status == 'queued') {
      mvRunner.cancelQueued(mv);
      outcome = 'cancelled';
    } else {
      mv.cancelRequested = true;
      outcome = 'cancel_requested';
    }
    final status = state.ledger.status(account, state.clock.nowMs());
    return JsonReply({
      'mv_id': mv.id,
      'outcome': outcome,
      'refunded': outcome == 'cancelled',
      'balances': {'songs_left': status.songsLeft, 'clips_left': status.clipsLeft},
    });
  }

  static String _mvLevel(Map<String, Object?> body) {
    final level = requireString(body, 'level');
    if (!Catalog.mvLevels.contains(level)) {
      throw ApiException.validation('level', 'must be one of ${Catalog.mvLevels}');
    }
    return level;
  }

  static Map<String, int>? _mvChorus(Map<String, Object?> body, String level) {
    final raw = body['chorus'];
    if (raw == null) return null;
    if (raw is! Map) throw ApiException.validation('chorus', 'must be an object');
    if (level != 'chorus_mv') {
      throw ApiException.validation('chorus', 'chorus window is only valid for chorus_mv');
    }
    final start = raw['start_ms'];
    final end = raw['end_ms'];
    if (start is! int || end is! int || start < 0 || end <= start) {
      throw ApiException.validation('chorus', 'must satisfy 0 <= start_ms < end_ms');
    }
    final window = end - start;
    if (window < Catalog.mvMinChorusWindowMs || window > Catalog.mvMaxChorusWindowMs) {
      throw ApiException.validation('chorus', 'window must be 4 to 60 seconds');
    }
    return {'start_ms': start, 'end_ms': end};
  }

  /// The song a video is made from: a succeeded job of this account whose
  /// 24 h candidate has not expired. Any other job is `MV_SONG_NOT_READY`;
  /// a full video of a song over the cap is `MV_SONG_TOO_LONG`.
  Job _mvSong(String account, String jobId) {
    final Job song;
    try {
      song = _ownedJob(account, jobId);
    } on ApiException catch (e) {
      if (e.code == ApiCodes.notFound) throw ApiException.songlet(SongletErrors.mvSongNotReady);
      rethrow;
    }
    if (song.status != 'succeeded') throw ApiException.songlet(SongletErrors.mvSongNotReady);
    final completed = song.completedAtMs;
    if (completed != null && state.clock.nowMs() - completed > _songRetention.inMilliseconds) {
      throw ApiException.songlet(SongletErrors.mvSongExpired);
    }
    return song;
  }

  /// A queued `fail_next` MV request code is consumed here (before any charge).
  void _forceMvRequestFailure() {
    final forced = state.failNext;
    if (forced != null && SongletErrors.mvRequestLevel.contains(forced)) {
      state.failNext = null;
      if (forced == SongletErrors.quotaExhausted) {
        throw ApiException(
          SongletErrors.codes[forced]!,
          SongletErrors.messages[forced]!,
          details: {
            'error_code': forced,
            'reason': 'insufficient',
            'required_credits': Catalog.chorusMvCredits,
            'available_credits': 0,
            'recommended_product_id': Catalog.mvChorusPack,
          },
        );
      }
      throw ApiException.songlet(forced);
    }
  }

  MvJob _ownedMv(String account, String id) {
    final mv = state.mvJobs[id];
    if (mv == null ||
        (mv.token != account &&
            state.ledger.resolve(mv.accountId) != state.ledger.resolve(account))) {
      throw ApiException.songlet(SongletErrors.mvNotFound);
    }
    return mv;
  }

  Job _ownedJob(String account, String id) {
    final job = state.jobs[id];
    if (job == null ||
        (job.token != account &&
            state.ledger.resolve(job.accountId) !=
                state.ledger.resolve(account))) {
      throw ApiException(ApiCodes.notFound, 'job not found');
    }
    return job;
  }

  // ── /v1/entitlements/sync ─────────────────────────────────────────────────

  Reply _sync(RequestContext ctx) {
    final account = _account(ctx);
    final body = ctx.jsonMap;
    final signed = optionalStringList(
      body,
      'signed_transactions',
    ).map(SignedTransaction.decode).toList();
    state.ledger.sync(account, signed);
    return JsonReply(
      state.ledger.status(account, state.clock.nowMs()).toJson(),
    );
  }

  // ── /v1/license/{id} ──────────────────────────────────────────────────────

  Reply _license(RequestContext ctx, String id) {
    final account = _account(ctx);
    final job = _ownedJob(account, id);
    if (job.status != 'succeeded') {
      throw ApiException(40900, 'job has not succeeded');
    }
    final status = state.ledger.status(account, state.clock.nowMs());
    if (status.tier == 'free' || state.ledger.fundingRevoked(job.charge)) {
      throw ApiException.songlet(SongletErrors.downloadLocked);
    }
    final pdf = buildLicensePdf(
      jobId: job.id,
      generatedAt: DateTime.fromMillisecondsSinceEpoch(
        job.completedAtMs ?? job.createdAtMs,
        isUtc: true,
      ),
      issuedAt: state.clock.now(),
      model: job.model,
    );
    final issued = state.clock.now();
    return BytesReply(
      pdf,
      contentType: 'application/pdf',
      headers: {
        'Content-Disposition':
            'attachment; filename="songlet-license-${job.id}.pdf"',
        // Shown on the download page (docs/ui P11; contract extension).
        'X-License-Id': licenseIdFor(job.id, issued),
        'X-License-Issued-At': issued.toIso8601String(),
      },
    );
  }

  // ── /v1/uploads/* (media_kit two-stage presigned upload) ──────────────────

  Reply _uploadSign(RequestContext ctx) {
    final account = _account(ctx);
    final body = ctx.jsonMap;
    final mime = requireString(body, 'mime_type');
    if (!_uploadMimes.contains(mime)) {
      throw ApiException(ApiCodes.uploadMime, 'mime type $mime not allowed');
    }
    final size = optionalNum(body, 'size')?.toInt() ?? 0;
    if (size <= 0 || size > _maxUploadBytes) {
      throw ApiException(ApiCodes.uploadSize, 'size must be 1..50 MiB');
    }
    final hash = optionalString(body, 'file_hash') ?? '';
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
      throw ApiException(ApiCodes.uploadHash, 'file_hash must be SHA-256 hex');
    }
    final upload = Upload(
      bid: uuidV4(),
      token: account,
      mimeType: mime,
      size: size,
      filename: optionalString(body, 'filename') ?? 'upload',
      fileHash: hash,
      accessLevel: optionalString(body, 'access_level') ?? 'private',
      contentType: optionalString(body, 'content_type'),
      createdAtMs: state.clock.nowMs(),
    );
    state.uploads[upload.bid] = upload;
    return JsonReply({
      'bid': upload.bid,
      'put_url': '${ctx.baseUrl}/r2/${upload.bid}',
      'public_url': '${ctx.baseUrl}/files/uploads/${upload.bid}',
      'key': upload.key,
      'dedup_hit': false,
      'expires_at': state.clock.nowSeconds() + 900,
    });
  }

  Reply _uploadFinalize(RequestContext ctx) {
    final account = _account(ctx);
    final bid = requireString(ctx.jsonMap, 'bid');
    final upload = state.uploads[bid];
    if (upload == null ||
        state.ledger.resolve(upload.token) != state.ledger.resolve(account)) {
      throw ApiException(ApiCodes.uploadBidUnknown, 'unknown bid');
    }
    if (upload.finalized) {
      throw ApiException(ApiCodes.uploadAlreadyFinalized, 'already finalized');
    }
    final bytes = upload.bytes;
    if (bytes == null) {
      throw ApiException(ApiCodes.uploadNoObject, 'no object uploaded yet');
    }
    if (bytes.length != upload.size) {
      throw ApiException(
        ApiCodes.uploadSizeMismatch,
        'uploaded ${bytes.length} bytes, declared ${upload.size}',
      );
    }
    upload.finalized = true;
    return JsonReply(upload.assetJson(ctx.baseUrl));
  }

  /// Raw `PUT /r2/{bid}` (no signature, no envelope), R2-style: the
  /// Content-Type must match the signed MIME type.
  Reply r2Put(RequestContext ctx, String bid) {
    final upload = state.uploads[bid];
    if (upload == null) return const EmptyReply(status: HttpStatus.notFound);
    final contentType = (ctx.header('Content-Type') ?? '')
        .split(';')
        .first
        .trim();
    if (contentType != upload.mimeType) {
      return const EmptyReply(status: HttpStatus.forbidden);
    }
    upload.bytes = ctx.body;
    return EmptyReply(
      headers: {'ETag': '"${upload.fileHash.substring(0, 32)}"'},
    );
  }
}

/// "SL-20260924-7F3A9C": issue date + the job id's last six hex digits.
String licenseIdFor(String jobId, DateTime issued) {
  final date = '${issued.year.toString().padLeft(4, '0')}${issued.month.toString().padLeft(2, '0')}'
      '${issued.day.toString().padLeft(2, '0')}';
  final tail = jobId.replaceAll(RegExp('[^0-9a-fA-F]'), '');
  return 'SL-$date-${(tail.length > 6 ? tail.substring(tail.length - 6) : tail).toUpperCase()}';
}
