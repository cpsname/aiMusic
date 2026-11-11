import 'package:dio/dio.dart';

import '../../device/device_info_service.dart';
import '../api_headers.dart';

/// Injects the device/app meta headers (`X-Device-ID`, `X-Platform`,
/// `X-App-Version`, `X-App-Build`, `X-Os-Version`, `X-Device-Model`,
/// `X-Language`, `X-Timezone`). The profile is loaded once and cached, so this is
/// cheap after the first request.
class DeviceHeadersInterceptor extends Interceptor {
  DeviceHeadersInterceptor({
    required DeviceInfoService deviceInfoService,
    required String Function() languageTagResolver,
    String Function()? timeZoneResolver,
    Map<String, String> Function()? extraHeadersResolver,
  })  : _deviceInfoService = deviceInfoService,
        _languageTagResolver = languageTagResolver,
        _timeZoneResolver = timeZoneResolver ?? systemTimeZoneTag,
        _extraHeadersResolver = extraHeadersResolver;

  final DeviceInfoService _deviceInfoService;
  final String Function() _languageTagResolver;
  final String Function() _timeZoneResolver;

  /// App-specific request meta (e.g. Songlet's `X-Storefront` /
  /// `X-Device-Region`), resolved per request. Empty values are skipped.
  final Map<String, String> Function()? _extraHeadersResolver;

  /// Best-effort device time zone as an ISO-8601 UTC offset (e.g. `+08:00`,
  /// `+05:30`, `-03:30`). Dependency-free and unaffected by clock skew (it is the
  /// zone offset, not the wall clock). Apps needing an IANA name (e.g.
  /// `Asia/Shanghai`) can supply a `timeZoneResolver` backed by a platform
  /// time-zone plugin. [offset] defaults to the device's current offset
  /// (injectable for tests).
  static String systemTimeZoneTag([Duration? offset]) {
    final value = offset ?? DateTime.now().timeZoneOffset;
    final sign = value.isNegative ? '-' : '+';
    final hours = value.inHours.abs().toString().padLeft(2, '0');
    final minutes = (value.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '$sign$hours:$minutes';
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final profile = _deviceInfoService.cachedProfile ??
        await _deviceInfoService.load();
    options.headers[ApiHeaders.deviceId] = profile.deviceId;
    options.headers[ApiHeaders.platform] = profile.platform;
    options.headers[ApiHeaders.appVersion] = profile.appVersion;
    options.headers[ApiHeaders.appBuild] = profile.appBuild;
    options.headers[ApiHeaders.osVersion] = profile.osVersion;
    options.headers[ApiHeaders.deviceModel] = profile.deviceModel;
    options.headers[ApiHeaders.language] = _languageTagResolver();
    options.headers[ApiHeaders.timezone] = _timeZoneResolver();
    final extra = _extraHeadersResolver?.call() ?? const <String, String>{};
    for (final entry in extra.entries) {
      if (entry.value.isNotEmpty) options.headers[entry.key] = entry.value;
    }
    handler.next(options);
  }
}
