import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // Retained so the channels keep handling calls for the app's lifetime.
  private var bootClockChannel: FlutterMethodChannel?
  private var songletApi: SongletNativeApiImpl?
  private var shareCardComposer: ShareCardComposer?
  private var speechService: SpeechService?
  private var notifications: NotificationService?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    #if DEBUG
    DebugLaunchReset.applyIfRequested()
    #endif
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // infra_core/DeviceBootClock: reports the device boot instant for reboot
    // detection (epoch millis from KERN_BOOTTIME).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DeviceBootClock") {
      let channel = FlutterMethodChannel(
        name: "infra_core/device",
        binaryMessenger: registrar.messenger())
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
    }

    // Songlet: the PRD §6.4 Pigeon bridge (StoreKit 2, App Attest, PhotosPicker,
    // playback + seek, export, SystemLanguageModel) + the share-card video encoder.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SongletNativeApi") {
      let api = SongletNativeApiImpl(messenger: registrar.messenger())
      SongletNativeApiSetup.setUp(binaryMessenger: registrar.messenger(), api: api)
      songletApi = api
      shareCardComposer = ShareCardComposer(messenger: registrar.messenger())
      // Beside the fixed Pigeon interface: on-device dictation (ADR-0006).
      // iCloud library sync (ADR-0013) is not registered: the app ships
      // without the iCloud capability, so `songlet/cloud_sync` has no handler
      // and the Dart side reads it as "unavailable".
      speechService = SpeechService(messenger: registrar.messenger())
      // Local notifications at a music video's ETA (ADR-0025). Created while
      // the app is launching, so a tap that launched the app still reaches
      // its delegate.
      notifications = NotificationService(messenger: registrar.messenger())
    }
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
