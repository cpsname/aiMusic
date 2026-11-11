import 'package:meta/meta.dart';

import '../error/api_error.dart';

/// The unified response envelope: `{code, message, data, details, request_id,
/// timestamp}`. `code == 0` is success; any other value is a typed [ApiError].
@immutable
class ApiEnvelope {
  const ApiEnvelope({
    required this.code,
    required this.message,
    this.data,
    this.details,
    this.requestId,
    this.timestamp,
  });

  factory ApiEnvelope.fromMap(Map<dynamic, dynamic> map) {
    final rawCode = map['code'];
    final rawDetails = map['details'];
    return ApiEnvelope(
      code: rawCode is int ? rawCode : int.tryParse('$rawCode') ?? 0,
      message: map['message'] is String ? map['message'] as String : '',
      data: map['data'],
      details: rawDetails is Map
          ? rawDetails.map(
              (dynamic k, dynamic v) => MapEntry(k.toString(), v.toString()),
            )
          : null,
      requestId: map['request_id'] is String ? map['request_id'] as String : null,
      timestamp: map['timestamp'] is int ? map['timestamp'] as int : null,
    );
  }

  final int code;
  final String message;
  final Object? data;
  final Map<String, String>? details;
  final String? requestId;
  final int? timestamp;

  bool get isSuccess => code == 0;

  /// `RequestOptions.extra` key under which the `EnvelopeInterceptor` stashes the
  /// envelope's `request_id`, so later interceptors (logging / telemetry) can
  /// correlate the round trip even after the envelope is unwrapped.
  static const String requestIdExtraKey = 'api_request_id';

  /// A payload is an envelope when it is a map carrying a numeric `code` field.
  static bool looksLikeEnvelope(Object? payload) =>
      payload is Map && payload['code'] is int;

  ApiError toApiError() => ApiError.fromEnvelope(
        code: code,
        message: message,
        requestId: requestId,
        details: details,
      );
}
