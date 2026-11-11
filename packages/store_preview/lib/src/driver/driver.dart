import '../config/app.dart';
import '../config/defaults.dart';
import '../plan/plan.dart';
import 'take.dart';

/// What a driver needs once per run.
class DriverContext {
  const DriverContext({required this.root, required this.buildDir, required this.slots});

  /// The app repo's root.
  final String root;

  /// `build/store_preview/<app>`.
  final String buildDir;

  /// The slots this run records (the driver refuses one the app does not
  /// ship for).
  final List<DeviceSlot> slots;
}

/// A device the take runs on.
class DeviceTarget {
  const DeviceTarget({required this.udid, required this.slot});

  final String udid;
  final DeviceSlot slot;
}

/// Drives an app through a recording plan on a simulator.
///
/// The first implementation is [FlutterIntegrationTestDriver]
/// (driver/flutter_driver.dart); another (a native XCUITest driver, …)
/// implements the same two calls and post-production does not change.
abstract interface class AppDriver {
  /// Once per run, before any take: build what the takes need (the
  /// system-UI helper, …), check the app ships for every slot.
  Future<void> prepare(DriverContext context);

  /// Starts the app on [device] (prepared for [storefront] — language,
  /// region, photo library — by the simulator controller) and returns the
  /// session that runs [plan].
  Future<DriverSession> launch({
    required DeviceTarget device,
    required Storefront storefront,
    required RecordingPlan plan,
    required TakeFiles files,
  });
}

/// One run of a plan.
abstract interface class DriverSession {
  /// Waits until the app is up and the prelude ran (the `ready` mark).
  Future<void> waitStable();

  /// Runs the plan to its `done` mark; throws on a `failed` mark, a crash or
  /// the timeout. Returns every mark.
  Future<List<SceneMark>> run();

  /// Stops whatever the session still runs (the helper).
  Future<void> close();
}
