import Flutter
import UIKit

/// The Swift side of the PRD §6.4 Pigeon bridge (`SongletApi.g.swift`, generated
/// from `pigeons/songlet_api.dart`). Each call is delegated to one focused
/// service; this type only adapts completions and forwards the two Flutter-bound
/// events (`onPlaybackProgress`, `onTransactionUpdated`).
@MainActor
final class SongletNativeApiImpl: @preconcurrency SongletNativeApi {
  private let flutterApi: SongletFlutterApi
  private let store: StoreKitService
  private let attest = AppAttestService()
  private let photos = PhotoPickerService()
  private let audio = AudioPlaybackService()
  private let exporter = FileExportService()
  private let polisher = PromptPolisher()

  /// Seek beside the fixed Pigeon interface (ADR-0017).
  private var playbackChannel: FlutterMethodChannel?

  init(messenger: FlutterBinaryMessenger) {
    let flutterApi = SongletFlutterApi(binaryMessenger: messenger)
    self.flutterApi = flutterApi
    store = StoreKitService { jws, delivered in
      flutterApi.onTransactionUpdated(signedTransaction: jws) { result in
        if case .success = result { delivered(true) } else { delivered(false) }
      }
    }
    audio.onProgress = { seconds in
      flutterApi.onPlaybackProgress(seconds: seconds) { _ in }
    }
    store.startListening()

    let playback = FlutterMethodChannel(name: "songlet/playback", binaryMessenger: messenger)
    playback.setMethodCallHandler { [weak self] call, result in
      guard call.method == "seek",
            let seconds = ((call.arguments as? [String: Any])?["seconds"] as? NSNumber)?.doubleValue
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      MainActor.assumeIsolated { self?.audio.seek(to: seconds) }
      result(nil)
    }
    playbackChannel = playback
  }

  func fetchProducts(ids: [String], completion: @escaping (Result<[SKProductDto], Error>) -> Void) {
    store.flushPending()
    Task { completion(await Self.run { try await self.store.fetchProducts(ids: ids) }) }
  }

  func purchase(
    productId: String, appAccountToken: String,
    completion: @escaping (Result<PurchaseResultDto, Error>) -> Void
  ) {
    store.flushPending()
    Task {
      completion(await Self.run {
        try await self.store.purchase(productId: productId, appAccountToken: appAccountToken)
      })
    }
  }

  func currentSignedTransactions(completion: @escaping (Result<[String], Error>) -> Void) {
    store.flushPending()
    Task { completion(.success(await self.store.currentSignedTransactions())) }
  }

  func appAttestAssertion(challenge: String, completion: @escaping (Result<String, Error>) -> Void) {
    Task { completion(await Self.run { try await self.attest.assertion(challenge: challenge) }) }
  }

  func pickPhotos(max: Int64, completion: @escaping (Result<[FlutterStandardTypedData], Error>) -> Void) {
    photos.pick(max: Int(max), completion: completion)
  }

  func playAudio(path: String, loop: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
    do {
      try audio.play(path: path, loop: loop)
      completion(.success(()))
    } catch {
      completion(.failure(PigeonError(code: "playback_failed", message: error.localizedDescription, details: nil)))
    }
  }

  func exportToFiles(path: String, name: String, completion: @escaping (Result<Void, Error>) -> Void) {
    exporter.export(path: path, name: name, completion: completion)
  }

  func polishPrompt(raw: String, locale: String, completion: @escaping (Result<String, Error>) -> Void) {
    Task { completion(.success(await self.polisher.polish(raw: raw, locale: locale))) }
  }

  /// Maps a thrown error to a `PigeonError` so Dart receives a PlatformException
  /// with a stable code.
  private static func run<T>(_ body: () async throws -> T) async -> Result<T, Error> {
    do {
      return .success(try await body())
    } catch let error as PigeonError {
      return .failure(error)
    } catch {
      return .failure(PigeonError(code: "native_error", message: error.localizedDescription, details: nil))
    }
  }
}
