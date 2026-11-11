import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

/// Detects device reboots via the system boot instant.
///
/// The wall-clock time the device last booted is stable within a boot session
/// and changes across reboots, so a changed boot instant (beyond a few seconds
/// of clock jitter) means the device was restarted. Backed by a host
/// [MethodChannel] (`infra_core/device` → `getBootTimeMillis`): iOS/macOS read
/// `sysctl KERN_BOOTTIME`, Android `currentTimeMillis - elapsedRealtime`.
///
/// Returns `null` when the host handler isn't registered or the platform can't
/// report it (e.g. web, or a desktop host without the handler). Callers treat
/// `null` as "unknown" — typically "don't trust a reboot-scoped cache, refetch"
/// — so the app degrades to its pre-cache behaviour rather than serving stale
/// data.
@immutable
class DeviceBootClock {
  const DeviceBootClock([
    this._channel = const MethodChannel('infra_core/device'),
  ]);

  final MethodChannel _channel;

  /// The wall-clock instant the device last booted, or `null` if undetectable.
  Future<DateTime?> bootTime() async {
    try {
      final millis = await _channel.invokeMethod<int>('getBootTimeMillis');
      if (millis == null || millis <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    } on MissingPluginException {
      return null; // host handler not registered (e.g. unsupported platform)
    } on PlatformException {
      return null; // host failed to read the boot time
    }
  }
}
