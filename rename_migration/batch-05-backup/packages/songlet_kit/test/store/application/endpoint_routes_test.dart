import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet_kit/songlet_kit.dart';

EnvConfig _env({String platform = ''}) => EnvConfig(
      env: AppEnv.dev,
      baseUrl: 'https://genaistudio-products.showsapp.org/v1',
      platformBaseUrl: platform,
      distributionCode: 'songlet.ios',
      distributionSecret: 's',
      appCode: 'songlet',
      bundleId: 'com.songlet.ios',
      iapChannel: 'app_store',
    );

void main() {
  List<EndpointRoute> routes(EnvConfig env) {
    final container = ProviderContainer(overrides: [...songletKitOverrides(), envConfigProvider.overrideWithValue(env)]);
    addTearDown(container.dispose);
    return container.read(endpointRoutesProvider);
  }

  String hostFor(List<EndpointRoute> table, String path, String fallback) =>
      table.where((r) => r.claims(path)).firstOrNull?.baseUrl ?? fallback;

  test('/app/config goes to the platform; every other endpoint stays on the product backend', () {
    const product = 'https://genaistudio-products.showsapp.org/v1';
    const platform = 'https://genaistudio.showsapp.org/v1';
    final table = routes(_env(platform: platform));
    expect(hostFor(table, '/app/config', product), platform);
    for (final path in ['/attest', '/templates', '/generate', '/jobs/j1', '/entitlements/sync', '/mv/estimate', '/uploads/sign']) {
      expect(hostFor(table, path, product), product, reason: path);
    }
  });

  test('without PLATFORM_BASE_URL everything stays on BASE_URL', () {
    expect(routes(_env()).map((r) => r.baseUrl).toSet(), {'https://genaistudio-products.showsapp.org/v1'});
  });
}
