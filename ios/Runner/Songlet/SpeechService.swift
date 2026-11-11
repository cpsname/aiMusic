import AVFoundation
import Flutter
import Speech

/// On-device dictation for the composer's voice mode (docs/ui P03a; ADR-0006).
///
/// `songlet/speech` methods: `availability(locale)` → `available` | `denied` |
/// `unsupportedLocale` | `unavailable`; `stop()` ends the session (the final
/// transcript follows on the event stream); `cancel()` abandons it.
/// `songlet/speech/events`: listening with `{locale}` starts a session and
/// streams `{type: partial|level|final|error, text?, level?, reason?}`.
///
/// Recognition is forced on-device (`requiresOnDeviceRecognition`): audio never
/// leaves the phone, and a locale without an on-device model reports
/// `unsupportedLocale` instead of falling back to a server.
final class SpeechService: NSObject, FlutterStreamHandler {
  static let methodChannel = "songlet/speech"
  static let eventChannel = "songlet/speech/events"

  private let methods: FlutterMethodChannel
  private let events: FlutterEventChannel
  private var sink: FlutterEventSink?
  private var recognizer: SFSpeechRecognizer?
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private let engine = AVAudioEngine()
  private var lastText = ""

  init(messenger: FlutterBinaryMessenger) {
    methods = FlutterMethodChannel(name: Self.methodChannel, binaryMessenger: messenger)
    events = FlutterEventChannel(name: Self.eventChannel, binaryMessenger: messenger)
    super.init()
    events.setStreamHandler(self)
    methods.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "availability":
        let locale = (call.arguments as? [String: Any])?["locale"] as? String ?? "en-US"
        Task { result(await self.availability(locale: locale)) }
      case "stop":
        self.stop()
        result(nil)
      case "cancel":
        self.cancel()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Availability

  private func availability(locale: String) async -> String {
    let speech = await withCheckedContinuation { continuation in
      SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
    }
    guard speech == .authorized else { return "denied" }
    let microphone = await AVAudioApplication.requestRecordPermission()
    guard microphone else { return "denied" }
    guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: locale)) else {
      return "unsupportedLocale"
    }
    guard recognizer.supportsOnDeviceRecognition else { return "unsupportedLocale" }
    return recognizer.isAvailable ? "available" : "unavailable"
  }

  // MARK: - FlutterStreamHandler

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    let locale = (arguments as? [String: Any])?["locale"] as? String ?? "en-US"
    do {
      try start(locale: locale)
    } catch {
      emit(["type": "error", "reason": "unavailable"])
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    cancel()
    sink = nil
    return nil
  }

  // MARK: - Session

  private func start(locale: String) throws {
    cancel()
    guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: locale)),
          recognizer.supportsOnDeviceRecognition
    else {
      emit(["type": "error", "reason": "unsupportedLocale"])
      return
    }
    self.recognizer = recognizer
    lastText = ""

    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.record, mode: .measurement, options: .duckOthers)
    try session.setActive(true, options: .notifyOthersOnDeactivation)

    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = true
    request.requiresOnDeviceRecognition = true
    request.addsPunctuation = true
    self.request = request

    let input = engine.inputNode
    let format = input.outputFormat(forBus: 0)
    input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
      request.append(buffer)
      self?.emitLevel(buffer)
    }
    engine.prepare()
    try engine.start()

    task = recognizer.recognitionTask(with: request) { [weak self] result, error in
      guard let self else { return }
      if let result {
        self.lastText = result.bestTranscription.formattedString
        if result.isFinal {
          self.emit(["type": "final", "text": self.lastText])
          self.teardown()
          return
        }
        self.emit(["type": "partial", "text": self.lastText])
      }
      if error != nil {
        // Ending the audio also ends the task with an error; the words so far
        // are the final transcript.
        self.emit(["type": "final", "text": self.lastText])
        self.teardown()
      }
    }
  }

  private func stop() {
    engine.stop()
    engine.inputNode.removeTap(onBus: 0)
    request?.endAudio()
  }

  private func cancel() {
    task?.cancel()
    teardown()
  }

  private func teardown() {
    if engine.isRunning { engine.stop() }
    engine.inputNode.removeTap(onBus: 0)
    request = nil
    task = nil
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }

  /// RMS of the buffer mapped to 0..1 (-50 dB … 0 dB), ~20 updates a second.
  private func emitLevel(_ buffer: AVAudioPCMBuffer) {
    guard let channel = buffer.floatChannelData?[0] else { return }
    let count = Int(buffer.frameLength)
    guard count > 0 else { return }
    var sum: Float = 0
    for i in 0..<count { sum += channel[i] * channel[i] }
    let rms = sqrt(sum / Float(count))
    let decibels = 20 * log10(max(rms, 0.000_01))
    let level = max(0, min(1, (decibels + 50) / 50))
    emit(["type": "level", "level": Double(level)])
  }

  private func emit(_ event: [String: Any]) {
    DispatchQueue.main.async { [weak self] in self?.sink?(event) }
  }
}
