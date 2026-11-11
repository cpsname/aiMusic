import 'dart:convert';

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

ResponseBody _envelope(
  Map<String, dynamic> body, {
  int statusCode = 200,
  int? serverTimeMillis,
}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        if (serverTimeMillis != null)
          ApiHeaders.serverTime: [serverTimeMillis.toString()],
      },
    );

Dio _dioWith(ClockOffsetService clockOffset, FakeHttpAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: _env.baseUrl));
  dio.httpClientAdapter = adapter;
  dio.interceptors.addAll([
    SignatureInterceptor(
      config: _env,
      signing: const SigningService(),
      clock: clockOffset.now,
    ),
    ClockSyncInterceptor(clockOffset: clockOffset, dio: dio),
    const EnvelopeInterceptor(),
  ]);
  return dio;
}

void main() {
  test('the signer uses the corrected clock once an offset is known', () async {
    final device = DateTime.utc(2026, 6, 1, 10);
    final clockOffset = ClockOffsetService(deviceClock: () => device);
    // Pre-load a +5min offset (as if a prior response had synced it).
    clockOffset.syncFromRoundTrip(
      serverEpochMillis:
          device.add(const Duration(minutes: 5)).millisecondsSinceEpoch,
      sentAt: device,
      receivedAt: device,
    );

    final timestamps = <String>[];
    final adapter = FakeHttpAdapter((options, _) {
      timestamps.add(options.headers[ApiHeaders.timestamp] as String);
      return _envelope({'code': 0, 'data': 'ok'});
    });

    await _dioWith(clockOffset, adapter).get<dynamic>('/wallet');

    // Timestamp reflects device+5min, not the raw device clock.
    expect(
      timestamps.single,
      (device.add(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000)
          .toString(),
    );
  });

  test('absorbs X-Server-Time from any response to learn the offset', () async {
    final device = DateTime.utc(2026, 6, 1, 10);
    final clockOffset = ClockOffsetService(deviceClock: () => device);
    final adapter = FakeHttpAdapter(
      (options, _) => _envelope(
        {'code': 0, 'data': 'ok'},
        serverTimeMillis:
            device.add(const Duration(minutes: 7)).millisecondsSinceEpoch,
      ),
    );

    expect(clockOffset.hasOffset, isFalse);
    await _dioWith(clockOffset, adapter).get<dynamic>('/wallet');

    expect(clockOffset.hasOffset, isTrue);
    expect(clockOffset.offset, const Duration(minutes: 7));
  });

  test(
      'cold start: 40111 + X-Server-Time → re-signs once with the corrected '
      'clock → success', () async {
    final device = DateTime.utc(2026, 6, 1, 10);
    final clockOffset = ClockOffsetService(deviceClock: () => device);
    final serverMillis =
        device.add(const Duration(minutes: 5)).millisecondsSinceEpoch;

    final timestamps = <String>[];
    final adapter = FakeHttpAdapter((options, callIndex) {
      timestamps.add(options.headers[ApiHeaders.timestamp] as String);
      if (callIndex == 0) {
        // First attempt signed on the skewed local clock → rejected, but the
        // rejection carries the authoritative server time.
        return _envelope(
          {'code': ApiCodes.signatureTimestampInvalid, 'message': 'bad ts'},
          serverTimeMillis: serverMillis,
        );
      }
      return _envelope({'code': 0, 'data': 'ok'});
    });

    final response =
        await _dioWith(clockOffset, adapter).post<dynamic>('/iap/orders',
            data: {'a': 1});

    // Exactly one retry (two wire calls), and the unwrapped success surfaces.
    expect(adapter.calls, 2);
    expect(response.data, 'ok');
    // First attempt used the raw device clock; the retry used device+5min.
    expect(
      timestamps[0],
      (device.millisecondsSinceEpoch ~/ 1000).toString(),
    );
    expect(
      timestamps[1],
      (device.add(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000)
          .toString(),
    );
  });

  test('a persistent time-window rejection retries only once, then surfaces',
      () async {
    final device = DateTime.utc(2026, 6, 1, 10);
    final clockOffset = ClockOffsetService(deviceClock: () => device);
    final serverMillis =
        device.add(const Duration(minutes: 5)).millisecondsSinceEpoch;

    final adapter = FakeHttpAdapter(
      (options, _) => _envelope(
        {'code': ApiCodes.signatureExpired, 'message': 'expired'},
        serverTimeMillis: serverMillis,
      ),
    );

    await expectLater(
      _dioWith(clockOffset, adapter).post<dynamic>('/iap/orders', data: {'a': 1}),
      throwsA(
        isA<DioException>().having(
          (e) => e.error,
          'error',
          isA<ApiError>(),
        ),
      ),
    );
    // One original + exactly one re-sign retry; no infinite loop.
    expect(adapter.calls, 2);
  });
}
