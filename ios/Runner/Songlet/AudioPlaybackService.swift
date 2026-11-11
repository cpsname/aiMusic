import AVFoundation
import MediaPlayer
import UIKit

/// AVAudioPlayer playback with background audio + lock-screen / Control Center
/// controls (PRD F07). Requires `UIBackgroundModes: audio` in Info.plist.
///
/// The fixed bridge has a single `playAudio(path, loop)` call, so its meaning is
/// pinned here (and in pigeons/songlet_api.dart):
/// * a `path` other than the loaded one → load it and play from 0;
/// * the loaded `path` with the **same** `loop` → toggle pause / resume;
/// * the loaded `path` with a different `loop` → only change looping;
/// * an empty `path` → stop and release.
/// Progress goes back through `onPlaybackProgress`: seconds (≥ 0) while playing
/// (4 Hz), `-1` when paused (by the app, a remote command or an interruption),
/// `-2` when playback ended or stopped.
final class AudioPlaybackService: NSObject, AVAudioPlayerDelegate {
  static let paused: Double = -1
  static let ended: Double = -2

  var onProgress: ((Double) -> Void)?

  private var player: AVAudioPlayer?
  private var currentPath: String?
  private var currentLoop = false
  private var timer: Timer?
  private var remoteCommandsInstalled = false

  override init() {
    super.init()
    NotificationCenter.default.addObserver(
      self, selector: #selector(handleInterruption(_:)),
      name: AVAudioSession.interruptionNotification, object: nil)
  }

  func play(path: String, loop: Bool) throws {
    if path.isEmpty {
      stop()
      return
    }
    if path == currentPath, let player {
      if loop != currentLoop {
        currentLoop = loop
        player.numberOfLoops = loop ? -1 : 0
        return
      }
      if player.isPlaying {
        pause()
      } else {
        try resume()
      }
      return
    }

    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, mode: .default)
    try session.setActive(true)

    let newPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
    newPlayer.delegate = self
    newPlayer.numberOfLoops = loop ? -1 : 0
    newPlayer.prepareToPlay()
    player?.stop()
    player = newPlayer
    currentPath = path
    currentLoop = loop
    installRemoteCommands()
    newPlayer.play()
    startTimer()
    updateNowPlaying(title: "Songlet")
    Task { @MainActor [weak self] in
      guard let title = await Self.title(of: path), self?.currentPath == path else { return }
      self?.updateNowPlaying(title: title)
    }
  }

  /// Moves the loaded track to [seconds] (clamped to its length) without
  /// changing play / pause — the `songlet/playback` seek (ADR-0017).
  func seek(to seconds: Double) {
    guard let player else { return }
    player.currentTime = max(0, min(seconds, player.duration))
    onProgress?(player.isPlaying ? player.currentTime : Self.paused)
    updateNowPlayingRate()
  }

  // MARK: - AVAudioPlayerDelegate

  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    stopTimer()
    onProgress?(Self.ended)
    updateNowPlayingRate()
  }

  // MARK: - Private

  private func pause() {
    player?.pause()
    stopTimer()
    onProgress?(Self.paused)
    updateNowPlayingRate()
  }

  private func resume() throws {
    try AVAudioSession.sharedInstance().setActive(true)
    player?.play()
    startTimer()
    updateNowPlayingRate()
  }

  private func stop() {
    player?.stop()
    player = nil
    currentPath = nil
    stopTimer()
    onProgress?(Self.ended)
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }

  private func startTimer() {
    stopTimer()
    timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
      guard let self, let player = self.player, player.isPlaying else { return }
      self.onProgress?(player.currentTime)
    }
    if let player { onProgress?(player.currentTime) }
  }

  private func stopTimer() {
    timer?.invalidate()
    timer = nil
  }

  @objc private func handleInterruption(_ notification: Notification) {
    guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: raw)
    else { return }
    if type == .began, player?.isPlaying == true {
      stopTimer()
      onProgress?(Self.paused)
      updateNowPlayingRate()
    }
  }

  private func installRemoteCommands() {
    guard !remoteCommandsInstalled else { return }
    remoteCommandsInstalled = true
    let center = MPRemoteCommandCenter.shared()
    center.playCommand.addTarget { [weak self] _ in
      guard let self, self.player != nil else { return .noActionableNowPlayingItem }
      try? self.resume()
      return .success
    }
    center.pauseCommand.addTarget { [weak self] _ in
      guard let self, self.player != nil else { return .noActionableNowPlayingItem }
      self.pause()
      return .success
    }
    center.togglePlayPauseCommand.addTarget { [weak self] _ in
      guard let self, let player = self.player else { return .noActionableNowPlayingItem }
      if player.isPlaying { self.pause() } else { try? self.resume() }
      return .success
    }
    center.changePlaybackPositionCommand.addTarget { [weak self] event in
      guard let self, let player = self.player,
            let event = event as? MPChangePlaybackPositionCommandEvent
      else { return .commandFailed }
      player.currentTime = event.positionTime
      self.onProgress?(player.isPlaying ? player.currentTime : Self.paused)
      self.updateNowPlayingRate()
      return .success
    }
  }

  private func updateNowPlaying(title: String) {
    guard let player else { return }
    var info: [String: Any] = [
      MPMediaItemPropertyTitle: title,
      MPMediaItemPropertyArtist: "Songlet · AI generated",
      MPMediaItemPropertyPlaybackDuration: player.duration,
      MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
      MPNowPlayingInfoPropertyPlaybackRate: player.isPlaying ? 1.0 : 0.0,
    ]
    if let icon = UIImage(named: "AppIcon") {
      info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: icon.size) { _ in icon }
    }
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
  }

  private func updateNowPlayingRate() {
    guard let player, var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
    info[MPNowPlayingInfoPropertyPlaybackRate] = player.isPlaying ? 1.0 : 0.0
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
  }

  /// The ID3 title the Dart side wrote into the file, if any.
  private static func title(of path: String) async -> String? {
    let asset = AVURLAsset(url: URL(fileURLWithPath: path))
    guard let metadata = try? await asset.load(.commonMetadata),
          let item = AVMetadataItem.metadataItems(
            from: metadata, filteredByIdentifier: .commonIdentifierTitle
          ).first
    else { return nil }
    return try? await item.load(.stringValue)
  }
}
