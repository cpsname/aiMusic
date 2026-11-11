import 'package:meta/meta.dart';

import 'error_codes.dart';

/// Typed representation of a non-zero backend envelope `code`. The
/// [EnvelopeInterceptor] produces these from `{code, message, ...}` payloads;
/// downstream layers translate them into [Failure]s via the [ErrorHandler].
@immutable
sealed class ApiError implements Exception {
  const ApiError({
    required this.code,
    required this.message,
    this.requestId,
    this.errorCode,
    this.details = const <String, String>{},
  });

  /// Maps an envelope `(code, message, ...)` to the matching typed error.
  factory ApiError.fromEnvelope({
    required int code,
    required String message,
    String? requestId,
    Map<String, String>? details,
    int? retryAfterSeconds,
  }) {
    final errorCode = details?[errorCodeDetailKey];
    switch (code) {
      case ApiCodes.validationFailed:
        return ValidationApiError(
          code: code,
          message: message,
          requestId: requestId,
          errorCode: errorCode,
          details: details ?? const <String, String>{},
        );
      case ApiCodes.tokenExpired:
      case ApiCodes.invalidPassword:
        return AuthApiError(
          code: code,
          message: message,
          requestId: requestId,
          errorCode: errorCode,
          details: details ?? const <String, String>{},
          requiresForceLogout: false,
        );
      case ApiCodes.refreshInvalid:
      case ApiCodes.tokenRevoked:
      case ApiCodes.sessionInvalid:
      case ApiCodes.refreshReused:
      case ApiCodes.refreshMismatch:
        return AuthApiError(
          code: code,
          message: message,
          requestId: requestId,
          errorCode: errorCode,
          details: details ?? const <String, String>{},
          requiresForceLogout: true,
        );
      case ApiCodes.insufficientCredits:
        return InsufficientCreditsApiError(
          code: code,
          message: message,
          requestId: requestId,
          errorCode: errorCode,
        details: details ?? const <String, String>{},
        );
      case ApiCodes.signatureHeaderMissing:
      case ApiCodes.signatureTimestampInvalid:
      case ApiCodes.signatureExpired:
      case ApiCodes.signatureNonceReused:
      case ApiCodes.signatureInvalid:
      case ApiCodes.iapSignatureInvalid:
        return SignatureApiError(
          code: code,
          message: message,
          requestId: requestId,
          errorCode: errorCode,
        details: details ?? const <String, String>{},
        );
      case ApiCodes.promptRejected:
      case ApiCodes.contentFiltered:
        return ContentFilterApiError(
          code: code,
          message: message,
          requestId: requestId,
          errorCode: errorCode,
        details: details ?? const <String, String>{},
        );
    }
    return switch (code ~/ 100) {
      401 => AuthApiError(
          code: code,
          message: message,
          requestId: requestId,
          errorCode: errorCode,
          details: details ?? const <String, String>{},
          requiresForceLogout: false,
        ),
      402 => InsufficientCreditsApiError(
          code: code,
          message: message,
          requestId: requestId,
          errorCode: errorCode,
          details: details ?? const <String, String>{},
        ),
      403 => PermissionApiError(
          code: code,
          message: message,
          requestId: requestId,
          errorCode: errorCode,
          details: details ?? const <String, String>{},
        ),
      404 => NotFoundApiError(
          code: code,
          message: message,
          requestId: requestId,
          errorCode: errorCode,
          details: details ?? const <String, String>{},
        ),
      409 => ConflictApiError(
          code: code,
          message: message,
          requestId: requestId,
          errorCode: errorCode,
          details: details ?? const <String, String>{},
        ),
      429 => RateLimitApiError(
          code: code,
          message: message,
          requestId: requestId,
          errorCode: errorCode,
          details: details ?? const <String, String>{},
          retryAfterSeconds: retryAfterSeconds,
        ),
      451 => ContentFilterApiError(
          code: code,
          message: message,
          requestId: requestId,
          errorCode: errorCode,
          details: details ?? const <String, String>{},
        ),
      _ => ServerApiError(
          code: code,
          message: message,
          requestId: requestId,
          errorCode: errorCode,
          details: details ?? const <String, String>{},
        ),
    };
  }

  final int code;
  final String message;
  final String? requestId;

  /// Symbolic business error name carried in the envelope's
  /// `details.error_code` (e.g. Songlet's PRD §6.5 `QUOTA_EXHAUSTED`), when the
  /// bounded context supplies one. Copy selection keys off it before falling
  /// back to the numeric [code] family.
  final String? errorCode;

  /// The envelope's `details` object, values as strings (numbers keep their
  /// decimal form, `null` becomes `"null"`): field-level validation reasons on
  /// 40001, and business context such as Songlet's `QuotaExhaustedDetails`
  /// (`required_credits`, `available_credits`, `recommended_product_id`).
  final Map<String, String> details;

  /// `details` key holding [errorCode].
  static const String errorCodeDetailKey = 'error_code';

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';
}

final class AuthApiError extends ApiError {
  const AuthApiError({
    required super.code,
    required super.message,
    super.requestId,
    super.errorCode,
    super.details,
    required this.requiresForceLogout,
  });

  /// True when the session is unrecoverable (revoked/reused/session gone) and
  /// the client must clear local state. False for plain access-token expiry.
  final bool requiresForceLogout;
}

final class SignatureApiError extends ApiError {
  const SignatureApiError({
    required super.code,
    required super.message,
    super.requestId,
    super.errorCode,
    super.details,
  });
}

final class ValidationApiError extends ApiError {
  const ValidationApiError({
    required super.code,
    required super.message,
    super.requestId,
    super.errorCode,
    super.details,
  });
}

final class InsufficientCreditsApiError extends ApiError {
  const InsufficientCreditsApiError({
    required super.code,
    required super.message,
    super.requestId,
    super.errorCode,
    super.details,
  });
}

final class RateLimitApiError extends ApiError {
  const RateLimitApiError({
    required super.code,
    required super.message,
    super.requestId,
    super.errorCode,
    super.details,
    this.retryAfterSeconds,
  });

  final int? retryAfterSeconds;
}

final class ConflictApiError extends ApiError {
  const ConflictApiError({
    required super.code,
    required super.message,
    super.requestId,
    super.errorCode,
    super.details,
  });
}

final class ContentFilterApiError extends ApiError {
  const ContentFilterApiError({
    required super.code,
    required super.message,
    super.requestId,
    super.errorCode,
    super.details,
  });
}

final class NotFoundApiError extends ApiError {
  const NotFoundApiError({
    required super.code,
    required super.message,
    super.requestId,
    super.errorCode,
    super.details,
  });
}

final class PermissionApiError extends ApiError {
  const PermissionApiError({
    required super.code,
    required super.message,
    super.requestId,
    super.errorCode,
    super.details,
  });
}

final class ServerApiError extends ApiError {
  const ServerApiError({
    required super.code,
    required super.message,
    super.requestId,
    super.errorCode,
    super.details,
  });
}
