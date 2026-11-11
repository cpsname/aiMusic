import XCTest

/// Songlet acceptance run on the simulator (PRD §13.2 completion criteria +
/// §12.4 commercial cases), driving the real app against the dev mock backend
/// (`mock_server/`, http://localhost:8787).
///
/// StoreKit: this toolchain's simulator refuses StoreKit Testing for apps not
/// launched by an Xcode debug session (`storekitd`: "not installed for
/// development"), so a headless run cannot complete the native purchase sheet.
/// Purchases are therefore applied on the server side (`/__admin/grant`, the
/// equivalent of App Store Server Notifications V2 SUBSCRIBED /
/// ONE_TIME_CHARGE), after asserting the paywall was presented; everything
/// downstream — entitlement sync, the paywalled full song, download gating,
/// refund lock, lapse — runs through the real app. The on-device purchase +
/// `currentEntitlements` restore are covered by the manual StoreKit checklist
/// (docs/songlet/acceptance.md).
///
/// Run: start the mock (`make mock`), then `make acceptance`.
final class SongletAcceptanceTests: XCTestCase {
  private var app: XCUIApplication!
  private let admin = MockAdmin(base: URL(string: "http://localhost:8787/__admin")!)

  override func setUpWithError() throws {
    continueAfterFailure = false
    try admin.post("reset")
    try admin.post("config", ["clip_delay_ms": 8000, "song_delay_ms": 12000])
    app = XCUIApplication()
  }

  override func tearDownWithError() throws {
    app?.terminate()
  }

  // MARK: - Completion criteria (PRD §13.2)

  /// Open → Birthday Wish template → name + keywords → 30 s clip → playing,
  /// within 90 s. Then the first-session paywall appears after the first
  /// finished listen (PRD §8.2), not at launch.
  func test01_firstSessionClipPlaysWithin90Seconds() throws {
    let started = Date()
    launch(freshDevice: true)
    XCTAssertFalse(element("paywall.close").exists, "no paywall at launch (PRD §8.2)")
    makeClip(name: "Alex", keywords: ["coffee", "hiking", "Sunday"])
    let elapsed = Date().timeIntervalSince(started)
    XCTAssertTrue(isPlaying())
    XCTAssertLessThan(elapsed, 90, "open → first listen took \(Int(elapsed)) s")
    let timing = XCTAttachment(string: "open → first listen: \(String(format: "%.1f", elapsed)) s")
    timing.name = "open-to-first-listen"
    timing.lifetime = .keepAlways
    add(timing)
    print("SONGLET open → first listen: \(String(format: "%.1f", elapsed)) s")

    // The 30 s preview ends → the paywall is offered once.
    expectExists(element("paywall.close"), timeout: 45, "paywall after the first listen")
    element("paywall.close").tap()
  }

  /// Pro purchase → full song → MP3 + lyrics + license saved to Files — and
  /// PRD §12.4 case 1: 40/100 → one song → 39/100 → renewal cancelled →
  /// period over → allowance zero, the song still plays.
  func test02_proPurchaseFullSongExportAndLapse() throws {
    launch(freshDevice: true)
    makeClip(name: "Alex", keywords: ["coffee", "hiking", "Sunday"])
    pause() // stop before the first-listen paywall

    tapRevealed("player.fullSong")
    buy(product: "com.songlet.pro.monthly")
    // After the purchase the flow continues straight into the full song.
    waitForFullSong()

    let account = try admin.account()
    XCTAssertEqual(account.tier, "pro")
    XCTAssertEqual(account.songsLeft, 39, "40 songs − 1 (PRD §12.4 case 1)")

    // Download page (P11): the whole bundle into a Files folder.
    pause()
    tapRevealed("player.download")
    expectExists(element("download.mp3"), timeout: 10, "download page (P11)")
    tapRevealed("download.files")
    saveInFilesPicker(confirmation: "Saved to Files.")
    tapRevealed("download.done")

    openSettings()
    expectExists(label("39 full songs left"), timeout: 20, "Pro allowance after one song")
    XCTAssertTrue(label("100 previews left").exists, "the preview came from the free allowance")

    // Cancel renewal and let the period end (S2S EXPIRED + server clock).
    try admin.post("advance_clock", ["days": 32])
    try admin.post("notify", ["notification_type": "EXPIRED", "original_transaction_id": try admin.firstTransactionId()])
    relaunch()
    openSettings()
    expectExists(label("Free"), timeout: 30, "tier back to Free")
    XCTAssertTrue(label("0 full songs left").exists)
    assertLibrarySongStillPlays()
  }

  // MARK: - PRD §12.4 commercial cases

  /// Case 2: a 10-song pack → a failed generation is refunded → still 10;
  /// the pack does not reset at the month boundary.
  func test03_packRefundedOnFailureNeverExpires() throws {
    launch(freshDevice: true)
    makeClip(name: "Sam", keywords: ["sunset", "road trip", "guitar"])
    pause()
    try admin.post("fail_next", ["error_code": "UPSTREAM_TIMEOUT"])
    tapRevealed("player.fullSong")
    buy(product: "com.songlet.pack.10")
    expectExists(element("generating.failure"), timeout: 90, "failure state")
    expectExists(label(upstreamTimeoutCopy), timeout: 5, "UPSTREAM_TIMEOUT copy (PRD §6.5)")
    XCTAssertEqual(try admin.account().songsLeft, 10, "failed job refunded")

    try admin.post("advance_clock", ["days": 31])
    relaunch()
    openSettings()
    expectExists(label("10 full songs left"), timeout: 30, "pack allowance kept")
    XCTAssertEqual(try admin.account().songsLeft, 10, "packs never expire")
  }

  /// Case 3: a refunded purchase freezes its allowance; its song stays
  /// playable but can no longer be downloaded.
  func test04_refundLocksDownloadKeepsPlayback() throws {
    launch(freshDevice: true)
    makeClip(name: "Mia", keywords: ["rain", "jazz", "cats"])
    pause()
    tapRevealed("player.fullSong")
    buy(product: "com.songlet.pack.10")
    waitForFullSong()
    XCTAssertEqual(try admin.account().songsLeft, 9)

    // StoreKit refund (→ Transaction.updates, revoked JWS) + the App Store
    // Server Notification V2 the backend would receive.
    try admin.post("notify", ["notification_type": "REFUND", "transaction_id": try admin.firstTransactionId()])
    relaunch()
    assertLibrarySongStillPlays(fullSong: true)
    pause()
    tapRevealed("player.download")
    expectExists(element("download.locked"), timeout: 20, "DOWNLOAD_LOCKED after refund")
    XCTAssertTrue(label("Downloads aren't available for this song").exists)
    XCTAssertEqual(try admin.account().songsLeft, 0, "refunded pack credits frozen")
  }

  /// Case 4: a new device restores tier and remaining allowance from
  /// `Transaction.currentEntitlements`. Needs a StoreKit environment (the
  /// signed transactions are what link the new device's token to the buyer),
  /// so it runs from Xcode with `Songlet.storekit` — see
  /// docs/songlet/acceptance.md; the ledger half is covered by the mock's
  /// restore-link tests.
  func test05_restoreOnNewDevice() throws {
    throw XCTSkip("requires a StoreKit environment (Xcode run with Songlet.storekit or a sandbox device)")
  }

  /// Case 5 (as amended by ADR-0005): the client never blocks by region —
  /// every template stays open on a device in an unsupported region. When the
  /// server still refuses (REGION_UNAVAILABLE) the user sees the transient
  /// UPSTREAM_TIMEOUT copy, and the library keeps working.
  func test06_regionRejectedByServerLibraryWorks() throws {
    launch(freshDevice: true, extraArguments: ["-AppleLanguages", "(en-RU)", "-AppleLocale", "en_RU"])
    openTemplate()
    expectExists(element("composer.name"), timeout: 10, "the composer unfolds: no client-side region gate")
    fillForm(name: "Ivan", keywords: ["snow", "tea", "books"])
    tapRevealed("composer.create")
    expectExists(element("generating.failure"), timeout: 60, "server REGION_UNAVAILABLE")
    XCTAssertTrue(label(upstreamTimeoutCopy).exists, "REGION_UNAVAILABLE presents as UPSTREAM_TIMEOUT")
    openTab("library")
    expectExists(label("Library"), timeout: 10, "library still available")
  }

  /// PRD F08 + F04: the 9:16 share card is composed and handed to the system
  /// share sheet; a song is made from photos picked with PhotosPicker.
  func test08_shareCardAndPhotoSong() throws {
    launch(freshDevice: true)
    makeClip(name: "Alex", keywords: ["coffee", "hiking", "Sunday"])
    pause()

    // Share card (P10) → system share sheet.
    tapRevealed("player.share")
    expectExists(element("share.card"), timeout: 10, "share card page")
    tapRevealed("share.send")
    let sheet = app.otherElements["ActivityListView"]
    expectExists(sheet, timeout: 60, "share sheet with the composed card video")
    snap("share-sheet")
    if app.buttons["Close"].exists { app.buttons["Close"].tap() } else { sheet.swipeDown(velocity: .fast) }

    // Composer "+" → photos (P04) → song. Photos are free input (ADR-0033):
    // the picked card is left first.
    openTab("create")
    let unpick = app.buttons["Remove Birthday Wish"]
    if unpick.waitForExistence(timeout: 5) { unpick.tap() }
    let addPhotos = app.buttons.matching(NSPredicate(format: "label == 'Add photos'")).firstMatch
    expectExists(addPhotos, timeout: 10, "composer add-photos button")
    addPhotos.tap()
    // An empty photos page (P04) opens PhotosPicker straight away.
    let photo = app.images.matching(NSPredicate(format: "label BEGINSWITH 'Photo'")).firstMatch
    expectExists(photo, timeout: 20, "PhotosPicker grid")
    // The picker's cells are hosted out of process and report "not hittable";
    // tap their centre by coordinate.
    photo.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    snap("photos-picker")
    let add = app.buttons["Add"]
    if add.waitForExistence(timeout: 5) { add.tap() }
    expectExists(label("1 / 10"), timeout: 20, "one compressed photo in the draft")
    snap("photos-page")
    tapRevealed("photos.create")
    waitForPlayer(timeout: 90)
    snap("photo-song")
  }

  /// Not an acceptance criterion: captures every screen of the flow (kept as
  /// attachments) for design review and store screenshots.
  /// Music video (PRD ch.15; docs/ui P19 → P20 → P22 → P24 → P26): a
  /// chorus video refused for credits opens the credits sheet; the pack lands
  /// on the server (see the class note), Continue sends the same request
  /// (same `client_ref`), and the video is made and charged once.
  func test09_mvQuotaPurchaseRetry() throws {
    try admin.post("config", ["clip_delay_ms": 4000, "song_delay_ms": 6000, "mv_delay_ms": 8000])
    launch(freshDevice: true)
    makeClip(name: "Alex", keywords: ["coffee", "hiking"])
    pause()
    tapRevealed("player.fullSong")
    buy(product: "com.songlet.pro.monthly")
    waitForFullSong()
    pause()

    tapRevealed("mv.entry.open")
    expectExists(element("mv.level.chorus_mv"), timeout: 20, "video hub (P20)")
    expectExists(label("2103 more needed"), timeout: 20, "the chorus level priced with its gap")
    element("mv.level.chorus_mv").tap()
    tapRevealed("mv.create")
    expectExists(element("mv.quota.buy"), timeout: 20, "credits sheet (P22)")
    XCTAssertTrue(element("mv.quota.pack").exists, "the recommended pack")
    element("mv.quota.close").tap()

    XCTAssertNoThrow(try admin.post("grant", ["product_id": "com.songlet.mv.chorus"]))
    for _ in 0..<6 where !element("mv.intent").exists { app.swipeDown(velocity: .fast) }
    expectExists(element("mv.intent"), timeout: 10, "the video waits for credits")
    label("Continue").tap()
    expectExists(element("mv.progressTitle"), timeout: 20, "progress (P24)")
    expectExists(element("mv.player"), timeout: 90, "the video (P26)")
    XCTAssertEqual(try admin.account().credits, 66 + 2395 - 2169, "charged once")
  }

  func test07_screenshotTour() throws {
    launch(freshDevice: true)
    snap("01-create")
    // The selectors sit under the summary row (ADR-0033 state C).
    element("composer.summary").tap()
    expectExists(element("composer.genre"), timeout: 10, "the composer's options")
    element("composer.genre").tap()
    Thread.sleep(forTimeInterval: 1)
    snap("02-genre-panel")
    app.tap() // dismiss the panel
    openTemplate()
    fillForm(name: "Alex", keywords: ["coffee", "hiking", "Sunday"])
    snap("03-picked")
    tapRevealed("composer.create")
    expectExists(element("generating.progress"), timeout: 20, "generating")
    snap("04-generating")
    waitForPlayer(timeout: 80)
    Thread.sleep(forTimeInterval: 4)
    snap("05-preview")
    pause()
    tapRevealed("player.fullSong")
    expectExists(element("paywall.close"), timeout: 20, "paywall")
    snap("06-paywall")
    element("paywall.close").tap()
    openTab("library")
    snap("07-library")
    openTab("settings")
    Thread.sleep(forTimeInterval: 2)
    snap("08-settings")
  }

  private func snap(_ name: String) {
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = name
    shot.lifetime = .keepAlways
    add(shot)
  }

  // MARK: - Flow helpers

  private let upstreamTimeoutCopy = "Taking longer than usual. We'll keep trying and notify you."
  private let clipTemplate = "tile.birthday_wish"

  /// [freshDevice] = a new iPhone (new Keychain identity, empty library).
  private func launch(freshDevice: Bool = false, extraArguments: [String] = []) {
    app.launchEnvironment["SONGLET_RESET_LOCAL"] = freshDevice ? "1" : "0"
    app.launchArguments = extraArguments
    app.launch()
    expectExists(element(clipTemplate), timeout: 30, "create screen")
  }

  private func relaunch(newDevice: Bool = false) {
    app.terminate()
    launch(freshDevice: newDevice, extraArguments: app.launchArguments)
  }

  /// Picks the Birthday Wish tile (ADR-0032, ADR-0033): the composer shows
  /// the card's fields in place of the prompt; a pick starts at the 30 s
  /// preview (ADR-0036).
  private func openTemplate() {
    let tile = element(clipTemplate)
    expectExists(tile, timeout: 10, "template tile")
    tile.tap()
    expectExists(element("composer.name"), timeout: 10, "the composer's fields")
  }

  /// Name + keyword chips in the unfolded composer (Return commits a chip).
  private func fillForm(name: String, keywords: [String]) {
    let nameField = field(in: "composer.name")
    nameField.tap()
    nameField.typeText(name)
    for word in keywords {
      let keywordField = field(in: "composer.keywords")
      keywordField.tap()
      keywordField.typeText(word + "\n")
    }
  }

  /// Birthday Wish → name + keywords → 30 s preview playing (P07).
  private func makeClip(name: String, keywords: [String]) {
    openTemplate()
    fillForm(name: name, keywords: keywords)
    tapRevealed("composer.create")
    waitForPlayer(timeout: 80)
  }

  /// Generation of the ≈2 min song, then its player page (P09).
  private func waitForFullSong() {
    expectExists(element("generating.progress"), timeout: 30, "full song generating")
    expectExists(element("player.download"), timeout: 90, "full song ready")
    waitForPlayer(timeout: 10)
  }

  /// The play/pause disc. Flutter exposes it beside (not under) the
  /// `player.toggle` container; its label is the action it performs, so
  /// "Pause" means the song is playing.
  private func transport(_ action: String) -> XCUIElement {
    app.buttons.matching(NSPredicate(format: "label == %@", action)).firstMatch
  }

  private func isPlaying() -> Bool { transport("Pause").exists }

  private func pause() {
    if transport("Pause").exists { transport("Pause").tap() }
  }

  private func waitForPlayer(timeout: TimeInterval) {
    expectExists(element("player.toggle"), timeout: timeout, "player shown")
    expectExists(transport("Pause"), timeout: 15, "playback started")
  }

  /// Scrolls down until [target] is built (lazy lists build on demand).
  private func scrollUntilExists(_ target: XCUIElement, _ message: String) {
    for _ in 0..<8 where !target.exists { app.swipeUp(velocity: .slow) }
    expectExists(target, timeout: 2, message)
  }

  /// Taps [id], scrolling the page until it is on screen (Flutter reports
  /// off-screen list items with an empty frame).
  private func tapRevealed(_ id: String, timeout: TimeInterval = 10) {
    let target = element(id)
    // Wait for the page, then scroll until the (lazily built) target is laid
    // out on screen.
    if !target.waitForExistence(timeout: timeout) { scrollUntilExists(target, id) }
    for _ in 0..<8 where !(target.isHittable && target.frame.height > 0) {
      app.swipeUp(velocity: .slow)
    }
    waitUntilSettled(target)
    target.tap()
  }

  /// Waits until [target] stops moving: a tap during a fling only stops the
  /// scroll in Flutter, it never reaches the button.
  private func waitUntilSettled(_ target: XCUIElement, timeout: TimeInterval = 5) {
    let deadline = Date().addingTimeInterval(timeout)
    var last = target.frame
    while Date() < deadline {
      RunLoop.current.run(until: Date().addingTimeInterval(0.25))
      let now = target.frame
      if now == last { return }
      last = now
    }
  }

  /// The paywall is presented (PRD §8.2 hard paywall); the purchase lands on
  /// the server (see the class note) and the user returns to the flow, which
  /// re-reads the ledger and continues.
  private func buy(product: String) {
    expectExists(element("paywall.close"), timeout: 20, "paywall presented")
    XCTAssertTrue(label("Make it a full song").exists)
    // Restore / Terms / Privacy / Manage (App Review 3.1.2), at the foot.
    scrollUntilExists(element("paywall.links"), "paywall legal links")
    XCTAssertTrue(label("Restore purchases").exists)
    XCTAssertNoThrow(try admin.post("grant", ["product_id": product]))
    element("paywall.close").tap()
  }

  private func openSettings() {
    openTab("settings")
    expectExists(element("settings.credits"), timeout: 10, "settings")
  }

  /// Pops pushed routes (Flutter "Back" buttons), then selects a tab
  /// (`nav.create` / `nav.library` / `nav.settings`).
  private func openTab(_ tab: String) {
    let destination = element("nav.\(tab)")
    for _ in 0..<6 {
      if destination.waitForExistence(timeout: 1) && destination.isHittable { break }
      let back = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Back'")).firstMatch
      guard back.waitForExistence(timeout: 3) else { break }
      back.tap()
    }
    expectExists(destination, timeout: 10, "\(tab) tab")
    destination.tap()
  }

  private func assertLibrarySongStillPlays(fullSong: Bool = false) {
    openTab("library")
    let song = app.descendants(matching: .any)
      .matching(NSPredicate(format: "identifier BEGINSWITH 'library.work.'"))
      .firstMatch
    expectExists(song, timeout: 20, "library entry")
    song.tap()
    expectExists(element("player.toggle"), timeout: 10, fullSong ? "full-song player" : "player")
    if fullSong { XCTAssertTrue(element("player.sections").exists, "full-song player (P09)") }
    // Opening a work autoplays it; start it by hand if it did not.
    if !transport("Pause").waitForExistence(timeout: 5) { transport("Play").tap() }
    expectExists(transport("Pause"), timeout: 10, "playback started")
  }

  /// The export sheet of `UIDocumentPickerViewController(forExporting:)`,
  /// then the app's [confirmation] banner (it dismisses itself after a
  /// couple of seconds, so it is watched for together with the sheet's
  /// "Replace" prompt rather than after it).
  private func saveInFilesPicker(confirmation: String) {
    let saved = label(confirmation)
    for title in ["Save", "Move", "Done", "Copy"] {
      let button = app.buttons[title]
      if button.waitForExistence(timeout: title == "Save" ? 15 : 2) && button.isEnabled {
        button.tap()
        // A folder from an earlier run is replaced, not duplicated.
        let replace = app.buttons["Replace"]
        let deadline = Date().addingTimeInterval(20)
        while Date() < deadline {
          if saved.exists { return }
          if replace.exists { replace.tap() }
          RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        expectExists(saved, timeout: 1, "saved confirmation")
        return
      }
    }
    XCTFail("Files export sheet not found:\n\(app.debugDescription)")
  }

  /// Waits for [element]; on failure attaches a screenshot + the UI tree.
  private func expectExists(
    _ element: XCUIElement, timeout: TimeInterval, _ message: String,
    file: StaticString = #filePath, line: UInt = #line
  ) {
    if element.waitForExistence(timeout: timeout) { return }
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.lifetime = .keepAlways
    add(shot)
    let tree = XCTAttachment(string: app.debugDescription)
    tree.name = "UI tree at failure"
    tree.lifetime = .keepAlways
    add(tree)
    XCTFail(message, file: file, line: line)
  }

  /// Any element whose accessibility label is exactly [text] (Flutter exposes
  /// message banners and some texts as generic elements, not static texts).
  private func label(_ text: String) -> XCUIElement {
    app.descendants(matching: .any)
      .matching(NSPredicate(format: "label == %@ OR label CONTAINS %@", text, text))
      .firstMatch
  }

  private func element(_ id: String) -> XCUIElement {
    app.descendants(matching: .any).matching(identifier: id).firstMatch
  }

  /// The text field tagged [id] (the tag sits on its container).
  private func field(in id: String) -> XCUIElement {
    let tagged = element(id)
    expectExists(tagged, timeout: 10, id)
    let inner = tagged.textFields.firstMatch
    return inner.exists ? inner : tagged
  }
}

/// Minimal client for the mock's `/__admin` API (dev only).
private struct MockAdmin {
  let base: URL

  struct Account {
    let tier: String
    let songsLeft: Int
    let clipsLeft: Int
    let credits: Int
  }

  @discardableResult
  func post(_ path: String, _ body: [String: Any] = [:]) throws -> [String: Any] {
    try call(path, method: "POST", body: body)
  }

  /// The most recently active account's computed status.
  func account() throws -> Account {
    let state = try call("state", method: "GET", body: nil)
    let data = state["data"] as? [String: Any] ?? [:]
    let accounts = data["accounts"] as? [[String: Any]] ?? []
    let withPurchases = accounts.last { (($0["status"] as? [String: Any])?["tier"] as? String) != "free" }
    let status = ((withPurchases ?? accounts.last)?["status"] as? [String: Any]) ?? [:]
    return Account(
      tier: status["tier"] as? String ?? "",
      songsLeft: status["songs_left"] as? Int ?? -1,
      clipsLeft: status["clips_left"] as? Int ?? -1,
      credits: status["credits"] as? Int ?? -1)
  }

  func firstTransactionId() throws -> String {
    let state = try call("state", method: "GET", body: nil)
    let data = state["data"] as? [String: Any] ?? [:]
    let transactions = data["transactions"] as? [[String: Any]] ?? []
    guard let tx = transactions.first else { return "" }
    return (tx["transaction_id"] as? String) ?? (tx["transactionId"] as? String) ?? ""
  }

  private func call(_ path: String, method: String, body: [String: Any]?) throws -> [String: Any] {
    var request = URLRequest(url: base.appendingPathComponent(path))
    request.httpMethod = method
    if let body {
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = try JSONSerialization.data(withJSONObject: body)
    }
    let semaphore = DispatchSemaphore(value: 0)
    var result: [String: Any] = [:]
    var failure: Error?
    URLSession.shared.dataTask(with: request) { data, _, error in
      failure = error
      if let data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        result = json
      }
      semaphore.signal()
    }.resume()
    semaphore.wait()
    if let failure { throw failure }
    return result
  }
}
