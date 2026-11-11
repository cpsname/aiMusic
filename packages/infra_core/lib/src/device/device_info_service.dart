import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:meta/meta.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../storage/secure_token_store.dart';

/// Stable device + app identity sent on every request as `X-*` headers.
@immutable
class DeviceProfile {
  const DeviceProfile({
    required this.deviceId,
    required this.platform,
    required this.osVersion,
    required this.deviceModel,
    required this.appVersion,
    required this.appBuild,
  });

  final String deviceId;
  final String platform; // ios / android / macos / web / windows / linux
  final String osVersion;
  final String deviceModel;
  final String appVersion;
  final String appBuild;
}

/// Low-level platform facts (OS version + model) — injectable for tests.
typedef PlatformDetailsProbe = Future<({String platform, String osVersion, String model})>
    Function();

/// Resolves and caches a [DeviceProfile]. The device id is a UUID generated
/// once and persisted to the Keychain via [SecureTokenStore], so it survives
/// reinstalls and anchors guest-register idempotency.
class DeviceInfoService {
  DeviceInfoService({
    required SecureTokenStore tokenStore,
    Uuid uuid = const Uuid(),
    PlatformDetailsProbe? platformDetailsProbe,
    Future<PackageInfo> Function()? packageInfoProbe,
  })  : _tokenStore = tokenStore,
        _uuid = uuid,
        _platformDetailsProbe = platformDetailsProbe ?? _defaultPlatformDetails,
        _packageInfoProbe = packageInfoProbe ?? PackageInfo.fromPlatform;

  final SecureTokenStore _tokenStore;
  final Uuid _uuid;
  final PlatformDetailsProbe _platformDetailsProbe;
  final Future<PackageInfo> Function() _packageInfoProbe;

  DeviceProfile? _cached;

  /// The already-resolved profile, or null before the first [load].
  DeviceProfile? get cachedProfile => _cached;

  /// Drops the cached profile so the next [load] re-resolves the identity.
  ///
  /// Needed after account deletion (the Keychain device id was destroyed):
  /// without this, the cached profile keeps serving the dead id to the
  /// device-headers interceptor and to guest-register, silently resurrecting
  /// the deleted account.
  void reset() => _cached = null;

  Future<DeviceProfile> load() async {
    final cached = _cached;
    if (cached != null) return cached;

    final deviceId = await _ensureDeviceId();
    final details = await _platformDetailsProbe();
    final pkg = await _packageInfoProbe();

    final profile = DeviceProfile(
      deviceId: deviceId,
      platform: details.platform,
      osVersion: details.osVersion,
      deviceModel: details.model,
      appVersion: pkg.version,
      appBuild: pkg.buildNumber,
    );
    _cached = profile;
    return profile;
  }

  Future<String> _ensureDeviceId() async {
    final existing = await _tokenStore.readDeviceId();
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = _uuid.v4();
    await _tokenStore.writeDeviceId(generated);
    return generated;
  }

  static Future<({String platform, String osVersion, String model})>
      _defaultPlatformDetails() async {
    final plugin = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      return (
        platform: 'ios',
        osVersion: info.systemVersion,
        model: info.utsname.machine,
      );
    }
    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      return (
        platform: 'android',
        osVersion: info.version.release,
        model: info.model,
      );
    }
    if (Platform.isMacOS) {
      final info = await plugin.macOsInfo;
      return (
        platform: 'macos',
        osVersion: info.osRelease,
        model: info.model,
      );
    }
    return (
      platform: Platform.operatingSystem,
      osVersion: Platform.operatingSystemVersion,
      model: 'unknown',
    );
  }
}
