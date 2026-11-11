import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';

import '../support/fake_http_adapter.dart';

Dio _dioReturning(Object? body, {int statusCode = 200}) =>
    Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter =
          FakeHttpAdapter.always(body, statusCode: statusCode)
      ..interceptors.add(const EnvelopeInterceptor());

void main() {
  test('unwraps data on code == 0', () async {
    final dio = _dioReturning({
      'code': 0,
      'message': 'success',
      'data': {'balance': 100},
    });
    final response = await dio.get<dynamic>('/wallet');
    expect(response.data, {'balance': 100});
  });

  test('converts a non-zero code into a typed ApiError', () async {
    final dio = _dioReturning({'code': 40200, 'message': 'no credits'});
    try {
      await dio.get<dynamic>('/x');
      fail('expected a DioException');
    } on DioException catch (e) {
      expect(e.error, isA<InsufficientCreditsApiError>());
      expect((e.error! as ApiError).message, 'no credits');
    }
  });

  test('passes through a non-envelope payload untouched', () async {
    final dio = _dioReturning([1, 2, 3]);
    final response = await dio.get<dynamic>('/x');
    expect(response.data, [1, 2, 3]);
  });

  test('maps an envelope error body on a real HTTP error status', () async {
    final dio = _dioReturning(
      {'code': 40405, 'message': 'order missing'},
      statusCode: 404,
    );
    try {
      await dio.get<dynamic>('/x');
      fail('expected a DioException');
    } on DioException catch (e) {
      expect(e.error, isA<NotFoundApiError>());
    }
  });
}
