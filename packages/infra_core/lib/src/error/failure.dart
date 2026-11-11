import 'package:meta/meta.dart';

import 'api_error.dart' show ApiError;

/// UI-facing, presentation-oriented error taxonomy. Produced by the
/// [ErrorHandler] from [ApiError]s, `DioException`s, store/platform exceptions
/// and cache faults. Screens switch on these to decide how to react.
@immutable
sealed class Failure {
  const Failure({
    required this.message,
    this.code,
    this.requestId,
    this.errorCode,
    this.details = const <String, String>{},
  });

  final String message;
  final int? code;
  final String? requestId;

  /// The symbolic business error (envelope `details.error_code`, see
  /// [ApiError.errorCode]) — e.g. Songlet's PRD §6.5 codes. Null for transport,
  /// store and config failures.
  final String? errorCode;

  /// The backend envelope's `details` (see [ApiError.details]): validation
  /// reasons per field, or business context beside [errorCode] such as the
  /// credit gap behind a `QUOTA_EXHAUSTED`. Empty for transport, store and
  /// config failures.
  final Map<String, String> details;

  /// Whether re-running the same operation could plausibly succeed. Error
  /// surfaces use it to decide whether to offer a retry at all: a button that
  /// cannot change the outcome reads to the user as a broken button.
  bool get isRetryable => true;

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';
}

final class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
    super.requestId,
    super.errorCode,
    super.details,
    this.requiresForceLogout = false,
  });

  final bool requiresForceLogout;
}

final class PaymentFailure extends Failure {
  const PaymentFailure({
    required super.message,
    super.code,
    super.requestId,
    super.errorCode,
    super.details,
  });
}

final class RateLimitFailure extends Failure {
  const RateLimitFailure({
    required super.message,
    super.code,
    super.requestId,
    super.errorCode,
    super.details,
    this.retryAfterSeconds,
  });

  final int? retryAfterSeconds;
}

final class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
    super.requestId,
    super.errorCode,
    super.details,
  });
}

final class ContentFilterFailure extends Failure {
  const ContentFilterFailure({
    required super.message,
    super.code,
    super.requestId,
    super.errorCode,
    super.details,
  });
}

final class SignatureFailure extends Failure {
  const SignatureFailure({
    required super.message,
    super.code,
    super.requestId,
    super.errorCode,
    super.details,
  });
}

/// This build cannot talk to the backend at all: `config/<env>.json` was never
/// injected, so there is no base URL, no distribution code and no signing
/// secret. Distinct from [SignatureFailure], which is a *server* verdict on a
/// signature we did produce — this one never reaches the network, and unlike
/// every other failure it cannot be retried: a missing `--dart-define` can only
/// be supplied by a new build.
final class ConfigFailure extends Failure {
  const ConfigFailure({required super.message, required this.missingKeys});

  /// Config-file key names with no value, e.g. `DISTRIBUTION_SECRET`.
  final List<String> missingKeys;

  @override
  bool get isRetryable => false;
}

final class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
    super.requestId,
    super.errorCode,
    super.details,
  });
}

/// The transport-level cause behind a [NetworkFailure], used **only** to tailor
/// user-facing copy ("you appear to be offline" vs a generic network error)
/// without re-inspecting the original `DioException`.
///
/// It does NOT describe retry behaviour and must not be used to drive
/// retry/backoff: `RetryInterceptor` auto-retries connect/send/receive timeouts
/// and `connectionError`, but not `badCertificate`, `cancel`, or an unclassified
/// `SocketException` — so two failures sharing a [NetworkFailureKind] may differ
/// in whether the transport already retried them.
enum NetworkFailureKind {
  /// The host could not be reached at all: no connectivity, DNS failure,
  /// connection refused/reset, or an unclassified `SocketException`.
  offline,

  /// A connection stage timed out (connect / send / receive).
  timeout,

  /// A transport failure that could not be classified more precisely
  /// (e.g. a TLS/certificate error, or a cancelled request).
  unknown,
}

final class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
    super.requestId,
    super.errorCode,
    super.details,
    this.kind = NetworkFailureKind.unknown,
  });

  /// The transport cause, for copy selection. Defaults to
  /// [NetworkFailureKind.unknown] so existing constructions stay valid.
  final NetworkFailureKind kind;
}

/// In-app-purchase / store-platform failure (store unavailable, SK platform
/// error, etc.). Cancellation is **not** a failure and never produces one.
final class StoreFailure extends Failure {
  const StoreFailure({required super.message, super.code, super.requestId});
}

final class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code, super.requestId});
}
