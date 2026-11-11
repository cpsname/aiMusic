import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';

/// Envelope `details` travel with every [ApiError] and [Failure], not only the
/// 40001 field map: business errors carry context beside `error_code`
/// (Songlet's `QuotaExhaustedDetails`: numbers as strings, a JSON null as
/// `"null"`), and the UI reads it off the failure.
void main() {
  const details = {
    'error_code': 'QUOTA_EXHAUSTED',
    'reason': 'insufficient',
    'required_credits': '2169',
    'available_credits': '66',
    'recommended_product_id': 'null',
  };

  test('every code family keeps the details it was built from', () {
    for (final code in [49303, 40102, 40106, 40200, 40110, 45100, 40301, 40401, 40901, 42901, 45101, 50000]) {
      final error = ApiError.fromEnvelope(code: code, message: 'm', details: details);
      expect(error.details, details, reason: '$code (${error.runtimeType})');
      final failure = const ErrorHandler().handle(error);
      expect(failure.details, details, reason: '$code → ${failure.runtimeType}');
      expect(failure.errorCode, 'QUOTA_EXHAUSTED');
    }
  });

  test('absent details are an empty map; a 40001 field map is unchanged', () {
    expect(ApiError.fromEnvelope(code: 50000, message: '').details, isEmpty);
    expect(const ErrorHandler().handle(ApiError.fromEnvelope(code: 50000, message: '')).details, isEmpty);
    final validation = const ErrorHandler().handle(
      ApiError.fromEnvelope(code: 40001, message: '', details: {'level': 'unknown level'}),
    );
    expect(validation, isA<ValidationFailure>());
    expect((validation as ValidationFailure).details, {'level': 'unknown level'});
  });

  test('the envelope parser stringifies numbers and nulls so they survive the transport', () {
    final envelope = ApiEnvelope.fromMap({
      'code': 49303,
      'message': 'quota exhausted',
      'data': null,
      'details': {'error_code': 'QUOTA_EXHAUSTED', 'required_credits': 2169, 'recommended_product_id': null},
    });
    expect(envelope.details, {'error_code': 'QUOTA_EXHAUSTED', 'required_credits': '2169', 'recommended_product_id': 'null'});
    expect(envelope.toApiError().details['required_credits'], '2169');
  });
}
