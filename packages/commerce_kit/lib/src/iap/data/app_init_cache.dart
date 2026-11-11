import 'package:infra_core/infra_core.dart';

import '../domain/iap_models.dart';
import 'iap_dtos.dart';

/// Persists the `/app/init` payload (products + legal + update) across app
/// launches and invalidates it on a **device reboot** or **app upgrade**.
///
/// The catalog + legal links change rarely, so re-fetching them on every cold
/// start is wasteful. This cache serves them within a boot session and forces a
/// refetch when the device reboots (the boot instant changes) or the app is
/// upgraded (a new build may expect a new catalog). When the boot instant is
/// undetectable (see [DeviceBootClock]) the cache never reports a hit, so the
/// app safely degrades to fetching on every launch.
class AppInitCache {
  AppInitCache({
    required KeyValueStore store,
    required DeviceBootClock bootClock,
    Duration bootTolerance = const Duration(seconds: 5),
  })  : _store = store,
        _bootClock = bootClock,
        _bootTolerance = bootTolerance;

  static const _key = 'iap.app_init.v1';

  final KeyValueStore _store;
  final DeviceBootClock _bootClock;
  final Duration _bootTolerance;

  /// The cached payload, or null if there is no valid entry for the current boot
  /// session + [appVersion] (miss / reboot / upgrade / undetectable boot).
  Future<AppInitData?> read({required String appVersion, String languageTag = ''}) async {
    final entry = _store.getJson(_cacheKey(languageTag));
    if (entry == null) return null;
    if (entry['app_version'] != appVersion) return null;

    final storedBoot = entry['boot_millis'];
    if (storedBoot is! int) return null;
    final boot = await _bootClock.bootTime();
    if (boot == null) return null; // can't prove same boot session → refetch
    final delta = (boot.millisecondsSinceEpoch - storedBoot).abs();
    if (delta > _bootTolerance.inMilliseconds) return null; // device rebooted

    final data = entry['data'];
    if (data is! Map) return null;
    return AppInitResponseDto.fromJson(Map<String, dynamic>.from(data)).toDomain();
  }

  /// Persists [data] tagged with the current boot instant + [appVersion]. No-op
  /// when the boot instant is undetectable (so [read] stays a guaranteed miss).
  Future<void> write(AppInitData data, {required String appVersion, String languageTag = ''}) async {
    final boot = await _bootClock.bootTime();
    if (boot == null) return;
    await _store.setJson(_cacheKey(languageTag), {
      'boot_millis': boot.millisecondsSinceEpoch,
      'app_version': appVersion,
      'data': appInitDataToJson(data),
    });
  }

  Future<void> clear({String languageTag = ''}) => _store.remove(_cacheKey(languageTag));

  String _cacheKey(String languageTag) => languageTag.isEmpty ? _key : '$_key.$languageTag';
}
