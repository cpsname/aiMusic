import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';

import '../support/fake_http_adapter.dart';

const _config = ApiConfig(
  connectTimeout: Duration(seconds: 1),
  sendTimeout: Duration(seconds: 1),
  receiveTimeout: Duration(seconds: 1),
  retryBackoff: [Duration(milliseconds: 1), Duration(milliseconds: 1)],
);

Dio _dio(FakeHttpAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = adapter;
  dio.interceptors.add(RetryInterceptor(dio: dio, config: _config));
  return dio;
}

void main() {
  test('retries transient 503s then succeeds', () async {
    final adapter = FakeHttpAdapter(
      (_, i) => i < 2
          ? jsonResponse({'code': 0}, statusCode: 503)
          : jsonResponse({'code': 0, 'data': 'ok'}),
    );
    final response = await _dio(adapter).get<dynamic>('/x');
    expect(response.statusCode, 200);
    expect(adapter.calls, 3); // initial + 2 retries
  });

  test('gives up after maxRetries and throws', () async {
    final adapter = FakeHttpAdapter.always({'code': 0}, statusCode: 503);
    await expectLater(
      _dio(adapter).get<dynamic>('/x'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.calls, _config.maxRetries + 1);
  });

  test('does not retry non-retryable status codes', () async {
    final adapter = FakeHttpAdapter.always({'code': 40001}, statusCode: 400);
    await expectLater(
      _dio(adapter).get<dynamic>('/x'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.calls, 1);
  });
}
