import 'dart:io';

import 'music_catalog.dart';
import 'music_core.dart';
import 'music_demo.dart';
import 'music_http_support.dart';
import 'music_inspirations.dart';
import 'music_job_runner.dart';
import 'music_jws.dart';
import 'music_jwt.dart';
import 'music_license_pdf.dart';
import 'music_lyrics.dart';
import 'music_mv_runner.dart';
import 'music_safety.dart';
import 'music_state.dart';

/// The `/v1/*` Songlet + monolith endpoints (contract §2–§4). The app
/// signature is verified by the server before any handler runs.
class MusicApiRoutes {
  MusicApiRoutes({
    required this.state,
    required this.tokens,
    required this.runner,
    required this.mvRunner,
  });

  final MusicMockState state;
  final MusicDeviceTokenIssuer tokens;
  final MusicJobRunner runner;
  final MusicMvRunner mvRunner;

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

  Future<MusicReply> handle(MusicRequestContext ctx) async {
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
      _ => throw MusicApiException(
        ApiCodes.notFound,
        'no route ${ctx.method} '
        '${ctx.request.uri.path}',
      ),
    };
  }

  /// Verified bearer → the normalized (lowercase) `app_account_token`.
  String _account(MusicRequestContext ctx) =>
      tokens.verifyBearer(ctx.header('Authorization')).toLowerCase();

  // ── /v1/app/config ────────────────────────────────────────────────────────

  MusicReply _appConfig() => MusicJsonReply({
    'maintenance': state.config.maintenance,
    'kill_switches': state.config.killSwitches,
    'config': state.config.remoteConfig,
  });

  // ── /v1/attest ────────────────────────────────────────────────────────────

  MusicReply _attest(MusicRequestContext ctx) {
    final body = ctx.jsonMap;
    final token = requireString(body, 'app_account_token');
    final challenge = requireString(body, 'challenge');
    if (state.config.attestFail) {
      throw MusicApiException.songlet(MusicErrors.attestFailed);
    }
    _checkChallenge(token, challenge);
    final unsupported = body['unsupported'] == true;
    if (!unsupported) {
      final keyId = optionalString(body, 'key_id') ?? '';
      final proof =
          (optionalString(body, 'attestation') ?? '').isNotEmpty ||
          (optionalString(body, 'assertion') ?? '').isNotEmpty;
      if (keyId.isEmpty || !proof) {
        throw MusicApiException.songlet(
          MusicErrors.attestFailed,
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
    return MusicJsonReply({
      'device_token': tokens.issue(appAccountToken: token, ttlSeconds: ttl),
      'expires_in': ttl,
    });
  }

  /// `challenge = <app_account_token>.<unix_ms>.<uuid>`, single use, ±5 min
  /// of the mock clock (or of the real clock, so a client that has not yet
  /// learned an advanced mock clock can still attest).
  void _checkChallenge(String token, String challenge) {
    final parts = challenge.split('.');
    Never fail(String why) => throw MusicApiException.songlet(
      MusicErrors.attestFailed,
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

  MusicReply _generate(MusicRequestContext ctx) {
    final account = _account(ctx);
    final body = ctx.jsonMap;
    final model = requireString(body, 'model');
    if (!Catalog.models.contains(model)) {
      throw MusicApiException.validation(
        'model',
        'must be one of ${Catalog.models}',
      );
    }
    final occasion = requireString(body, 'occasion');
    if (!Catalog.occasions.contains(occasion)) {
      throw MusicApiException.validation(
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
      throw MusicApiException.validation('inspiration', 'inspiration differs from the prompt block');
    }
    final slug = (topInspiration == null || topInspiration.isEmpty) ? lineInspiration : topInspiration;
    MusicInspirationSeed? scene;
    if (slug != null) {
      scene = inspirationBySlug(slug);
      if (scene == null) throw MusicApiException.validation('inspiration', 'unknown inspiration');
      if (scene.occasion != occasion) {
        throw MusicApiException.validation('inspiration', 'inspiration does not belong to the occasion');
      }
    }
    final template = scene?.slug;
    for (final key in ['vocals', 'lyric_language']) {
      if ((fields[key] ?? '').isEmpty) throw MusicApiException.validation('prompt.$key', 'required');
    }
    if (!const {'custom', 'vocals', 'instrumental'}.contains(fields['vocals'])) {
      throw MusicApiException.validation('prompt.vocals', 'must be custom, vocals or instrumental');
    }
    final lyrics = optionalString(body, 'lyrics');
    final images = optionalStringList(body, 'images');
    final clientRef = requireString(body, 'client_ref');
    _checkLyrics(lyrics);
    final hasLyrics = lyrics != null && lyrics.trim().isNotEmpty;
    if (hasLyrics && fields['vocals'] == 'instrumental') {
      throw MusicApiException.validation('lyrics', 'an instrumental takes no lyrics');
    }
    if (scene != null && scene.inputRequired && (fields['description'] ?? '').isEmpty && !hasLyrics) {
      throw MusicApiException.validation('prompt.description', "this inspiration needs the user's words");
    }
    if (scene == null && !hasLyrics && images.isEmpty && !['keywords', 'description', 'note'].any((k) => (fields[k] ?? '').isNotEmpty)) {
      throw MusicApiException.validation('prompt.description', 'a name alone does not make a song');
    }
    if (images.length > 10) {
      throw MusicApiException.validation('images', 'accepts at most 10 bids');
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
        throw MusicApiException.validation(
          'images',
          'unknown or unfinalized bid $bid',
        );
      }
    }
    if (safetyViolation([prompt, lyrics]) != null) {
      throw MusicApiException.songlet(MusicErrors.safetyBlocked);
    }
    final forced = state.failNext;
    if (forced != null && MusicErrors.requestLevel.contains(forced)) {
      state.failNext = null;
      throw MusicApiException.songlet(forced);
    }

    final isSong = model == Catalog.songModel;
    final nowMs = state.clock.nowMs();
    final charge = state.ledger.charge(
      account,
      isSong ? 'song' : 'clip',
      nowMs,
    );
    final jobForced = forced != null && MusicErrors.jobLevel.contains(forced)
        ? forced
        : null;
    if (jobForced != null) state.failNext = null;
    final demoSong = state.demo?.selectedSong;
    final delay = demoSong != null
        ? state.config.demoDelayMs
        : isSong
            ? state.config.songDelayMs
            : state.config.clipDelayMs;
    final job = MusicJob(
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
      plan: MusicJobRunner.planFor(delayMs: delay, forced: demoSong != null ? MusicJobRunner.demo : jobForced),
      createdAtMs: nowMs,
      createdRealMs: DateTime.now().millisecondsSinceEpoch,
      etaSeconds: demoSong != null ? MusicDemoProfile.etaSeconds : (delay / 1000).ceil(),
      draftLyrics: demoSong?.lyrics ??
          generateLyrics(
            prompt: MusicPromptBlock.parse(prompt),
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
      if (fields.containsKey(key)) throw MusicApiException.validation('prompt.$key', 'duplicate key');
      fields[key] = line.substring(i + 1).trim();
    }
    return fields;
  }

  MusicReply _generateReply(MusicJob job) => MusicJsonReply({
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
      throw MusicApiException.validation('lyrics', 'exceeds $limit characters');
    }
  }

  /// REGION_UNAVAILABLE when the device region or storefront is unsupported,
  /// or the requested preset is not one of the 14 launch regions.
  void _checkRegion(MusicRequestContext ctx, String account, String region) {
    final deviceRegion = (ctx.header('X-Device-Region') ?? '').toUpperCase();
    var storefront = (ctx.header('X-Storefront') ?? '').toUpperCase();
    if (storefront.isEmpty) {
      storefront = state.ledger.accountFor(account).lastStorefront ?? '';
    }
    if (!Catalog.presetRegions.contains(region) ||
        Catalog.unsupportedRegions.contains(deviceRegion) ||
        Catalog.unsupportedRegions.contains(storefront)) {
      throw MusicApiException.songlet(MusicErrors.regionUnavailable);
    }
  }

  // ── /v1/jobs/{id} ─────────────────────────────────────────────────────────

  MusicReply _job(MusicRequestContext ctx, String id) {
    final account = _account(ctx);
    final job = _ownedJob(account, id);
    final status = state.ledger.status(account, state.clock.nowMs());
    return MusicJsonReply(
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
  MusicReply _cancel(MusicRequestContext ctx, String id) {
    final account = _account(ctx);
    final job = _ownedJob(account, id);
    if (job.terminal) throw MusicApiException.songlet(MusicErrors.jobAlreadyFinished);
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
    return MusicJsonReply({
      'job_id': job.id,
      'refunded': refund,
      'balances': {'songs_left': status.songsLeft, 'clips_left': status.clipsLeft},
    });
  }

  // ── /v1/templates ─────────────────────────────────────────────────────────

  /// Template sample clips for the create home's play buttons (ADR-0008).
  MusicReply _templates(MusicRequestContext ctx) {
    _account(ctx);
    return MusicJsonReply({
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
  MusicReply _mvEstimate(MusicRequestContext ctx) {
    final account = _account(ctx);
    final body = ctx.jsonMap;
    final level = _mvLevel(body);
    final song = _mvSong(account, requireString(body, 'job_id'));
    _forceMvRequestFailure();
    final credits = MusicMvRunner.creditsFor(level, song);
    final available = state.ledger.creditsAvailable(account);
    final affordable = available >= credits;
    return MusicJsonReply({
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
  MusicReply _mvCreate(MusicRequestContext ctx, String jobId) {
    final account = _account(ctx);
    final body = ctx.jsonMap;
    final level = _mvLevel(body);
    final clientRef = requireString(body, 'client_ref');
    final aspectRatio = optionalString(body, 'aspect_ratio') ?? '9:16';
    if (!Catalog.mvAspectRatios.contains(aspectRatio)) {
      throw MusicApiException.validation('aspect_ratio', 'must be 9:16|16:9|1:1');
    }
    final quality = optionalString(body, 'quality') ?? 'standard';
    if (!Catalog.mvQualities.contains(quality)) {
      throw MusicApiException.validation('quality', 'must be standard|high');
    }
    final subtitles = body['subtitles'];
    if (subtitles != null && subtitles is! bool) {
      throw MusicApiException.validation('subtitles', 'must be boolean');
    }
    final photoBids = optionalStringList(body, 'photo_bids');
    if (photoBids.length > Catalog.mvMaxPhotos) {
      throw MusicApiException.validation('photo_bids', 'accepts at most ${Catalog.mvMaxPhotos} bids');
    }
    if (photoBids.toSet().length != photoBids.length) {
      throw MusicApiException.validation('photo_bids', 'duplicate photo');
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
        throw MusicApiException.validation('photo_bids', 'unknown or unfinalized bid $bid');
      }
      if (state.clock.nowMs() - upload.createdAtMs > _songRetention.inMilliseconds) {
        throw MusicApiException.songlet(MusicErrors.mvPhotosExpired);
      }
    }
    _forceMvRequestFailure();

    final credits = MusicMvRunner.creditsFor(level, song);
    state.ledger.chargeCredits(account, credits, recommendedProductId: Catalog.mvPackFor(level));
    final forced = state.failNext;
    final jobForced = forced != null && MusicErrors.mvJobLevel.contains(forced) ? forced : null;
    if (jobForced != null) state.failNext = null;
    final nowMs = state.clock.nowMs();
    final delay = state.config.mvDelayMs;
    final songSeconds = MusicMvRunner.songSecondsOf(song);
    final mv = MusicMvJob(
      id: 'mv_${randomHex(24)}',
      accountId: state.ledger.resolve(account),
      token: account,
      clientRef: clientRef,
      jobId: song.id,
      level: level,
      credits: credits,
      plan: MusicMvRunner.planFor(level: level, songSeconds: songSeconds, delayMs: delay, forced: jobForced),
      createdAtMs: nowMs,
      createdRealMs: DateTime.now().millisecondsSinceEpoch,
      etaSeconds: (delay / 1000).ceil(),
      durationMs: switch (level) {
        'lyric_video' when song.videoFile != null =>
          MusicDemoVideo(videoPath: song.videoFile!).probeDurationMs() ?? songSeconds * 1000,
        'chorus_mv' => 30000,
        _ => songSeconds * 1000,
      },
      aspectRatio: aspectRatio,
      quality: quality,
      subtitles: subtitles == true || level == 'lyric_video',
      photoBids: photoBids,
      chorus: chorus,
      // Demo profile: a lyric video of a storefront song is that storefront's
      // platform-rendered video (music_demo.dart).
      videoFile: level == 'lyric_video' ? song.videoFile : null,
    );
    state.mvJobs[mv.id] = mv;
    state.mvIdempotency[idemKey] = mv.id;
    mvRunner.start(mv);
    return _mvTicket(mv);
  }

  MusicReply _mvTicket(MusicMvJob mv) => MusicJsonReply({
    'mv_id': mv.id,
    'eta_seconds': mv.etaSeconds,
    'credits_charged': mv.credits,
  });

  /// `GET /v1/mv/{id}`: the platform's real progress snapshot; a terminal
  /// video carries the balances.
  MusicReply _mv(MusicRequestContext ctx, String id) {
    final account = _account(ctx);
    final mv = _ownedMv(account, id);
    final status = state.ledger.status(account, state.clock.nowMs());
    return MusicJsonReply(
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
  MusicReply _mvCancel(MusicRequestContext ctx, String id) {
    final account = _account(ctx);
    final mv = _ownedMv(account, id);
    if (mv.terminal) throw MusicApiException.songlet(MusicErrors.jobAlreadyFinished);
    final String outcome;
    if (mv.status == 'queued') {
      mvRunner.cancelQueued(mv);
      outcome = 'cancelled';
    } else {
      mv.cancelRequested = true;
      outcome = 'cancel_requested';
    }
    final status = state.ledger.status(account, state.clock.nowMs());
    return MusicJsonReply({
      'mv_id': mv.id,
      'outcome': outcome,
      'refunded': outcome == 'cancelled',
      'balances': {'songs_left': status.songsLeft, 'clips_left': status.clipsLeft},
    });
  }

  static String _mvLevel(Map<String, Object?> body) {
    final level = requireString(body, 'level');
    if (!Catalog.mvLevels.contains(level)) {
      throw MusicApiException.validation('level', 'must be one of ${Catalog.mvLevels}');
    }
    return level;
  }

  static Map<String, int>? _mvChorus(Map<String, Object?> body, String level) {
    final raw = body['chorus'];
    if (raw == null) return null;
    if (raw is! Map) throw MusicApiException.validation('chorus', 'must be an object');
    if (level != 'chorus_mv') {
      throw MusicApiException.validation('chorus', 'chorus window is only valid for chorus_mv');
    }
    final start = raw['start_ms'];
    final end = raw['end_ms'];
    if (start is! int || end is! int || start < 0 || end <= start) {
      throw MusicApiException.validation('chorus', 'must satisfy 0 <= start_ms < end_ms');
    }
    final window = end - start;
    if (window < Catalog.mvMinChorusWindowMs || window > Catalog.mvMaxChorusWindowMs) {
      throw MusicApiException.validation('chorus', 'window must be 4 to 60 seconds');
    }
    return {'start_ms': start, 'end_ms': end};
  }

  /// The song a video is made from: a succeeded job of this account whose
  /// 24 h candidate has not expired. Any other job is `MV_SONG_NOT_READY`;
  /// a full video of a song over the cap is `MV_SONG_TOO_LONG`.
  MusicJob _mvSong(String account, String jobId) {
    final MusicJob song;
    try {
      song = _ownedJob(account, jobId);
    } on MusicApiException catch (e) {
      if (e.code == ApiCodes.notFound) throw MusicApiException.songlet(MusicErrors.mvSongNotReady);
      rethrow;
    }
    if (song.status != 'succeeded') throw MusicApiException.songlet(MusicErrors.mvSongNotReady);
    final completed = song.completedAtMs;
    if (completed != null && state.clock.nowMs() - completed > _songRetention.inMilliseconds) {
      throw MusicApiException.songlet(MusicErrors.mvSongExpired);
    }
    return song;
  }

  /// A queued `fail_next` MV request code is consumed here (before any charge).
  void _forceMvRequestFailure() {
    final forced = state.failNext;
    if (forced != null && MusicErrors.mvRequestLevel.contains(forced)) {
      state.failNext = null;
      if (forced == MusicErrors.quotaExhausted) {
        throw MusicApiException(
          MusicErrors.codes[forced]!,
          MusicErrors.messages[forced]!,
          details: {
            'error_code': forced,
            'reason': 'insufficient',
            'required_credits': Catalog.chorusMvCredits,
            'available_credits': 0,
            'recommended_product_id': Catalog.mvChorusPack,
          },
        );
      }
      throw MusicApiException.songlet(forced);
    }
  }

  MusicMvJob _ownedMv(String account, String id) {
    final mv = state.mvJobs[id];
    if (mv == null ||
        (mv.token != account &&
            state.ledger.resolve(mv.accountId) != state.ledger.resolve(account))) {
      throw MusicApiException.songlet(MusicErrors.mvNotFound);
    }
    return mv;
  }

  MusicJob _ownedJob(String account, String id) {
    final job = state.jobs[id];
    if (job == null ||
        (job.token != account &&
            state.ledger.resolve(job.accountId) !=
                state.ledger.resolve(account))) {
      throw MusicApiException(ApiCodes.notFound, 'job not found');
    }
    return job;
  }

  // ── /v1/entitlements/sync ─────────────────────────────────────────────────

  MusicReply _sync(MusicRequestContext ctx) {
    final account = _account(ctx);
    final body = ctx.jsonMap;
    final signed = optionalStringList(
      body,
      'signed_transactions',
    ).map(MusicSignedTransaction.decode).toList();
    state.ledger.sync(account, signed);
    return MusicJsonReply(
      state.ledger.status(account, state.clock.nowMs()).toJson(),
    );
  }

  // ── /v1/license/{id} ──────────────────────────────────────────────────────

  MusicReply _license(MusicRequestContext ctx, String id) {
    final account = _account(ctx);
    final job = _ownedJob(account, id);
    if (job.status != 'succeeded') {
      throw MusicApiException(40900, 'job has not succeeded');
    }
    final status = state.ledger.status(account, state.clock.nowMs());
    if (status.tier == 'free' || state.ledger.fundingRevoked(job.charge)) {
      throw MusicApiException.songlet(MusicErrors.downloadLocked);
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
    return MusicBytesReply(
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

  MusicReply _uploadSign(MusicRequestContext ctx) {
    final account = _account(ctx);
    final body = ctx.jsonMap;
    final mime = requireString(body, 'mime_type');
    if (!_uploadMimes.contains(mime)) {
      throw MusicApiException(ApiCodes.uploadMime, 'mime type $mime not allowed');
    }
    final size = optionalNum(body, 'size')?.toInt() ?? 0;
    if (size <= 0 || size > _maxUploadBytes) {
      throw MusicApiException(ApiCodes.uploadSize, 'size must be 1..50 MiB');
    }
    final hash = optionalString(body, 'file_hash') ?? '';
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
      throw MusicApiException(ApiCodes.uploadHash, 'file_hash must be SHA-256 hex');
    }
    final upload = MusicUpload(
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
    return MusicJsonReply({
      'bid': upload.bid,
      'put_url': '${ctx.baseUrl}/r2/${upload.bid}',
      'public_url': '${ctx.baseUrl}/files/uploads/${upload.bid}',
      'key': upload.key,
      'dedup_hit': false,
      'expires_at': state.clock.nowSeconds() + 900,
    });
  }

  MusicReply _uploadFinalize(MusicRequestContext ctx) {
    final account = _account(ctx);
    final bid = requireString(ctx.jsonMap, 'bid');
    final upload = state.uploads[bid];
    if (upload == null ||
        state.ledger.resolve(upload.token) != state.ledger.resolve(account)) {
      throw MusicApiException(ApiCodes.uploadBidUnknown, 'unknown bid');
    }
    if (upload.finalized) {
      throw MusicApiException(ApiCodes.uploadAlreadyFinalized, 'already finalized');
    }
    final bytes = upload.bytes;
    if (bytes == null) {
      throw MusicApiException(ApiCodes.uploadNoObject, 'no object uploaded yet');
    }
    if (bytes.length != upload.size) {
      throw MusicApiException(
        ApiCodes.uploadSizeMismatch,
        'uploaded ${bytes.length} bytes, declared ${upload.size}',
      );
    }
    upload.finalized = true;
    return MusicJsonReply(upload.assetJson(ctx.baseUrl));
  }

  /// Raw `PUT /r2/{bid}` (no signature, no envelope), R2-style: the
  /// Content-Type must match the signed MIME type.
  MusicReply r2Put(MusicRequestContext ctx, String bid) {
    final upload = state.uploads[bid];
    if (upload == null) return const MusicEmptyReply(status: HttpStatus.notFound);
    final contentType = (ctx.header('Content-Type') ?? '')
        .split(';')
        .first
        .trim();
    if (contentType != upload.mimeType) {
      return const MusicEmptyReply(status: HttpStatus.forbidden);
    }
    upload.bytes = ctx.body;
    return MusicEmptyReply(
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
