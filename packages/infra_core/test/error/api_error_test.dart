import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';

void main() {
  group('ApiError.fromEnvelope', () {
    test('40001 maps to ValidationApiError carrying details', () {
      final error = ApiError.fromEnvelope(
        code: 40001,
        message: 'bad',
        details: {'duration_sec': 'must be in [4,12]'},
      );
      expect(error, isA<ValidationApiError>());
      expect((error as ValidationApiError).details['duration_sec'],
          'must be in [4,12]');
    });

    test('40102 is auth, not force-logout; 40106 is force-logout', () {
      expect(
        (ApiError.fromEnvelope(code: 40102, message: '') as AuthApiError)
            .requiresForceLogout,
        isFalse,
      );
      expect(
        (ApiError.fromEnvelope(code: 40106, message: '') as AuthApiError)
            .requiresForceLogout,
        isTrue,
      );
    });

    test('signature codes map to SignatureApiError', () {
      for (final code in [40110, 40111, 40112, 40113, 40114, 40015]) {
        expect(
          ApiError.fromEnvelope(code: code, message: ''),
          isA<SignatureApiError>(),
          reason: 'code $code',
        );
      }
    });

    test('payment / content / rate-limit / not-found / conflict / permission', () {
      expect(ApiError.fromEnvelope(code: 40200, message: ''),
          isA<InsufficientCreditsApiError>());
      expect(ApiError.fromEnvelope(code: 45100, message: ''),
          isA<ContentFilterApiError>());
      expect(ApiError.fromEnvelope(code: 45110, message: ''),
          isA<ContentFilterApiError>());
      final rate = ApiError.fromEnvelope(
          code: 42901, message: '', retryAfterSeconds: 30);
      expect(rate, isA<RateLimitApiError>());
      expect((rate as RateLimitApiError).retryAfterSeconds, 30);
      expect(ApiError.fromEnvelope(code: 40405, message: ''),
          isA<NotFoundApiError>());
      expect(ApiError.fromEnvelope(code: 40912, message: ''),
          isA<ConflictApiError>());
      expect(ApiError.fromEnvelope(code: 40301, message: ''),
          isA<PermissionApiError>());
    });

    test('5xx and unknown codes fall back to ServerApiError', () {
      expect(ApiError.fromEnvelope(code: 50000, message: ''),
          isA<ServerApiError>());
      expect(ApiError.fromEnvelope(code: 50301, message: ''),
          isA<ServerApiError>());
      expect(ApiError.fromEnvelope(code: 49999, message: ''),
          isA<ServerApiError>());
    });
  });
}
