import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'api_routes.dart';
import 'catalog.dart';
import 'core.dart';
import 'demo.dart';
import 'http_support.dart';
import 'job_runner.dart';
import 'jws.dart';
import 'jwt.dart';
import 'mv_runner.dart';
import 'signature.dart';
import 'state.dart';

/// The dev-only Songlet backend mock (docs/songlet/backend-contract.md).
///
/// * `/v1/*` — app-signed (`X-App-Signature`), JSON envelope, `X-Server-Time`.
/// * `PUT /r2/{bid}` — raw presigned upload target (no signature/envelope).
/// * `GET|HEAD /files/{job}.mp3|.wav`, `/files/{mv}.mp4`, `/files/uploads/{bid}` — media, Range.
/// * `/__admin/*` — test controls (no signature).
class MockServer {
  MockServer({
    this.secret = defaultSecret,
    this.distributionCode = defaultDistributionCode,
    this.stateFile,
    this.assetsDir,
    String? demoManifest,
    void Function(String line)? log,
  }) : _log = log ?? stdout.writeln {
    _verifier = SignatureVerifier(
      secret: secret,
      distributionCode: distributionCode,
      clock: state.clock,
    );
    _tokens = DeviceTokenIssuer(secret: secret, clock: state.clock);
    _runner = JobRunner(state, onChange: _persist);
    _mvRunner = MvRunner(state, onChange: _persist);
    _api = ApiRoutes(state: state, tokens: _tokens, runner: _runner, mvRunner: _mvRunner);
    if (demoManifest != null) state.demo = DemoProfile.load(demoManifest);
  }

  static const String defaultSecret = 'songlet-mock-secret';
  static const String defaultDistributionCode = 'songlet_ios';

  final String secret;
  final String distributionCode;
  final String? stateFile;
  String? assetsDir;
  final void Function(String line) _log;

  final MockState state = MockState();
  late final SignatureVerifier _verifier;
  late final DeviceTokenIssuer _tokens;
  late final JobRunner _runner;
  late final MvRunner _mvRunner;
  late final ApiRoutes _api;
  final Map<String, Uint8List> _fixtures = {};
  HttpServer? _server;

  int get port => _server!.port;

  Future<void> start({int port = 8787, Object? address}) async {
    assetsDir ??= await _defaultAssetsDir();
    _loadState();
    _server = await HttpServer.bind(address ?? InternetAddress.anyIPv4, port);
    _server!.listen((request) => unawaited(_handle(request)));
  }

  Future<void> close() async {
    _runner.cancelAll();
    _mvRunner.cancelAll();
    await _server?.close(force: true);
    _server = null;
  }

  // ── Plumbing ──────────────────────────────────────────────────────────────

  Future<void> _handle(HttpRequest request) async {
    final watch = Stopwatch()..start();
    final response = request.response;
    response.headers.set('X-Server-Time', '${state.clock.nowMs()}');
    String? note;
    try {
      final body = await _readBody(request);
      final reply = await _route(request, body);
      note = reply.logNote;
      _write(request, reply);
      if (request.method != 'GET' && request.method != 'HEAD') _persist();
    } on ApiException catch (e) {
      note = e.errorCode ?? '${e.code}';
      _writeEnvelope(
        response,
        e.httpStatus,
        code: e.code,
        message: e.message,
        details: e.details,
      );
    } on Object catch (e, st) {
      note = '${ApiCodes.serverError}';
      _log('ERROR $e\n$st');
      _writeEnvelope(
        response,
        HttpStatus.internalServerError,
        code: ApiCodes.serverError,
        message: 'internal error: $e',
      );
    }
    await response.close();
    _log(
      '${request.method} ${request.uri.path} ${response.statusCode} '
      '${watch.elapsedMilliseconds}ms${note == null ? '' : ' $note'}',
    );
  }

  static Future<Uint8List> _readBody(HttpRequest request) async {
    final builder = BytesBuilder(copy: false);
    await request.forEach(builder.add);
    return builder.takeBytes();
  }

  Future<Reply> _route(HttpRequest request, Uint8List body) async {
    final segments = request.uri.pathSegments;
    final head = segments.isEmpty ? '' : segments.first;
    switch (head) {
      case '__admin':
        final ctx = RequestContext(
          request,
          body,
          RequestContext.decodeJson(body),
        );
        return _admin(ctx);
      case 'r2' when request.method == 'PUT' && segments.length == 2:
        return _api.r2Put(RequestContext(request, body, null), segments[1]);
      case 'files':
        return _files(RequestContext(request, body, null));
      case 'v1':
        final json = RequestContext.decodeJson(body);
        _verifier.verify(
          header: (name) => request.headers.value(name),
          decodedBody: json,
        );
        return _api.handle(RequestContext(request, body, json));
      default:
        throw ApiException(ApiCodes.notFound, 'not found');
    }
  }

  Map<String, Object?> _envelope({
    int code = 0,
    String message = 'ok',
    Object? data,
    Map<String, Object?>? details,
  }) => {
    'code': code,
    'message': message,
    'data': data,
    'details': details,
    'request_id': uuidV4(),
    'timestamp': state.clock.nowMs(),
  };

  void _writeEnvelope(
    HttpResponse response,
    int status, {
    int code = 0,
    String message = 'ok',
    Object? data,
    Map<String, Object?>? details,
  }) {
    final bytes = utf8.encode(
      jsonEncode(
        _envelope(code: code, message: message, data: data, details: details),
      ),
    );
    response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..headers.contentLength = bytes.length
      ..add(bytes);
  }

  void _write(HttpRequest request, Reply reply) {
    final response = request.response;
    switch (reply) {
      case JsonReply(:final data):
        _writeEnvelope(response, HttpStatus.ok, data: data);
      case BytesReply(:final bytes, :final contentType, :final headers):
        response
          ..statusCode = reply.status
          ..headers.set(HttpHeaders.contentTypeHeader, contentType)
          ..headers.contentLength = bytes.length;
        headers.forEach(response.headers.set);
        if (request.method != 'HEAD') response.add(bytes);
      case EmptyReply(:final headers):
        response
          ..statusCode = reply.status
          ..headers.contentLength = 0;
        headers.forEach(response.headers.set);
    }
  }

  // ── Media ─────────────────────────────────────────────────────────────────

  Reply _files(RequestContext ctx) {
    if (ctx.method != 'GET' && ctx.method != 'HEAD') {
      throw ApiException(ApiCodes.notFound, 'not found');
    }
    final segs = ctx.segments;
    if (segs.length == 3 && segs[1] == 'uploads') {
      final upload = state.uploads[segs[2]];
      if (upload?.bytes == null) {
        throw ApiException(ApiCodes.notFound, 'no such upload');
      }
      return _ranged(ctx, upload!.bytes!, upload.mimeType);
    }
    // Template samples (ADR-0008): the clip fixture for every template.
    if (segs.length == 3 && segs[1] == 'samples' && segs[2].endsWith('.mp3')) {
      return _ranged(ctx, _fixture('clip_30s.mp3'), 'audio/mpeg');
    }
    if (segs.length != 2) throw ApiException(ApiCodes.notFound, 'not found');
    final name = segs[1];
    final ext = p.extension(name);
    if (ext == '.mp4') {
      // A finished music video: the badge-burned fixture (contract v1.1).
      final mv = state.mvJobs[p.basenameWithoutExtension(name)];
      if (mv == null || mv.status != 'succeeded') {
        throw ApiException(ApiCodes.notFound, 'no video for $name');
      }
      final video = mv.videoFile;
      return _ranged(ctx, video == null ? _fixture('mv_15s.mp4') : _file(video), 'video/mp4');
    }
    final job = state.jobs[p.basenameWithoutExtension(name)];
    if (job == null || job.status != 'succeeded') {
      throw ApiException(ApiCodes.notFound, 'no audio for $name');
    }
    final audio = job.mediaFile;
    return switch (ext) {
      '.mp3' when audio != null => _ranged(ctx, _file(audio), 'audio/mpeg'),
      '.wav' when audio != null => _ranged(ctx, _file(demoWav(audio).path), 'audio/wav'),
      '.mp3' => _ranged(
        ctx,
        _fixture(job.isSong ? 'song_120s.mp3' : 'clip_30s.mp3'),
        'audio/mpeg',
      ),
      '.wav' when job.isSong => _ranged(
        ctx,
        _fixture('song_120s.wav'),
        'audio/wav',
      ),
      _ => throw ApiException(ApiCodes.notFound, 'no audio for $name'),
    };
  }

  /// Serves [bytes] honouring a single `Range: bytes=` request.
  Reply _ranged(RequestContext ctx, Uint8List bytes, String contentType) {
    final total = bytes.length;
    final (int, int)? range;
    try {
      range = parseByteRange(ctx.header('Range'), total);
    } on RangeError {
      return EmptyReply(
        status: HttpStatus.requestedRangeNotSatisfiable,
        headers: {'Content-Range': 'bytes */$total'},
      );
    }
    final common = {'Accept-Ranges': 'bytes', 'Cache-Control': 'no-store'};
    if (range == null) {
      return BytesReply(bytes, contentType: contentType, headers: common);
    }
    final (start, end) = range;
    return BytesReply(
      Uint8List.sublistView(bytes, start, end + 1),
      contentType: contentType,
      status: HttpStatus.partialContent,
      headers: {...common, 'Content-Range': 'bytes $start-$end/$total'},
    );
  }

  Uint8List _fixture(String name) => _fixtures.putIfAbsent(
    name,
    () => File(p.join(assetsDir!, name)).readAsBytesSync(),
  );

  /// A `demo` profile file (absolute path), cached like the fixtures.
  Uint8List _file(String path) => _fixtures.putIfAbsent(path, () => File(path).readAsBytesSync());

  static Future<String> _defaultAssetsDir() async {
    final lib = await Isolate.resolvePackageUri(
      Uri.parse('package:songlet_mock_server/songlet_mock_server.dart'),
    );
    if (lib != null && lib.scheme == 'file') {
      return p.join(p.dirname(p.dirname(lib.toFilePath())), 'assets');
    }
    for (final candidate in ['assets', p.join('mock_server', 'assets')]) {
      if (Directory(candidate).existsSync()) return p.absolute(candidate);
    }
    return p.absolute('assets');
  }

  // ── Admin ─────────────────────────────────────────────────────────────────

  Reply _admin(RequestContext ctx) {
    final action = ctx.segments.length == 2 ? ctx.segments[1] : '';
    final body = ctx.jsonMap;
    return switch ((ctx.method, action)) {
      ('POST', 'reset') => _adminReset(),
      ('GET', 'config') => JsonReply(state.config.toJson()),
      ('POST', 'config') => _adminConfig(body),
      ('POST', 'fail_next') => _adminFailNext(body),
      ('POST', 'advance_clock') => _adminAdvance(body),
      ('POST', 'notify') => _adminNotify(body),
      ('POST', 'grant') => _adminGrant(body),
      ('GET', 'demo') => JsonReply({'demo': state.demo?.toJson()}),
      ('POST', 'demo') => _adminDemo(body),
      ('GET', 'state') => JsonReply(dumpState()),
      _ => throw ApiException(ApiCodes.notFound, 'no admin route $action'),
    };
  }

  Reply _adminReset() {
    _runner.cancelAll();
    _mvRunner.cancelAll();
    state.reset();
    _verifier.reset();
    return const JsonReply({'reset': true});
  }

  Reply _adminConfig(Map<String, Object?> body) {
    state.config.apply(body);
    return JsonReply(state.config.toJson());
  }

  /// `POST /__admin/demo {manifest?, script?, locale?}`: switches the `demo`
  /// profile on with a preview manifest (`manifest: null` → off), and/or
  /// selects the song the next job makes (demo.dart).
  Reply _adminDemo(Map<String, Object?> body) {
    if (body.containsKey('manifest')) {
      final manifest = optionalString(body, 'manifest');
      state.demo = manifest == null ? null : DemoProfile.load(manifest);
    }
    final script = optionalString(body, 'script');
    final locale = optionalString(body, 'locale');
    if (script != null || locale != null) {
      final demo = state.demo ?? (throw ApiException.validation('manifest', 'the demo profile is off'));
      demo.select(
        script ?? (throw ApiException.validation('script', 'required with locale')),
        locale ?? (throw ApiException.validation('locale', 'required with script')),
      );
    }
    return JsonReply({'demo': state.demo?.toJson()});
  }

  Reply _adminFailNext(Map<String, Object?> body) {
    final code = optionalString(body, 'error_code');
    if (code != null && !SongletErrors.forceable.contains(code)) {
      throw ApiException.validation(
        'error_code',
        'must be one of ${SongletErrors.forceable}',
      );
    }
    state.failNext = code;
    return JsonReply({'fail_next': code});
  }

  Reply _adminAdvance(Map<String, Object?> body) {
    final days = optionalNum(body, 'days') ?? 0;
    final hours = optionalNum(body, 'hours') ?? 0;
    final minutes = optionalNum(body, 'minutes') ?? 0;
    final ms = ((days * 24 + hours) * 60 + minutes) * 60 * 1000;
    state.clock.offset += Duration(milliseconds: ms.round());
    return JsonReply({
      'now': state.clock.now().toIso8601String(),
      'offset_ms': state.clock.offset.inMilliseconds,
    });
  }

  Reply _adminNotify(Map<String, Object?> body) {
    final type = requireString(body, 'notification_type').toUpperCase();
    final txId = optionalString(body, 'transaction_id');
    final origId = optionalString(body, 'original_transaction_id');
    if (txId == null && origId == null) {
      throw ApiException.validation(
        'transaction_id',
        'or original_transaction_id is required',
      );
    }
    return JsonReply({
      'notification_type': type,
      ...state.ledger.notify(
        type: type,
        nowMs: state.clock.nowMs(),
        transactionId: txId,
        originalTransactionId: origId,
      ),
    });
  }

  /// `POST /__admin/grant {product_id, app_account_token?, storefront?}`:
  /// records a purchase for an account as if App Store Server Notifications V2
  /// (SUBSCRIBED / ONE_TIME_CHARGE) had delivered it — the server-side half of
  /// a purchase, for driving the client when no StoreKit environment is
  /// available (e.g. headless simulator runs). Defaults to the most recently
  /// created account.
  Reply _adminGrant(Map<String, Object?> body) {
    final productId = requireString(body, 'product_id');
    final spec = Catalog.products[productId];
    if (spec == null) {
      throw ApiException.validation('product_id', 'unknown product $productId');
    }
    final token = optionalString(body, 'app_account_token') ??
        (state.ledger.accounts.isEmpty
            ? throw ApiException.validation('app_account_token', 'no account yet')
            : state.ledger.accounts.keys.last);
    final nowMs = state.clock.nowMs();
    final id = 'grant-${state.ledger.transactions.length + 1}-$nowMs';
    final isSub = spec.kind == ProductKind.subscription;
    final st = SignedTransaction(
      transactionId: id,
      originalTransactionId: id,
      productId: productId,
      purchaseDate: nowMs,
      originalPurchaseDate: nowMs,
      expiresDate: isSub
          ? addMonths(
              DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true),
              spec.isYearly ? 12 : 1,
            ).millisecondsSinceEpoch
          : null,
      type: isSub ? 'Auto-Renewable Subscription' : 'Consumable',
      appAccountToken: token,
      storefront: optionalString(body, 'storefront') ?? 'USA',
    );
    state.ledger.sync(token, [st]);
    return JsonReply({
      'transaction_id': id,
      'app_account_token': token,
      'status': state.ledger.status(state.ledger.resolve(token), nowMs).toJson(),
    });
  }

  /// `GET /__admin/state`: everything, plus each account's computed status.
  Map<String, Object?> dumpState() {
    final nowMs = state.clock.nowMs();
    final ledger = state.ledger;
    return {
      'now': state.clock.now().toIso8601String(),
      'clock_offset_ms': state.clock.offset.inMilliseconds,
      'config': state.config.toJson(),
      'fail_next': state.failNext,
      'accounts': [
        for (final a in ledger.accounts.values)
          {
            ...a.toJson(),
            'linked_tokens': [
              for (final e in ledger.links.entries)
                if (ledger.resolve(e.key) == a.id) e.key,
            ],
            'status': {
              ...ledger.status(a.id, nowMs).toJson(),
              // Music-video credits (contract v1.1 §5; not on the sync wire).
              'credits': ledger.creditsAvailable(a.id),
            },
          },
      ],
      'transactions': [
        for (final t in ledger.transactions.values)
          {...t.toJson(), 'owner': ledger.resolve(t.accountId)},
      ],
      'jobs': [for (final j in state.jobs.values) j.toJson()],
      'mv_jobs': [for (final j in state.mvJobs.values) j.toJson()],
      'uploads': [
        for (final u in state.uploads.values) u.toJson(withBytes: false),
      ],
    };
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  void _loadState() {
    final path = stateFile;
    if (path == null) return;
    final file = File(path);
    if (!file.existsSync()) return;
    final raw = jsonDecode(file.readAsStringSync());
    if (raw is! Map<String, Object?>) return;
    state.loadJson(raw);
    for (final job in state.jobs.values.where((j) => !j.terminal)) {
      _runner.start(job);
    }
    for (final mv in state.mvJobs.values.where((j) => !j.terminal)) {
      _mvRunner.start(mv);
    }
    _log(
      'loaded state from $path (${state.jobs.length} jobs, '
      '${state.ledger.accounts.length} accounts)',
    );
  }

  void _persist() {
    final path = stateFile;
    if (path == null) return;
    File(path).writeAsStringSync(jsonEncode(state.toJson()));
  }
}
