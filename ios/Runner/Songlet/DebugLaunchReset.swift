#if DEBUG
import Foundation
import Security

/// Debug-only "fresh device" switch for the simulator acceptance run (PRD
/// §12.4 "新设备"): launched with `SONGLET_RESET_LOCAL=1`, the app forgets its
/// Keychain identity (a new `app_account_token`), its preferences and its local
/// library before the Flutter engine starts — the state of a newly set-up
/// iPhone. Not compiled into Release builds.
enum DebugLaunchReset {
  static func applyIfRequested() {
    guard ProcessInfo.processInfo.environment["SONGLET_RESET_LOCAL"] == "1" else { return }
    // Keychain (flutter_secure_storage: device id + device token).
    SecItemDelete([kSecClass as String: kSecClassGenericPassword] as CFDictionary)
    // Preferences (shared_preferences + App Attest key id).
    if let bundleID = Bundle.main.bundleIdentifier {
      UserDefaults.standard.removePersistentDomain(forName: bundleID)
    }
    // Local library (SQLite + audio) in Application Support.
    let fm = FileManager.default
    if let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
      try? fm.removeItem(at: support.appendingPathComponent("Library/Songlet"))
    }
    NSLog("[DebugLaunchReset] local state cleared")
  }
}
#endif
