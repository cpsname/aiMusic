import 'dart:io' show SocketException;

import 'package:dio/dio.dart';

import '../observability/telemetry_sink.dart';
import 'api_error.dart';
import 'failure.dart';

/// Single funnel that turns any thrown object into a typed [Failure].
///
/// Order of resolution: an already-typed [Failure] passes through; a typed
/// [ApiError] (usually attached to a `DioException` by the EnvelopeInterceptor)
/// is mapped; transport-level `DioException`s become [NetworkFailure]/
/// [ServerFailure]; anything else falls back to [ServerFailure] — recorded to
/// [telemetry] first, because callers keep only the returned [Failure] and
/// bootstrap's hooks see only UNCAUGHT errors, so this is the last point where
/// the original throwable exists.
class ErrorHandler {
  const ErrorHandler({TelemetrySink telemetry = const NoopTelemetrySink()})
      : _telemetry = telemetry;

  final TelemetrySink _telemetry;

  Failure handle(Object error, [StackTrace? stackTrace]) {
    if (error is Failure) return error;
    if (error is ApiError) return _fromApiError(error);
    if (error is DioException) return _fromDio(error);
    // An arbitrary throwable's toString() is a diagnostic, not user copy — the
    // UI maps the empty message to a localized generic. Record the original
    // object here so the diagnostic survives for triage; it exists nowhere
    // else after this returns.
    _telemetry.recordError(error, stackTrace, fatal: false);
    return const ServerFailure(message: '');
  }

  Failure _fromApiError(ApiError error) => switch (error) {
        AuthApiError(:final requiresForceLogout) => AuthFailure(
            message: error.message,
            code: error.code,
            requestId: error.requestId,
            errorCode: error.errorCode,
            details: error.details,
            requiresForceLogout: requiresForceLogout,
          ),
        SignatureApiError() => SignatureFailure(
            message: error.message,
            code: error.code,
            requestId: error.requestId,
            errorCode: error.errorCode,
            details: error.details,
          ),
        ValidationApiError() => ValidationFailure(
            message: error.message,
            code: error.code,
            requestId: error.requestId,
            errorCode: error.errorCode,
            details: error.details,
          ),
        InsufficientCreditsApiError() => PaymentFailure(
            message: error.message,
            code: error.code,
            requestId: error.requestId,
            errorCode: error.errorCode,
            details: error.details,
          ),
        RateLimitApiError(:final retryAfterSeconds) => RateLimitFailure(
            message: error.message,
            code: error.code,
            requestId: error.requestId,
            errorCode: error.errorCode,
            details: error.details,
            retryAfterSeconds: retryAfterSeconds,
          ),
        ContentFilterApiError() => ContentFilterFailure(
            message: error.message,
            code: error.code,
            requestId: error.requestId,
            errorCode: error.errorCode,
            details: error.details,
          ),
        // 403 account/permission states surface in the auth domain.
        PermissionApiError() => AuthFailure(
            message: error.message,
            code: error.code,
            requestId: error.requestId,
            errorCode: error.errorCode,
            details: error.details,
          ),
        // Not-found / conflict are surfaced generically; specific retryable
        // conflicts (e.g. 40912) are consumed by orchestrators before here.
        NotFoundApiError() || ConflictApiError() || ServerApiError() =>
          ServerFailure(
            message: error.message,
            code: error.code,
            requestId: error.requestId,
            errorCode: error.errorCode,
            details: error.details,
          ),
      };

  Failure _fromDio(DioException error) {
    final inner = error.error;
    if (inner is ApiError) return _fromApiError(inner);
    if (inner is Failure) return inner;

    // Transport/diagnostic failures carry an EMPTY user-facing message: Dio's
    // `error.message` is an internal diagnostic, never localized copy. The UI
    // maps these to localized generics (network kind → connectivity copy); the
    // round trip already left a masked telemetry breadcrumb (LoggingInterceptor
    // emits method · path · status · error type on every Dio error), so the
    // diagnostic is not lost. Only backend-envelope failures (via
    // `_fromApiError`) carry a user message, which is localized.
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure(message: '', kind: NetworkFailureKind.timeout);
      case DioExceptionType.connectionError:
        return const NetworkFailure(message: '', kind: NetworkFailureKind.offline);
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
        // kind defaults to NetworkFailureKind.unknown.
        return const NetworkFailure(message: '');
      case DioExceptionType.badResponse:
        final parsed = _apiErrorFromResponse(error.response);
        if (parsed != null) return _fromApiError(parsed);
        return ServerFailure(message: '', code: error.response?.statusCode);
      case DioExceptionType.unknown:
        // Dio funnels transport errors it cannot classify here; a wrapped
        // SocketException is a genuine no-connectivity failure (host
        // unreachable / connection refused), not a server error.
        if (error.error is SocketException) {
          return const NetworkFailure(message: '', kind: NetworkFailureKind.offline);
        }
        return const ServerFailure(message: '');
    }
  }

  ApiError? _apiErrorFromResponse(Response<dynamic>? response) {
    final data = response?.data;
    if (data is! Map) return null;
    final code = data['code'];
    if (code is! int || code == 0) return null;
    final details = data['details'];
    return ApiError.fromEnvelope(
      code: code,
      message: data['message'] is String
          ? data['message'] as String
          : 'Request failed',
      requestId: data['request_id'] is String
          ? data['request_id'] as String
          : null,
      details: details is Map
          ? details.map(
              (dynamic k, dynamic v) => MapEntry(k.toString(), v.toString()),
            )
          : null,
    );
  }
}
