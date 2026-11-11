import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _MockTokenStore extends Mock implements SecureTokenStore {}

DeviceInfoService _service(SecureTokenStore store) => DeviceInfoService(
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

void main() {
  setUpAll(() {
    registerFallbackValue('');
  });

  test('generates and persists a device id when none exists', () async {
    final store = _MockTokenStore();
    when(() => store.readDeviceId()).thenAnswer((_) async => null);
    when(() => store.writeDeviceId(any())).thenAnswer((_) async {});

    final profile = await _service(store).load();

    expect(profile.deviceId, isNotEmpty);
    expect(profile.platform, 'ios');
    expect(profile.osVersion, '17.0');
    expect(profile.appVersion, '1.2.3');
    expect(profile.appBuild, '42');
    verify(() => store.writeDeviceId(profile.deviceId)).called(1);
  });

  test('reuses a persisted device id without rewriting', () async {
    final store = _MockTokenStore();
    when(() => store.readDeviceId()).thenAnswer((_) async => 'existing-id');

    final profile = await _service(store).load();

    expect(profile.deviceId, 'existing-id');
    verifyNever(() => store.writeDeviceId(any()));
  });

  test('caches the profile after the first load', () async {
    final store = _MockTokenStore();
    when(() => store.readDeviceId()).thenAnswer((_) async => 'existing-id');
    final service = _service(store);

    final first = await service.load();
    final second = await service.load();

    expect(identical(first, second), isTrue);
    expect(service.cachedProfile, same(first));
    verify(() => store.readDeviceId()).called(1);
  });

  test('reset drops the cache so the next load re-resolves the identity',
      () async {
    // The account-deletion path: the Keychain id was destroyed; without the
    // reset, the cached profile would keep serving the dead id.
    final store = _MockTokenStore();
    when(() => store.readDeviceId()).thenAnswer((_) async => 'existing-id');
    when(() => store.writeDeviceId(any())).thenAnswer((_) async {});
    final service = _service(store);
    await service.load();

    service.reset();
    expect(service.cachedProfile, isNull);

    when(() => store.readDeviceId()).thenAnswer((_) async => null);
    final fresh = await service.load();

    expect(fresh.deviceId, isNotEmpty);
    expect(fresh.deviceId, isNot('existing-id'));
    verify(() => store.writeDeviceId(fresh.deviceId)).called(1);
  });
}
