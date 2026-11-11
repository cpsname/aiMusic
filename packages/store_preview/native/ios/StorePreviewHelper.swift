import XCTest

/// System UI for App Store preview recordings (packages/store_preview):
/// the photo picker and the notification prompt, which an app's
/// integration_test cannot reach (they run out of process).
///
/// Copy this file into the app's UI test target (README › New app, step 5).
/// The test attaches to the app the recording already launched — it never
/// launches, terminates or reinstalls it — waits for each picker session,
/// picks photos the way a user does and confirms.
///
/// Environment (set by the recorder through `TEST_RUNNER_*`):
/// - `STORE_PREVIEW_PICKS`: the sessions in order, comma-separated, each
///   `<count>@<offset>`: tap `count` photos starting `offset` photos from the
///   newest (the picker lists newest first; the recorder empties the library,
///   then imports the storefront's photos last first). `0@0` is an off-camera
///   warm-up: close the first-run card, cancel.
/// - `STORE_PREVIEW_BUNDLE_ID`: the app under recording.
/// - `STORE_PREVIEW_ALLOW_NOTIFICATIONS=1`: after the sessions, answer the
///   app's notification prompt with Allow (writes `alert.done`).
/// - `STORE_PREVIEW_SYNC_DIR`: a host directory (the simulator shares the
///   host file system) where session `n` writes `session-<n>.done` once the
///   picker has closed; the recording waits for it.
/// Without either `STORE_PREVIEW_PICKS` or the notification flag the test is
/// skipped, so the app's other UI tests are unaffected.

final class StorePreviewHelper: XCTestCase {
  func testServe() throws {
    let env = ProcessInfo.processInfo.environment
    let plan = env["STORE_PREVIEW_PICKS"] ?? ""
    let notifications = env["STORE_PREVIEW_ALLOW_NOTIFICATIONS"] == "1"
    guard !plan.isEmpty || notifications else {
      throw XCTSkip("nothing to serve: run by store-preview recordings only")
    }
    guard let bundleId = env["STORE_PREVIEW_BUNDLE_ID"], !bundleId.isEmpty else {
      XCTFail("STORE_PREVIEW_BUNDLE_ID not set")
      return
    }
    continueAfterFailure = false
    let sessionTimeout = TimeInterval(env["STORE_PREVIEW_PICK_TIMEOUT"] ?? "") ?? 900
    guard let syncDir = env["STORE_PREVIEW_SYNC_DIR"], !syncDir.isEmpty else {
      XCTFail("STORE_PREVIEW_SYNC_DIR not set")
      return
    }
    let app = XCUIApplication(bundleIdentifier: bundleId)
    // The runner took the foreground when it started; give it back, then
    // tell the recording it may start filming.
    app.activate()
    XCTAssertTrue(app.wait(for: .runningForeground, timeout: 30), "the app did not come back to the foreground")
    try Data().write(to: URL(fileURLWithPath: syncDir).appendingPathComponent("attached"))
    for (index, session) in plan.split(separator: ",", omittingEmptySubsequences: true).enumerated() {
      let parts = session.split(separator: "@")
      guard parts.count == 2, let count = Int(parts[0]), let offset = Int(parts[1]), count >= 0, offset >= 0 else {
        XCTFail("bad STORE_PREVIEW_PICKS session \(session)")
        return
      }
      // Language-independent anchors: the grid's scroll view, and the only
      // navigation bar on screen (the app's own UI is Flutter).
      let grid = app.scrollViews["photosView_content_scroll_view"]
      XCTAssertTrue(grid.waitForExistence(timeout: sessionTimeout), "the photo picker never opened")
      let picker = app.navigationBars.firstMatch
      dismissOnboarding(in: app)
      if count == 0 {
        cancel(picker)
      } else {
        try pick(count: count, offset: offset, in: app)
        try confirm(picker, in: app)
      }
      let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: grid)
      XCTAssertEqual(XCTWaiter.wait(for: [gone], timeout: 20), .completed, "the picker did not close")
      let done = URL(fileURLWithPath: syncDir).appendingPathComponent("session-\(index).done")
      try Data().write(to: done)
    }
    if notifications {
      try allowNotifications(syncDir: syncDir, timeout: sessionTimeout)
    }
  }

  /// The app's notification prompt, answered Allow off camera as a user
  /// would, so it never covers a filmed scene. Writes `alert.done`.
  private func allowNotifications(syncDir: String, timeout: TimeInterval) throws {
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let alert = springboard.alerts.firstMatch
    XCTAssertTrue(alert.waitForExistence(timeout: timeout), "the notification prompt never appeared")
    // Don't Allow · Allow — the labels follow the device language.
    let allow = alert.buttons.element(boundBy: alert.buttons.count - 1)
    allow.tap()
    _ = alert.waitForNonExistence(timeout: 10)
    try Data().write(to: URL(fileURLWithPath: syncDir).appendingPathComponent("alert.done"))
  }

  /// The "Private Access to Photos" card shown on a device's first picker:
  /// closed once, before any recorded session needs the grid.
  private func dismissOnboarding(in app: XCUIApplication) {
    let icon = app.images["PickerOnboardingHeaderViewIcon"].firstMatch
    guard icon.exists else { return }
    // The card's first button is its close button (then "Learn More").
    let close = app.otherElements["PXGSingleViewContainerView_AX"].buttons.firstMatch
    if close.exists {
      close.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
      _ = icon.waitForNonExistence(timeout: 5)
    }
  }

  /// The leading button of the picker's bar.
  private func cancel(_ picker: XCUIElement) {
    let buttons = picker.buttons.allElementsBoundByIndex.filter { $0.exists && $0.frame.width < 80 }
    guard let cancel = buttons.min(by: { $0.frame.minX < $1.frame.minX }) else {
      XCTFail("no cancel button on the picker")
      return
    }
    cancel.tap()
  }

  /// The grid's photo frames, newest first (reading order), from one
  /// accessibility snapshot (querying each cell's frame costs a round trip).
  private func photoFrames(in app: XCUIApplication) throws -> [CGRect] {
    var frames: [CGRect] = []
    func walk(_ node: XCUIElementSnapshot) {
      if node.elementType == .image, node.identifier == "PXGGridLayout-Info" { frames.append(node.frame) }
      node.children.forEach(walk)
    }
    walk(try app.snapshot())
    return frames.sorted { abs($0.minY - $1.minY) > 1 ? $0.minY < $1.minY : $0.minX < $1.minX }
  }

  private func pick(count: Int, offset: Int, in app: XCUIApplication) throws {
    let grid = try photoFrames(in: app)
    XCTAssertGreaterThanOrEqual(grid.count, count + offset, "the library holds \(grid.count) photos, the session needs \(count + offset)")
    // The picker's cells live in another process and report themselves not
    // hittable: tap their centres in screen coordinates.
    let origin = app.coordinate(withNormalizedOffset: .zero)
    for frame in grid[offset..<(offset + count)] {
      origin.withOffset(CGVector(dx: frame.midX, dy: frame.midY)).tap()
    }
  }

  /// The confirm button: the trailing button of the picker's bar (its label
  /// follows the device language), enabled once photos are selected.
  private func confirm(_ picker: XCUIElement, in app: XCUIApplication) throws {
    let deadline = Date().addingTimeInterval(5)
    while Date() < deadline {
      let bar = try picker.snapshot()
      let trailing = bar.children
        .filter { $0.elementType == .button && $0.frame.width < 80 && $0.frame.minX > bar.frame.midX }
        .max { $0.frame.maxX < $1.frame.maxX }
      if let done = trailing, done.isEnabled {
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: done.frame.midX, dy: done.frame.midY)).tap()
        return
      }
      Thread.sleep(forTimeInterval: 0.1)
    }
    XCTFail("the picker's confirm button stayed disabled")
  }
}
