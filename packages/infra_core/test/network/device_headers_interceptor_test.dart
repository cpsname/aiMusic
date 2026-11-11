import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../support/fake_http_adapter.dart';

class _MockTokenStore extends Mock implements SecureTokenStore {}

void main() {
  test('injects all eight device/app meta headers', () async {
    final store = _MockTokenStore();
    when(() => store.readDeviceId()).thenAnswer((_) async => 'device-xyz');

    final service = DeviceInfoService(
      tokenStore: store,
      platformDetailsProbe: () async =>
          (platform: 'ios', osVersion: '17.0', model: 'iPhone15,2'),
      packageInfoProbe: () async => PackageInfo(
        appName: 'Studio',
        packageName: 'com.example.studio',
        version: '1.2.3',
        buildNumber: '42',
      ),
    );

    var language = 'en-US';
    final adapter = FakeHttpAdapter.always({'code': 0});
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        DeviceHeadersInterceptor(
          deviceInfoService: service,
          languageTagResolver: () => language,
          timeZoneResolver: () => 'Asia/Shanghai',
        ),
      );

    await dio.get<dynamic>('/x');

    final headers = adapter.requests.single.headers;
    expect(headers[ApiHeaders.deviceId], 'device-xyz');
    expect(headers[ApiHeaders.platform], 'ios');
    expect(headers[ApiHeaders.appVersion], '1.2.3');
    expect(headers[ApiHeaders.appBuild], '42');
    expect(headers[ApiHeaders.osVersion], '17.0');
    expect(headers[ApiHeaders.deviceModel], 'iPhone15,2');
    expect(headers[ApiHeaders.language], 'en-US');
    expect(headers[ApiHeaders.timezone], 'Asia/Shanghai');
    language = 'zh-Hant';
    await dio.get<dynamic>('/next');
    expect(adapter.requests.last.headers[ApiHeaders.language], 'zh-Hant');
  });

  test('default time zone is an ISO-8601 UTC offset (e.g. +08:00)', () {
    expect(
      DeviceHeadersInterceptor.systemTimeZoneTag(),
      matches(r'^[+-]\d{2}:\d{2}$'),
    );
  });

  test('systemTimeZoneTag formats offsets (sign, padding, half-hour zones)', () {
    String tag(Duration d) => DeviceHeadersInterceptor.systemTimeZoneTag(d);
    expect(tag(const Duration(hours: 8)), '+08:00');
    expect(tag(const Duration(hours: 5, minutes: 30)), '+05:30'); // India
    expect(tag(const Duration(hours: 5, minutes: 45)), '+05:45'); // Nepal
    expect(tag(const Duration(hours: -8)), '-08:00'); // PST
    expect(tag(const Duration(hours: -3, minutes: -30)), '-03:30'); // NL
    expect(tag(Duration.zero), '+00:00'); // UTC
  });

  test('adds app-specific meta headers per request, skipping empty values', () async {
    final store = _MockTokenStore();
    when(() => store.readDeviceId()).thenAnswer((_) async => 'device-xyz');
    final service = DeviceInfoService(
      tokenStore: store,
      platformDetailsProbe: () async =>
          (platform: 'ios', osVersion: '26.5', model: 'iPhone18,1'),
      packageInfoProbe: () async => PackageInfo(
        appName: 'Songlet',
        packageName: 'com.songlet.ios',
        version: '1.0.0',
        buildNumber: '1',
      ),
    );
    var storefront = '';
    final adapter = FakeHttpAdapter.always({'code': 0});
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        DeviceHeadersInterceptor(
          deviceInfoService: service,
          languageTagResolver: () => 'en-US',
          extraHeadersResolver: () => {
            'X-Storefront': storefront,
            'X-Device-Region': 'US',
          },
        ),
      );

    await dio.get<dynamic>('/a');
    storefront = 'USA'; // resolved again on the next request
    await dio.get<dynamic>('/b');

    expect(adapter.requests[0].headers.containsKey('X-Storefront'), isFalse);
    expect(adapter.requests[0].headers['X-Device-Region'], 'US');
    expect(adapter.requests[1].headers['X-Storefront'], 'USA');
  });
}
