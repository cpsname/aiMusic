import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';

/// Records the full URI of every request.
class _Recorder implements HttpClientAdapter {
  final List<Uri> uris = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    uris.add(options.uri);
    return ResponseBody.fromString('{}', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Recorder recorder;
  late Dio dio;

  setUp(() {
    recorder = _Recorder();
    dio = Dio(BaseOptions(baseUrl: 'https://product.example/v1'))
      ..httpClientAdapter = recorder
      ..interceptors.add(EndpointRoutingInterceptor(const [
        EndpointRoute('/app/config', 'https://platform.example/v1'),
      ]));
  });

  test('a routed path goes to its host; others keep BASE_URL', () async {
    await dio.get<dynamic>('/app/config');
    await dio.post<dynamic>('/attest');
    expect(recorder.uris.map((u) => u.toString()), [
      'https://platform.example/v1/app/config',
      'https://product.example/v1/attest',
    ]);
  });

  test('prefixes match whole segments; a query string does not hide a route', () async {
    await dio.get<dynamic>('/app/configs');
    await dio.get<dynamic>('/app/config', queryParameters: {'v': 1});
    expect(recorder.uris.first.host, 'product.example');
    expect(recorder.uris.last.host, 'platform.example');
  });

  test('absolute URLs are never rerouted', () async {
    await dio.get<dynamic>('https://cdn.example/app/config/sample.mp3');
    expect(recorder.uris.single.toString(), 'https://cdn.example/app/config/sample.mp3');
  });

  test('the platform host falls back to BASE_URL when PLATFORM_BASE_URL is unset', () {
    const one = EnvConfig(
      env: AppEnv.dev,
      baseUrl: 'https://one.example/v1',
      distributionCode: 'd',
      distributionSecret: 's',
      appCode: 'a',
      bundleId: 'b',
      iapChannel: 'app_store',
    );
    expect(one.effectivePlatformBaseUrl, 'https://one.example/v1');
    const two = EnvConfig(
      env: AppEnv.dev,
      baseUrl: 'https://product.example/v1',
      platformBaseUrl: 'https://platform.example/v1',
      distributionCode: 'd',
      distributionSecret: 's',
      appCode: 'a',
      bundleId: 'b',
      iapChannel: 'app_store',
    );
    expect(two.effectivePlatformBaseUrl, 'https://platform.example/v1');
  });
}
