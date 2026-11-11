import 'package:app_config/src/data/app_config_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_http_adapter.dart';

void main() {
  test('issues GET /app/config and parses the unwrapped body', () async {
    RequestOptions? captured;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/v1'))
      ..httpClientAdapter = FakeHttpAdapter((options, _) {
        captured = options;
        // The envelope interceptor (infra_core) unwraps `code:0` before the
        // repository sees it, so the body here is the inner AppConfig object.
        return jsonResponse({
          'maintenance': {
            'active': true,
            'message': 'm',
            'resume_at': 1781755280613,
          },
          'kill_switches': ['x'],
          'config': {'a': 1},
        });
      });

    final config = await AppConfigRepositoryImpl(dio).fetch();

    expect(captured!.method, 'GET');
    expect(captured!.path, '/app/config');
    expect(config.maintenance.active, isTrue);
    expect(config.killSwitches, ['x']);
    expect(config.configValue<int>('a', 0), 1);
  });

  test('a transport failure propagates (application applies fail-open)',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/v1'))
      ..httpClientAdapter = FakeHttpAdapter(
        (options, _) => throw DioException(requestOptions: options),
      );

    await expectLater(
      AppConfigRepositoryImpl(dio).fetch(),
      throwsA(isA<DioException>()),
    );
  });
}
