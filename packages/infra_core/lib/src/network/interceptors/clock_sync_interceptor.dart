import 'package:dio/dio.dart';

import '../../error/error_codes.dart';
import '../../time/clock_offset_service.dart';
import '../api_headers.dart';

/// Keeps [ClockOffsetService] in sync from the `X-Server-Time` response header
/// and repairs the cold-start race where the very first signed request goes out
/// on an un-corrected device clock.
///
/// * **Continuous correction** — every response/error updates the offset
///   (RTT-compensated) from the header, so a clock that drifts mid-session is
///   tracked. The header is read from the live response only, never from the
///   cache-first `/app/init` body, so it can never feed a stale offset.
/// * **Cold-start re-sign-once** — if a request is rejected for a signature
///   *time-window* code (`40111`/`40112`) and an offset has since been learned,
///   the request is re-dispatched **once**. Re-running the chain re-signs it with
///   the corrected clock. A one-shot flag prevents an infinite loop; a
///   still-failing retry surfaces normally.
class ClockSyncInterceptor extends Interceptor {
  ClockSyncInterceptor({
    required ClockOffsetService clockOffset,
    required Dio dio,
  })  : _clockOffset = clockOffset,
        _dio = dio;

  static const String _sentAtKey = 'clock_sync_sent_at_micros';
  static const String _resyncedKey = 'clock_sync_resynced';

  /// Signature codes that mean "your timestamp is outside the server's window".
  static const Set<int> _timeWindowCodes = {
    ApiCodes.signatureTimestampInvalid, // 40111
    ApiCodes.signatureExpired, // 40112
  };

  final ClockOffsetService _clockOffset;
  final Dio _dio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_sentAtKey] = _clockOffset.deviceNow().microsecondsSinceEpoch;
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    _absorbServerTime(response.headers, response.requestOptions);
    if (_shouldResync(_envelopeCode(response.data), response.requestOptions)) {
      await _resign(
        response.requestOptions,
        onSuccess: handler.resolve,
        onFailure: handler.reject,
      );
      return;
    }
    handler.next(response);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    if (response != null) {
      _absorbServerTime(response.headers, err.requestOptions);
    }
    final code = response == null ? null : _envelopeCode(response.data);
    if (_shouldResync(code, err.requestOptions)) {
      await _resign(
        err.requestOptions,
        onSuccess: handler.resolve,
        onFailure: handler.next,
      );
      return;
    }
    handler.next(err);
  }

  void _absorbServerTime(Headers headers, RequestOptions options) {
    final raw = headers.value(ApiHeaders.serverTime);
    if (raw == null) return;
    final serverEpochMillis = int.tryParse(raw.trim());
    if (serverEpochMillis == null) return;
    final receivedAt = _clockOffset.deviceNow();
    final sentAtMicros = options.extra[_sentAtKey] as int?;
    final sentAt = sentAtMicros == null
        ? receivedAt
        : DateTime.fromMicrosecondsSinceEpoch(
            sentAtMicros,
            isUtc: receivedAt.isUtc,
          );
    _clockOffset.syncFromRoundTrip(
      serverEpochMillis: serverEpochMillis,
      sentAt: sentAt,
      receivedAt: receivedAt,
    );
  }

  bool _shouldResync(int? code, RequestOptions options) =>
      code != null &&
      _timeWindowCodes.contains(code) &&
      _clockOffset.hasOffset &&
      options.extra[_resyncedKey] != true;

  Future<void> _resign(
    RequestOptions options, {
    required void Function(Response<dynamic>) onSuccess,
    required void Function(DioException) onFailure,
  }) async {
    options.extra[_resyncedKey] = true;
    try {
      onSuccess(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      onFailure(e);
    }
  }

  int? _envelopeCode(Object? data) {
    if (data is Map) {
      final code = data['code'];
      if (code is int) return code;
      if (code is String) return int.tryParse(code);
    }
    return null;
  }
}
