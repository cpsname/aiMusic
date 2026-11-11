import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';

class _BreadcrumbSink implements TelemetrySink {
  final List<(String, Map<String, Object?>?)> breadcrumbs = [];

  @override
  void breadcrumb(String message, {Map<String, Object?>? data}) =>
      breadcrumbs.add((message, data));

  @override
  void logEvent(String name, {Map<String, Object?>? properties}) {}

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    Map<String, Object?>? context,
    bool fatal = false,
  }) {}

  @override
  void setUser(String? anonymousId) {}
}

void main() {
  test('request: logs method/url + headers + body, masks the bearer token', () {
    final lines = <String>[];
    LoggingInterceptor(sink: lines.add).onRequest(
      RequestOptions(
        path: '/orders',
        method: 'POST',
        baseUrl: 'https://api.test/v1',
        headers: {
          'Authorization': 'Bearer eyJ0aGlzaXNhbG9uZ3Rva2Vu',
          'X-Nonce': 'nonce-123',
        },
        data: {'product_code': 'pro'},
      ),
      RequestInterceptorHandler(),
    );

    final out = lines.join('\n');
    expect(out, contains('→ POST https://api.test/v1/orders'));
    expect(out, contains('X-Nonce: nonce-123')); // non-sensitive shown
    expect(out, contains('body: {"product_code":"pro"}'));
    expect(out, isNot(contains('eyJ0aGlzaXNhbG9uZ3Rva2Vu'))); // bearer masked
    expect(
      lines.any((l) => l.contains('Authorization') && l.contains('…')),
      isTrue,
    );
  });

  test('response: logs status + body', () {
    final lines = <String>[];
    LoggingInterceptor(sink: lines.add).onResponse(
      Response<dynamic>(
        requestOptions:
            RequestOptions(path: '/wallet', baseUrl: 'https://api.test/v1'),
        statusCode: 200,
        data: {'balance': 0},
      ),
      ResponseInterceptorHandler(),
    );

    final out = lines.join('\n');
    expect(out, contains('← 200 https://api.test/v1/wallet'));
    expect(out, contains('body: {"balance":0}'));
  });

  test('verbose=false logs only the request line (no headers/body)', () {
    final lines = <String>[];
    LoggingInterceptor(sink: lines.add, verbose: false).onRequest(
      RequestOptions(
        path: '/x',
        baseUrl: 'https://api.test/v1',
        headers: {'X-Nonce': 'n'},
        data: {'a': 1},
      ),
      RequestInterceptorHandler(),
    );

    expect(lines, hasLength(1));
    expect(lines.single, startsWith('→'));
  });

  test('emits a compact http breadcrumb (status + latency + request_id)', () {
    final telemetry = _BreadcrumbSink();
    final interceptor = LoggingInterceptor(
      sink: (_) {},
      telemetry: telemetry,
      verbose: false, // even with console off, the breadcrumb is emitted
    );
    final options = RequestOptions(
      path: '/wallet',
      method: 'GET',
      baseUrl: 'https://api.test/v1',
    );

    interceptor.onRequest(options, RequestInterceptorHandler());
    // The EnvelopeInterceptor stashes request_id before logging runs.
    options.extra[ApiEnvelope.requestIdExtraKey] = 'req-abc-123';
    interceptor.onResponse(
      Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: {'balance': 0},
      ),
      ResponseInterceptorHandler(),
    );

    final (name, data) = telemetry.breadcrumbs.last;
    expect(name, 'http');
    expect(data!['method'], 'GET');
    expect(data['path'], contains('wallet'));
    expect(data['status'], 200);
    expect(data['request_id'], 'req-abc-123');
    expect(data['latency_ms'], isA<int>());
  });
}
