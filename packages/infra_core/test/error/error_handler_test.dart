import 'dart:io' show SocketException;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';

class _RecordingSink implements TelemetrySink {
  final List<Object> errors = [];
  final List<StackTrace?> stacks = [];
  final List<bool> fatals = [];

  @override
  void logEvent(String name, {Map<String, Object?>? properties}) {}

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    Map<String, Object?>? context,
    bool fatal = false,
  }) {
    errors.add(error);
    stacks.add(stackTrace);
    fatals.add(fatal);
  }

  @override
  void breadcrumb(String message, {Map<String, Object?>? data}) {}

  @override
  void setUser(String? anonymousId) {}
}

void main() {
  const handler = ErrorHandler();
  final options = RequestOptions(path: '/x');

  group('ErrorHandler.handle', () {
    test('AuthApiError preserves the force-logout flag', () {
      final failure = handler.handle(
        const AuthApiError(
          code: 40106,
          message: 'reused',
          requiresForceLogout: true,
        ),
      );
      expect(failure, isA<AuthFailure>());
      expect((failure as AuthFailure).requiresForceLogout, isTrue);
    });

    test('ValidationApiError preserves details', () {
      final failure = handler.handle(
        const ValidationApiError(
          code: 40001,
          message: 'bad',
          details: {'field': 'required'},
        ),
      );
      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).details['field'], 'required');
    });

    test('insufficient credits becomes a PaymentFailure', () {
      final failure = handler.handle(
        const InsufficientCreditsApiError(code: 40200, message: 'no credits'),
      );
      expect(failure, isA<PaymentFailure>());
    });

    test('rate limit preserves retryAfterSeconds', () {
      final failure = handler.handle(
        const RateLimitApiError(
          code: 42901,
          message: 'slow down',
          retryAfterSeconds: 12,
        ),
      );
      expect((failure as RateLimitFailure).retryAfterSeconds, 12);
    });

    test('transport timeouts become NetworkFailure(kind: timeout)', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        final failure = handler.handle(
          DioException(requestOptions: options, type: type),
        );
        expect(failure, isA<NetworkFailure>(), reason: '$type');
        expect((failure as NetworkFailure).kind, NetworkFailureKind.timeout,
            reason: '$type');
      }
    });

    test('connectionError becomes NetworkFailure(kind: offline)', () {
      final failure = handler.handle(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
      expect(failure, isA<NetworkFailure>());
      expect((failure as NetworkFailure).kind, NetworkFailureKind.offline);
    });

    test('badCertificate becomes NetworkFailure(kind: unknown)', () {
      final failure = handler.handle(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badCertificate,
        ),
      );
      expect(failure, isA<NetworkFailure>());
      expect((failure as NetworkFailure).kind, NetworkFailureKind.unknown);
    });

    test('unknown wrapping a SocketException becomes offline NetworkFailure', () {
      // DioException.type defaults to DioExceptionType.unknown.
      final failure = handler.handle(
        DioException(
          requestOptions: options,
          error: const SocketException('no route to host'),
        ),
      );
      expect(failure, isA<NetworkFailure>());
      expect((failure as NetworkFailure).kind, NetworkFailureKind.offline);
    });

    test('unknown without a SocketException falls back to ServerFailure', () {
      final failure = handler.handle(
        DioException(requestOptions: options, error: 'something odd'),
      );
      expect(failure, isA<ServerFailure>());
    });

    test('badResponse 5xx stays a ServerFailure with the status code', () {
      final failure = handler.handle(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 503,
            data: 'Service Unavailable',
          ),
        ),
      );
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).code, 503);
    });

    test('DioException wrapping an ApiError is unwrapped and mapped', () {
      final failure = handler.handle(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          error: const AuthApiError(
            code: 40102,
            message: 'expired',
            requiresForceLogout: false,
          ),
        ),
      );
      expect(failure, isA<AuthFailure>());
    });

    test('badResponse with an envelope body is parsed', () {
      final failure = handler.handle(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: {'code': 40200, 'message': 'no credits'},
          ),
        ),
      );
      expect(failure, isA<PaymentFailure>());
    });

    test('an existing Failure passes through untouched', () {
      const original = StoreFailure(message: 'store down', code: 50301);
      expect(identical(handler.handle(original), original), isTrue);
    });

    test('arbitrary errors fall back to ServerFailure with NO raw message', () {
      // The raw toString() is a diagnostic, never user-facing copy — it must not
      // leak into Failure.message (the UI maps an empty message to a localized
      // generic). Reaches telemetry separately via the original throwable.
      final failure = handler.handle(StateError('boom'));
      expect(failure, isA<ServerFailure>());
      expect(failure.message, isEmpty);
    });

    test('an arbitrary error is recorded to telemetry before being genericized',
        () {
      // Callers keep only the returned Failure and bootstrap's hooks see only
      // UNCAUGHT errors, so handle() is the last point where the original
      // throwable exists — it must be recorded (non-fatal) or the diagnostic
      // for a caught production fault is lost.
      final sink = _RecordingSink();
      final recording = ErrorHandler(telemetry: sink);
      final error = StateError('boom');
      final stack = StackTrace.current;

      recording.handle(error, stack);

      expect(sink.errors.single, same(error));
      expect(sink.stacks.single, same(stack));
      expect(sink.fatals.single, isFalse);
    });

    test('typed errors are NOT recorded (already mapped / breadcrumbed upstream)',
        () {
      final sink = _RecordingSink();
      final recording = ErrorHandler(telemetry: sink);

      recording.handle(const StoreFailure(message: 'store down'));
      recording.handle(
        const AuthApiError(code: 40102, message: 'x', requiresForceLogout: false),
      );
      recording.handle(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(sink.errors, isEmpty);
    });

    test('transport failures carry no raw diagnostic message', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.connectionError,
        DioExceptionType.badCertificate,
        DioExceptionType.cancel,
      ]) {
        final failure = handler.handle(
          DioException(
            requestOptions: options,
            type: type,
            error: 'internal dio detail',
            message: 'internal dio detail',
          ),
        );
        expect(failure.message, isEmpty, reason: '$type');
      }
    });
  });

  test('the envelope details.error_code travels to ApiError and Failure', () {
    final apiError = ApiError.fromEnvelope(
      code: 40201,
      message: 'quota',
      details: {ApiError.errorCodeDetailKey: 'QUOTA_EXHAUSTED'},
    );
    expect(apiError, isA<InsufficientCreditsApiError>());
    expect(apiError.errorCode, 'QUOTA_EXHAUSTED');

    final failure = const ErrorHandler().handle(apiError);
    expect(failure, isA<PaymentFailure>());
    expect(failure.errorCode, 'QUOTA_EXHAUSTED');

    final plain = const ErrorHandler().handle(
      ApiError.fromEnvelope(code: 40401, message: 'missing'),
    );
    expect(plain.errorCode, isNull);
  });
}
