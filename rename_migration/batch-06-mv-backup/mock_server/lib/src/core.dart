import 'dart:io' show HttpStatus;
import 'dart:math';

/// Simulated wall clock: real UTC now + an admin-controlled offset
/// (`POST /__admin/advance_clock`). Every time-dependent rule (signature
/// window, JWT expiry, subscription periods, `X-Server-Time`) reads this.
class MockClock {
  MockClock({this.offset = Duration.zero});

  Duration offset;

  DateTime now() => DateTime.now().toUtc().add(offset);

  int nowMs() => now().millisecondsSinceEpoch;

  int nowSeconds() => nowMs() ~/ 1000;

  /// Real (un-offset) UTC now, for the few leniency checks that accept the
  /// device's own clock as well.
  DateTime realNow() => DateTime.now().toUtc();
}

final Random _random = Random.secure();

/// A random RFC 4122 v4 UUID (lowercase, dashed).
String uuidV4() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// [length] random lowercase hex characters.
String randomHex(int length) {
  final sb = StringBuffer();
  for (var i = 0; i < length; i++) {
    sb.write(_random.nextInt(16).toRadixString(16));
  }
  return sb.toString();
}

/// PRD §6.5 error strings → envelope `code` (HTTP status: see
/// [ApiException.httpStatus]).
abstract final class SongletErrors {
  static const String safetyBlocked = 'SAFETY_BLOCKED';
  static const String imageRejected = 'IMAGE_REJECTED';
  static const String quotaExhausted = 'QUOTA_EXHAUSTED';
  static const String upstreamTimeout = 'UPSTREAM_TIMEOUT';
  static const String upstreamRateLimited = 'UPSTREAM_RATE_LIMITED';
  static const String regionUnavailable = 'REGION_UNAVAILABLE';
  static const String attestFailed = 'ATTEST_FAILED';
  static const String downloadLocked = 'DOWNLOAD_LOCKED';

  /// `DELETE /v1/jobs/{id}` on a job that already reached a terminal state
  /// (contract v2, platform decision 2026-09-27).
  static const String jobAlreadyFinished = 'JOB_ALREADY_FINISHED';

  // Music videos (contract v1.1 §4, platform 04-errors §2).
  static const String mvSongNotReady = 'MV_SONG_NOT_READY';
  static const String mvSongTooLong = 'MV_SONG_TOO_LONG';
  static const String mvSongExpired = 'MV_SONG_EXPIRED';
  static const String mvNotFound = 'MV_NOT_FOUND';
  static const String mvPhotosExpired = 'MV_PHOTOS_EXPIRED';
  static const String mvRenderFailed = 'MV_RENDER_FAILED';
  static const String userCancelled = 'USER_CANCELLED';

  static const Map<String, int> codes = {
    safetyBlocked: 45101,
    imageRejected: 45102,
    quotaExhausted: 49303,
    upstreamTimeout: 50401,
    upstreamRateLimited: 42901,
    regionUnavailable: 45103,
    attestFailed: 40140,
    downloadLocked: 40310,
    jobAlreadyFinished: 49309,
    mvSongNotReady: 49312,
    mvSongTooLong: 49313,
    mvSongExpired: 49314,
    mvNotFound: 49315,
    mvPhotosExpired: 49316,
  };

  /// PRD §6.5 user copy (English source strings).
  static const Map<String, String> messages = {
    safetyBlocked:
        "We can't make this one — try different words, and skip artist names.",
    imageRejected: "One of these photos can't be used. Try another.",
    quotaExhausted: "You've used this month's songs. Add a pack or upgrade.",
    upstreamTimeout:
        "Taking longer than usual. We'll keep trying and notify you.",
    upstreamRateLimited: 'Lots of songs being made right now. Yours is queued.',
    regionUnavailable: "Songlet isn't available in your region yet.",
    attestFailed: 'Please update Songlet from the App Store.',
    downloadLocked: 'This download is no longer available for this purchase.',
    jobAlreadyFinished: 'This song is already finished.',
    mvSongNotReady: 'song is not ready for a music video',
    mvSongTooLong: 'song is too long for a music video',
    mvSongExpired: 'song has expired, generate it again',
    mvNotFound: 'music video not found',
    mvPhotosExpired: 'reference photos have expired, upload them again',
  };

  /// Codes a job can end (or pause) with, as opposed to request-time codes.
  static const Set<String> jobLevel = {
    safetyBlocked,
    imageRejected,
    upstreamTimeout,
    upstreamRateLimited,
  };

  /// Request-time codes `fail_next` can force on the next `/v1/generate`.
  static const Set<String> requestLevel = {
    quotaExhausted,
    regionUnavailable,
    attestFailed,
  };

  /// Codes a music video can end with (`fail_next` forces the next MV). A
  /// rejected reference photo or a safety block lands on the first rendered
  /// scene — the segment-level interception of docs/ui P25, fully refunded.
  static const Set<String> mvJobLevel = {mvRenderFailed, upstreamTimeout, imageRejected, safetyBlocked};

  /// Request-time codes `fail_next` can force on the next
  /// `POST /v1/works/{id}/mv` or `POST /v1/mv/estimate`.
  static const Set<String> mvRequestLevel = {
    quotaExhausted,
    mvSongNotReady,
    mvSongTooLong,
    mvSongExpired,
    mvPhotosExpired,
  };

  /// Every code `fail_next` accepts.
  static const Set<String> forceable = {
    ...jobLevel,
    ...requestLevel,
    mvRenderFailed,
    mvSongNotReady,
    mvSongTooLong,
    mvSongExpired,
    mvPhotosExpired,
  };
}

/// Monolith transport / generic codes used by the mock.
abstract final class ApiCodes {
  static const int validationFailed = 40001;
  static const int tokenExpired = 40102;
  static const int signatureHeaderMissing = 40110;
  static const int signatureTimestampInvalid = 40111;
  static const int signatureExpired = 40112;
  static const int signatureNonceReused = 40113;
  static const int signatureInvalid = 40114;
  static const int notFound = 40404;
  static const int serverError = 50000;

  // media_kit UploadErrorCodes.
  static const int uploadMime = 40034;
  static const int uploadSize = 40035;
  static const int uploadHash = 40037;
  static const int uploadSizeMismatch = 40038;
  static const int uploadBidUnknown = 40420;
  static const int uploadNoObject = 40430;
  static const int uploadAlreadyFinalized = 40922;

  /// Songlet business codes the platform returns on HTTP 200 (contract v2 §1,
  /// platform 2026-09-28), e.g. `49309` JOB_ALREADY_FINISHED.
  static const int businessOnOkFirst = 49300;
  static const int businessOnOkLast = 49349;
}

/// A failure rendered as a non-zero envelope.
class ApiException implements Exception {
  ApiException(this.code, this.message, {this.details});

  /// A PRD §6.5 business error: numeric code + `details.error_code`.
  factory ApiException.songlet(String errorCode, {String? message}) =>
      ApiException(
        SongletErrors.codes[errorCode] ?? ApiCodes.serverError,
        message ?? SongletErrors.messages[errorCode] ?? errorCode,
        details: {'error_code': errorCode},
      );

  factory ApiException.validation(String field, String reason) => ApiException(
    ApiCodes.validationFailed,
    'validation failed: $field $reason',
    details: {field: reason},
  );

  final int code;
  final String message;
  final Map<String, Object?>? details;

  /// `code ~/ 100`, except the 49300–49349 business codes, which the platform
  /// carries on HTTP 200.
  int get httpStatus =>
      code >= ApiCodes.businessOnOkFirst && code <= ApiCodes.businessOnOkLast
      ? HttpStatus.ok
      : code ~/ 100;

  String? get errorCode => details?['error_code'] as String?;

  @override
  String toString() => 'ApiException($code, $message)';
}
