import Flutter
import UserNotifications

/// Local notifications for long music videos (docs/ui P24/P25; ADR-0025).
/// The app does not poll in the background: when a video is submitted, Dart
/// schedules one notification at the platform's ETA; opening it brings the
/// app to the video's progress page, which resumes polling. Nothing leaves
/// the device (no push, no APNs token).
///
/// `songlet/notifications` methods:
/// * `requestAuthorization()` → `granted` | `denied` (asks once; later calls
///   report the stored decision)
/// * `schedule({id, title, body, afterSeconds, location})` — replaces a
///   pending notification with the same id
/// * `cancel({id})`
///
/// `songlet/notifications/events` streams the `location` (an app route) of
/// every notification the user opens. A tap that launched or woke the app
/// before Dart listened is held and delivered when the stream starts.
final class NotificationService: NSObject, FlutterStreamHandler, UNUserNotificationCenterDelegate {
  static let methodChannel = "songlet/notifications"
  static let eventChannel = "songlet/notifications/events"
  static let locationKey = "location"

  private let methods: FlutterMethodChannel
  private let events: FlutterEventChannel
  private var sink: FlutterEventSink?
  private var pending: [String] = []
  private let center = UNUserNotificationCenter.current()

  init(messenger: FlutterBinaryMessenger) {
    methods = FlutterMethodChannel(name: Self.methodChannel, binaryMessenger: messenger)
    events = FlutterEventChannel(name: Self.eventChannel, binaryMessenger: messenger)
    super.init()
    center.delegate = self
    events.setStreamHandler(self)
    methods.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "requestAuthorization":
        Task { result(await self.requestAuthorization()) }
      case "schedule":
        Task {
          do {
            try await self.schedule(args)
            result(nil)
          } catch {
            result(FlutterError(code: "notification_failed", message: error.localizedDescription, details: nil))
          }
        }
      case "cancel":
        if let id = args["id"] as? String {
          self.center.removePendingNotificationRequests(withIdentifiers: [id])
          self.center.removeDeliveredNotifications(withIdentifiers: [id])
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Methods

  private func requestAuthorization() async -> String {
    let settings = await center.notificationSettings()
    switch settings.authorizationStatus {
    case .authorized, .provisional, .ephemeral:
      return "granted"
    case .denied:
      return "denied"
    default:
      let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
      return granted ? "granted" : "denied"
    }
  }

  private func schedule(_ args: [String: Any]) async throws {
    guard let id = args["id"] as? String,
          let title = args["title"] as? String,
          let body = args["body"] as? String,
          let location = args["location"] as? String
    else { throw NotificationError.badArguments }
    let seconds = max(1, (args["afterSeconds"] as? NSNumber)?.doubleValue ?? 1)
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    content.userInfo = [Self.locationKey: location]
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
    center.removePendingNotificationRequests(withIdentifiers: [id])
    try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
  }

  // MARK: - UNUserNotificationCenterDelegate

  /// In the foreground the app shows the video's state itself; the banner
  /// still appears so a video finishing while another page is open is seen.
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .list, .sound])
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if response.actionIdentifier == UNNotificationDefaultActionIdentifier,
       let location = response.notification.request.content.userInfo[Self.locationKey] as? String {
      DispatchQueue.main.async { self.deliver(location) }
    }
    completionHandler()
  }

  private func deliver(_ location: String) {
    if let sink {
      sink(location)
    } else {
      pending.append(location)
    }
  }

  // MARK: - FlutterStreamHandler

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    let held = pending
    pending.removeAll()
    for location in held { events(location) }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }
}

enum NotificationError: Error {
  case badArguments
}
