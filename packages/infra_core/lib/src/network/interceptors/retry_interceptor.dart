import 'package:dio/dio.dart';

import '../../config/api_config.dart';

/// Retries transient transport faults (connection/timeout errors) and the
/// configured retryable HTTP status codes (408/429/5xx) with per-attempt
/// backoff. Business errors (HTTP 200 + non-zero envelope code) are never
/// retried here — those are handled by domain orchestrators.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({required Dio dio, required ApiConfig config})
      : _dio = dio,
        _config = config;

  static const String _attemptKey = 'retry_attempt';

  final Dio _dio;
  final ApiConfig _config;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra[_attemptKey] as int?) ?? 0;
    if (attempt >= _config.maxRetries || !_isRetryable(err)) {
      handler.next(err);
      return;
    }

    await Future<void>.delayed(_config.retryBackoff[attempt]);

    final options = err.requestOptions;
    options.extra[_attemptKey] = attempt + 1;
    try {
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _isRetryable(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode;
        return status != null && _config.retryableStatusCodes.contains(status);
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return false;
    }
  }
}
