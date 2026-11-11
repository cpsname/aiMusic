import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';

import '../support/fake_http_adapter.dart';

const _env = EnvConfig(
  env: AppEnv.dev,
  baseUrl: 'https://api.test/v1',
  distributionCode: 'ios_global',
  distributionSecret: 'shhh',
  appCode: 'studio_app',
  bundleId: 'com.example.studio',
  iapChannel: 'appstore',
);

void main() {
  test('injects distribution/timestamp/nonce and a matching signature', () async {
    final adapter = FakeHttpAdapter.always({'code': 0, 'data': 'ok'});
    final dio = Dio(BaseOptions(baseUrl: _env.baseUrl))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        SignatureInterceptor(
          config: _env,
          signing: const SigningService(),
          clock: () => DateTime.fromMillisecondsSinceEpoch(1700000000000),
        ),
      );

    await dio.post<dynamic>('/iap/orders', data: {'b': 2, 'a': 1});

    final headers = adapter.requests.single.headers;
    expect(headers[ApiHeaders.distributionCode], 'ios_global');
    expect(headers[ApiHeaders.timestamp], '1700000000');
    final nonce = headers[ApiHeaders.nonce] as String;
    expect(
      nonce,
      matches(RegExp(r'^[0-9a-fA-F-]{36}$')), // UUID v4 shape
    );

    // The signature must match an independent computation over the same inputs.
    final expected = const SigningService().sign(
      secret: 'shhh',
      timestamp: '1700000000',
      nonce: nonce,
      body: {'b': 2, 'a': 1},
    );
    expect(headers[ApiHeaders.appSignature], expected);
  });

  test('a request with no body signs over {}', () async {
    final adapter = FakeHttpAdapter.always({'code': 0});
    final dio = Dio(BaseOptions(baseUrl: _env.baseUrl))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        SignatureInterceptor(
          config: _env,
          signing: const SigningService(),
          clock: () => DateTime.fromMillisecondsSinceEpoch(1700000000000),
        ),
      );

    await dio.get<dynamic>('/wallet');

    final headers = adapter.requests.single.headers;
    final nonce = headers[ApiHeaders.nonce] as String;
    final expected = const SigningService().sign(
      secret: 'shhh',
      timestamp: '1700000000',
      nonce: nonce,
    );
    expect(headers[ApiHeaders.appSignature], expected);
  });
}
