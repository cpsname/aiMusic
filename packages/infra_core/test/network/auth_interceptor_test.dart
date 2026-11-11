import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';

import '../support/fake_http_adapter.dart';

class _FakeGateway implements AuthGateway {
  _FakeGateway({this.token, this.refreshSucceeds = true});

  String? token;
  bool refreshSucceeds;
  int refreshCount = 0;
  int logoutCount = 0;

  @override
  String? get accessToken => token;

  @override
  Future<bool> refresh() async {
    refreshCount += 1;
    if (refreshSucceeds) {
      token = 'new-token';
      return true;
    }
    return false;
  }

  @override
  Future<void> forceLogout() async {
    logoutCount += 1;
    token = null;
  }
}

Dio _authDio(FakeHttpAdapter adapter) => Dio(BaseOptions(baseUrl: 'https://api.test'))
  ..httpClientAdapter = adapter
  ..interceptors.add(const EnvelopeInterceptor());

Dio _apiDio(FakeHttpAdapter adapter, _FakeGateway gateway, Dio authDio) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = adapter
    ..interceptors.add(AuthInterceptor(gateway: gateway, authDio: authDio))
    ..interceptors.add(const EnvelopeInterceptor());
  return dio;
}

void main() {
  test('injects the bearer token when authenticated', () async {
    final gateway = _FakeGateway(token: 'tok');
    final adapter = FakeHttpAdapter.always({'code': 0, 'data': 'ok'});
    final dio = _apiDio(
      adapter,
      gateway,
      _authDio(FakeHttpAdapter.always({'code': 0})),
    );

    await dio.get<dynamic>('/me');

    expect(adapter.requests.single.headers[ApiHeaders.authorization],
        'Bearer tok');
  });

  test('40102 on HTTP 200 → refresh once and replay with the new token',
      () async {
    final gateway = _FakeGateway(token: 'old');
    final replayAdapter = FakeHttpAdapter.always({
      'code': 0,
      'data': {'ok': true},
    });
    final apiAdapter =
        FakeHttpAdapter.always({'code': 40102, 'message': 'expired'});
    final dio = _apiDio(apiAdapter, gateway, _authDio(replayAdapter));

    final response = await dio.get<dynamic>('/me');

    expect(gateway.refreshCount, 1);
    expect(response.data, {'ok': true});
    expect(replayAdapter.requests.single.headers[ApiHeaders.authorization],
        'Bearer new-token');
  });

  test('40102 delivered as HTTP 401 is also refreshed and replayed', () async {
    final gateway = _FakeGateway(token: 'old');
    final replayAdapter = FakeHttpAdapter.always({
      'code': 0,
      'data': {'ok': true},
    });
    final apiAdapter =
        FakeHttpAdapter.always({'code': 40102}, statusCode: 401);
    final dio = _apiDio(apiAdapter, gateway, _authDio(replayAdapter));

    final response = await dio.get<dynamic>('/me');

    expect(gateway.refreshCount, 1);
    expect(response.data, {'ok': true});
  });

  test('40106 forces logout, does not refresh, and surfaces an auth error',
      () async {
    final gateway = _FakeGateway(token: 'tok');
    final apiAdapter =
        FakeHttpAdapter.always({'code': 40106, 'message': 'reused'});
    final dio = _apiDio(apiAdapter, gateway, _authDio(FakeHttpAdapter.always({})));

    await expectLater(
      dio.get<dynamic>('/me'),
      throwsA(
        predicate<DioException>(
          (e) =>
              e.error is AuthApiError &&
              (e.error! as AuthApiError).requiresForceLogout,
        ),
      ),
    );
    expect(gateway.logoutCount, 1);
    expect(gateway.refreshCount, 0);
  });

  test('a failed refresh forces logout and rejects', () async {
    final gateway = _FakeGateway(token: 'old', refreshSucceeds: false);
    final apiAdapter = FakeHttpAdapter.always({'code': 40102});
    final dio = _apiDio(apiAdapter, gateway, _authDio(FakeHttpAdapter.always({})));

    await expectLater(dio.get<dynamic>('/me'), throwsA(isA<DioException>()));
    expect(gateway.refreshCount, 1);
    expect(gateway.logoutCount, 1);
  });
}
