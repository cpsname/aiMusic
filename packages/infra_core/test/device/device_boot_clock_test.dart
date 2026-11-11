import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('infra_core/device');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('returns the boot instant when the host reports it', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getBootTimeMillis');
      return 1700000000000;
    });

    final boot = await const DeviceBootClock().bootTime();

    expect(boot, DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true));
  });

  test('returns null when no host handler is registered (MissingPlugin)',
      () async {
    // No mock handler → invoking the channel throws MissingPluginException.
    expect(await const DeviceBootClock().bootTime(), isNull);
  });

  test('returns null when the host reports a non-positive value', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => 0);
    expect(await const DeviceBootClock().bootTime(), isNull);
  });

  test('returns null when the host throws a PlatformException', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => throw PlatformException(code: 'boom'),
    );
    expect(await const DeviceBootClock().bootTime(), isNull);
  });
}
