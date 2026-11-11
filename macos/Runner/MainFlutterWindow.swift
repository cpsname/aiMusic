import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  // Retained so the channel keeps handling calls for the app's lifetime.
  private var bootClockChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // infra_core/DeviceBootClock: reports the device boot instant for reboot
    // detection (epoch millis from KERN_BOOTTIME).
    let channel = FlutterMethodChannel(
      name: "infra_core/device",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { call, result in
      if call.method == "getBootTimeMillis" {
        if let millis = deviceBootTimeMillis() {
          result(millis)
        } else {
          result(nil)
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    bootClockChannel = channel

    super.awakeFromNib()
  }
}

/// Wall-clock instant the device last booted, in epoch milliseconds, from
/// `sysctl KERN_BOOTTIME`. Returns nil if the syscall fails.
private func deviceBootTimeMillis() -> Int? {
  var mib = [CTL_KERN, KERN_BOOTTIME]
  var bootTime = timeval()
  var size = MemoryLayout<timeval>.stride
  guard sysctl(&mib, 2, &bootTime, &size, nil, 0) == 0 else { return nil }
  return Int(bootTime.tv_sec) * 1000 + Int(bootTime.tv_usec) / 1000
}
