import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';

void main() {
  group('ClockOffsetService', () {
    test('before any sync: offset zero, now() == device now', () {
      final device = DateTime.utc(2026, 6, 1, 10);
      final svc = ClockOffsetService(deviceClock: () => device);
      expect(svc.hasOffset, isFalse);
      expect(svc.offset, Duration.zero);
      expect(svc.now(), device);
    });

    test('syncFromRoundTrip applies the server offset with RTT/2 compensation',
        () {
      final device = DateTime.utc(2026, 6, 1, 10);
      final svc = ClockOffsetService(deviceClock: () => device);

      // Sent at 10:00:00.000, received at 10:00:00.400 (rtt 400ms);
      // server stamped 10:05:00.200 — i.e. 5 min ahead, at the round-trip midpoint.
      svc.syncFromRoundTrip(
        serverEpochMillis:
            DateTime.utc(2026, 6, 1, 10, 5, 0, 200).millisecondsSinceEpoch,
        sentAt: DateTime.utc(2026, 6, 1, 10),
        receivedAt: DateTime.utc(2026, 6, 1, 10, 0, 0, 400),
      );

      expect(svc.hasOffset, isTrue);
      // midpoint = 10:00:00.200; offset = server − midpoint = exactly 5 minutes.
      expect(svc.offset, const Duration(minutes: 5));
      // now() corrects the device clock by the learned offset.
      expect(svc.now(), DateTime.utc(2026, 6, 1, 10, 5));
    });

    test('a behind-server clock yields a negative offset', () {
      final device = DateTime.utc(2026, 6, 1, 10);
      final svc = ClockOffsetService(deviceClock: () => device);
      svc.syncFromRoundTrip(
        serverEpochMillis:
            device.subtract(const Duration(minutes: 3)).millisecondsSinceEpoch,
        sentAt: device,
        receivedAt: device,
      );
      expect(svc.offset, const Duration(minutes: -3));
      expect(svc.now(), device.subtract(const Duration(minutes: 3)));
    });

    test('a later sync slides the offset to the newest observation', () {
      final device = DateTime.utc(2026, 6, 1, 10);
      final svc = ClockOffsetService(deviceClock: () => device);
      svc.syncFromRoundTrip(
        serverEpochMillis:
            device.add(const Duration(minutes: 5)).millisecondsSinceEpoch,
        sentAt: device,
        receivedAt: device,
      );
      expect(svc.offset, const Duration(minutes: 5));
      svc.syncFromRoundTrip(
        serverEpochMillis:
            device.subtract(const Duration(minutes: 2)).millisecondsSinceEpoch,
        sentAt: device,
        receivedAt: device,
      );
      expect(svc.offset, const Duration(minutes: -2));
    });
  });
}
