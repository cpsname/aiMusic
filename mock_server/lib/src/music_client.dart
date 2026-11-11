import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'music_core.dart';
import 'music_jws.dart';
import 'music_server.dart';
import 'music_signature.dart';

/// A response as seen by a test / script client.
class MusicMockResponse {
  MusicMockResponse(this.status, this.headers, this.bytes);

  final int status;
  final HttpHeaders headers;
  final Uint8List bytes;

  Map<String, Object?> get json =>
      (jsonDecode(utf8.decode(bytes)) as Map).cast<String, Object?>();

  /// Envelope `code`.
  int get code => json['code']! as int;

  Map<String, Object?> get data =>
      (json['data']! as Map).cast<String, Object?>();

  String? get errorCode => (json['details'] as Map?)?['error_code'] as String?;

  /// The envelope `details` (field errors on 40001, business context beside
  /// `error_code` such as the credit gap on 49303).
  Map<String, Object?>? get details => (json['details'] as Map?)?.cast<String, Object?>();

  @override
  String toString() => '$status ${utf8.decode(bytes, allowMalformed: true)}';
}

/// Minimal client that signs exactly like `infra_core`'s
/// `SignatureInterceptor` (+ bearer + Songlet headers). Used by the tests and
/// `tool/happy_path.dart`.
class MusicMockClient {
  MusicMockClient({
    required this.baseUrl,
    this.secret = MusicMockServer.defaultSecret,
    this.distributionCode = MusicMockServer.defaultDistributionCode,
    String? appAccountToken,
    this.storefront = 'USA',
    this.deviceRegion = 'US',
    this.clockOffset = Duration.zero,
  }) : appAccountToken = appAccountToken ?? uuidV4();

  /// Server origin, e.g. `http://localhost:8787` (no `/v1`).
  final String baseUrl;
  final String secret;
  final String distributionCode;
  final String appAccountToken;
  String storefront;
  String deviceRegion;

  /// Added to the local clock when signing (emulates `ClockOffsetService`).
  Duration clockOffset;
  String? deviceToken;

  final HttpClient _http = HttpClient();

  void close() => _http.close(force: true);

  /// Signed `/v1` call. [path] is relative to `/v1` (e.g. `/generate`).
  Future<MusicMockResponse> call(
    String method,
    String path, {
    Map<String, Object?>? body,
    bool sign = true,
    bool auth = true,
    Map<String, String> headers = const {},
    String? secretOverride,
  }) async {
    final request = await _http.openUrl(method, Uri.parse('$baseUrl/v1$path'));
    if (sign) {
      final ts =
          (DateTime.now().add(clockOffset).millisecondsSinceEpoch ~/ 1000)
              .toString();
      final nonce = uuidV4();
      request.headers
        ..set(SignatureHeaders.distributionCode, distributionCode)
        ..set(SignatureHeaders.timestamp, ts)
        ..set(SignatureHeaders.nonce, nonce)
        ..set(
          SignatureHeaders.appSignature,
          computeAppSignature(
            secret: secretOverride ?? secret,
            timestamp: ts,
            nonce: nonce,
            body: body,
          ),
        );
    }
    request.headers
      ..set('X-Device-ID', appAccountToken)
      ..set('X-Platform', 'ios')
      ..set('X-Storefront', storefront)
      ..set('X-Device-Region', deviceRegion);
    if (auth && deviceToken != null) {
      request.headers.set('Authorization', 'Bearer $deviceToken');
    }
    headers.forEach(request.headers.set);
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode(body)));
    }
    return _finish(request);
  }

  /// Unsigned call to any absolute path (admin, files, r2).
  Future<MusicMockResponse> raw(
    String method,
    String url, {
    Object? json,
    List<int>? bytes,
    Map<String, String> headers = const {},
  }) async {
    final uri = url.startsWith('http')
        ? Uri.parse(url)
        : Uri.parse('$baseUrl$url');
    final request = await _http.openUrl(method, uri);
    headers.forEach(request.headers.set);
    if (json != null) {
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode(json)));
    } else if (bytes != null) {
      request.headers.contentLength = bytes.length;
      request.add(bytes);
    }
    return _finish(request);
  }

  Future<MusicMockResponse> admin(String action, [Map<String, Object?>? json]) =>
      raw(
        json == null && action == 'state' ? 'GET' : 'POST',
        '/__admin/$action',
        json: json ?? (action == 'state' ? null : const {}),
      );

  Future<MusicMockResponse> _finish(HttpClientRequest request) async {
    final response = await request.close();
    final builder = BytesBuilder(copy: false);
    await response.forEach(builder.add);
    return MusicMockResponse(
      response.statusCode,
      response.headers,
      builder.takeBytes(),
    );
  }

  /// `challenge = <token>.<unix_ms>.<uuid>`.
  String newChallenge() =>
      '$appAccountToken.'
      '${DateTime.now().add(clockOffset).millisecondsSinceEpoch}.${uuidV4()}';

  /// Attests (simulator flavour by default) and stores the device token.
  Future<MusicMockResponse> attest({
    bool unsupported = true,
    String? challenge,
  }) async {
    final res = await call(
      'POST',
      '/attest',
      auth: false,
      body: {
        'app_account_token': appAccountToken,
        'challenge': challenge ?? newChallenge(),
        'key_id': 'bW9jay1rZXk=',
        if (unsupported) 'unsupported': true else 'assertion': 'bW9jaw==',
      },
    );
    if (res.code == 0) deviceToken = res.data['device_token']! as String;
    return res;
  }

  Future<MusicMockResponse> generate({
    String model = 'lyria-3-clip-preview',
    String occasion = 'birthday',
    String region = 'US',
    String recipient = 'Alex',
    String keywords = 'coffee | hiking | Sunday',
    String lyricLanguage = 'en',
    String? lyrics,
    List<String>? images,
    String? clientRef,
    String? inspiration,
    String vocals = 'vocals',
    String? description,
  }) => call(
    'POST',
    '/generate',
    body: {
      'model': model,
      'occasion': occasion,
      'inspiration': ?inspiration,
      'region': region,
      'prompt': [
        if (inspiration != null) 'inspiration: $inspiration',
        if (recipient.isNotEmpty) 'recipient: $recipient',
        if (keywords.isNotEmpty) 'keywords: $keywords',
        if (description != null) 'description: $description',
        'genre: Indie Pop',
        'vocals: $vocals',
        'lyric_language: $lyricLanguage',
      ].join('\n'),
      'lyrics': ?lyrics,
      'images': ?images,
      'client_ref': clientRef ?? uuidV4(),
    },
  );

  Future<MusicMockResponse> job(String id) => call('GET', '/jobs/$id');

  // ── Music videos (contract v1.1) ──

  Future<MusicMockResponse> mvEstimate(String jobId, String level) =>
      call('POST', '/mv/estimate', body: {'job_id': jobId, 'level': level});

  Future<MusicMockResponse> mvCreate(
    String jobId, {
    String level = 'chorus_mv',
    String? clientRef,
    Map<String, Object?> options = const {},
  }) => call(
    'POST',
    '/works/$jobId/mv',
    body: {'level': level, 'client_ref': clientRef ?? uuidV4(), ...options},
  );

  Future<MusicMockResponse> mv(String id) => call('GET', '/mv/$id');

  Future<MusicMockResponse> cancelMv(String id) => call('DELETE', '/mv/$id');

  /// Polls a music video until it reaches [until] (default: terminal).
  Future<Map<String, Object?>> waitMv(
    String id, {
    Set<String> until = const {'succeeded', 'failed'},
    Duration timeout = const Duration(seconds: 30),
    Duration every = const Duration(milliseconds: 25),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (true) {
      final data = (await mv(id)).data;
      if (until.contains(data['status']) || until.contains(data['stage'])) return data;
      if (DateTime.now().isAfter(deadline)) throw StateError('mv $id stuck at $data');
      await Future<void>.delayed(every);
    }
  }

  Future<MusicMockResponse> cancelJob(String id) => call('DELETE', '/jobs/$id');

  Future<MusicMockResponse> templates() => call('GET', '/templates');

  Future<MusicMockResponse> sync(List<Map<String, Object?>> payloads) => call(
    'POST',
    '/entitlements/sync',
    body: {
      'app_account_token': appAccountToken,
      'signed_transactions': [for (final p in payloads) encodeFixtureJws(p)],
    },
  );

  /// Polls a job until it reaches [until] (default: a terminal status).
  Future<Map<String, Object?>> waitJob(
    String id, {
    Set<String> until = const {'succeeded', 'failed'},
    Duration timeout = const Duration(seconds: 30),
    Duration every = const Duration(milliseconds: 25),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (true) {
      final data = (await job(id)).data;
      if (until.contains(data['status'])) return data;
      if (DateTime.now().isAfter(deadline)) {
        throw StateError('job $id stuck at $data');
      }
      await Future<void>.delayed(every);
    }
  }
}
