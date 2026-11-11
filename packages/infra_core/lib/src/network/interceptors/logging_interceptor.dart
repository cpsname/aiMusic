import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../observability/telemetry_sink.dart';
import '../api_envelope.dart';

/// Request/response/error logger with two outputs:
///
/// * a **telemetry breadcrumb** on every round trip — `method · path · status ·
///   latency_ms · request_id` — emitted in **all** environments (DF②), so a
///   production IAP failure is traceable and correlatable with backend logs via
///   `request_id`. PII is scrubbed by the wrapping `RedactingTelemetrySink`.
/// * verbose **console** lines (request headers — `Authorization` masked — query,
///   body, and the response/error body) for debugging the signing chain locally.
///   The console output uses [debugPrint] (a no-op in release); [verbose] gates
///   the detailed header/body lines (off in production via the Dio factory).
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({
    void Function(String message)? sink,
    TelemetrySink telemetry = const NoopTelemetrySink(),
    this.verbose = true,
    this.maxBodyChars = 2000,
  })  : _sink = sink ?? _defaultSink,
        _telemetry = telemetry;

  final void Function(String message) _sink;
  final TelemetrySink _telemetry;
  final bool verbose;
  final int maxBodyChars;

  static const String _stopwatchKey = 'log_stopwatch';

  /// Header names whose value is masked (reusable credentials). The per-request
  /// signature/nonce/timestamp are shown — useful for debugging signing, and not
  /// reusable secrets.
  static const Set<String> _maskedHeaders = {'authorization'};

  static void _defaultSink(String message) => debugPrint('[http] $message');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_stopwatchKey] = Stopwatch()..start();
    _sink('→ ${options.method} ${options.uri}');
    if (verbose) {
      options.headers.forEach(
        (key, value) => _sink('    $key: ${_headerValue(key, value)}'),
      );
      if (options.data != null) _sink('    body: ${_body(options.data)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _breadcrumb(response.requestOptions, status: response.statusCode);
    _sink('← ${response.statusCode} ${response.requestOptions.uri}');
    if (verbose && response.data != null) {
      _sink('    body: ${_body(response.data)}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    _breadcrumb(err.requestOptions, status: status, errorType: err.type.name);
    _sink('✗ ${status ?? err.type.name} ${err.requestOptions.uri} '
        '(${err.error ?? err.message})');
    if (verbose && err.response?.data != null) {
      _sink('    body: ${_body(err.response!.data)}');
    }
    handler.next(err);
  }

  /// Compact, masked round-trip record emitted in **all** environments
  /// (request_id + status + latency) for production correlation.
  void _breadcrumb(
    RequestOptions options, {
    int? status,
    String? errorType,
  }) {
    final stopwatch = options.extra[_stopwatchKey];
    final requestId = options.extra[ApiEnvelope.requestIdExtraKey];
    _telemetry.breadcrumb('http', data: {
      'method': options.method,
      'path': options.uri.path,
      'status': ?status,
      if (stopwatch is Stopwatch) 'latency_ms': stopwatch.elapsedMilliseconds,
      if (requestId is String) 'request_id': requestId,
      'error': ?errorType,
    });
  }

  String _headerValue(String key, Object? value) {
    if (!_maskedHeaders.contains(key.toLowerCase())) return '$value';
    final raw = '$value';
    return raw.length <= 12
        ? '***'
        : '${raw.substring(0, 10)}…${raw.substring(raw.length - 4)}';
  }

  String _body(Object? data) {
    String text;
    if (data is String) {
      text = data;
    } else {
      try {
        text = jsonEncode(data);
      } on Object {
        text = '$data';
      }
    }
    return text.length > maxBodyChars
        ? '${text.substring(0, maxBodyChars)}… (${text.length} chars)'
        : text;
  }
}
