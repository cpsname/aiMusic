import AVFoundation
import Flutter
import Photos
import UIKit

/// Encodes the 9:16 share-card video (PRD F08): Dart renders the card frames
/// (cover, lyric lines, the non-removable "AI generated" badge — burned into
/// every frame) and this muxes them with the song audio into an H.264/AAC MP4.
///
/// Deliberately a separate method channel, not part of the Pigeon bridge: PRD
/// §6.4 fixes that interface verbatim and it has no video call, while encoding
/// H.264 is only practical through AVFoundation.
///
/// `compose` arguments: `frames` ([{path: PNG, start: seconds}], ascending),
/// `audioPath`, `outputPath`, `duration` (seconds), `width`, `height`, `fps`.
final class ShareCardComposer {
  static let channelName = "songlet/share_card"

  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      if call.method == "saveToPhotos", let path = (call.arguments as? [String: Any])?["path"] as? String {
        Task { result(await Self.saveToPhotos(path: path)) }
        return
      }
      guard call.method == "compose", let args = call.arguments as? [String: Any] else {
        result(FlutterMethodNotImplemented)
        return
      }
      Task.detached(priority: .userInitiated) {
        do {
          try await Self.compose(args)
          await MainActor.run { result(nil) }
        } catch {
          await MainActor.run {
            result(FlutterError(code: "compose_failed", message: error.localizedDescription, details: nil))
          }
        }
      }
    }
  }

  /// "Save video" (docs/ui P10): adds the MP4 to the photo library with
  /// add-only access. False when access is refused or the save fails.
  private static func saveToPhotos(path: String) async -> Bool {
    let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    guard status == .authorized || status == .limited else { return false }
    do {
      try await PHPhotoLibrary.shared().performChanges {
        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: path))
      }
      return true
    } catch {
      return false
    }
  }

  private struct Frame {
    let image: CGImage
    let start: Double
  }

  private static func compose(_ args: [String: Any]) async throws {
    guard let rawFrames = args["frames"] as? [[String: Any]], !rawFrames.isEmpty,
          let audioPath = args["audioPath"] as? String,
          let outputPath = args["outputPath"] as? String,
          let duration = (args["duration"] as? NSNumber)?.doubleValue, duration > 0
    else { throw ComposeError.badArguments }
    let width = (args["width"] as? NSNumber)?.intValue ?? 1080
    let height = (args["height"] as? NSNumber)?.intValue ?? 1920
    let fps = Int32((args["fps"] as? NSNumber)?.intValue ?? 5)

    let frames: [Frame] = try rawFrames.map { raw in
      guard let path = raw["path"] as? String,
            let start = (raw["start"] as? NSNumber)?.doubleValue,
            let image = UIImage(contentsOfFile: path)?.cgImage
      else { throw ComposeError.badFrame }
      return Frame(image: image, start: start)
    }

    let silent = FileManager.default.temporaryDirectory
      .appendingPathComponent("songlet-card-\(UUID().uuidString).mp4")
    defer { try? FileManager.default.removeItem(at: silent) }
    try await writeVideo(frames, to: silent, width: width, height: height, fps: fps, duration: duration)

    let output = URL(fileURLWithPath: outputPath)
    try? FileManager.default.removeItem(at: output)
    try await mux(video: silent, audio: URL(fileURLWithPath: audioPath), duration: duration, to: output)
  }

  private static func writeVideo(
    _ frames: [Frame], to url: URL, width: Int, height: Int, fps: Int32, duration: Double
  ) async throws {
    let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
    let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: width,
      AVVideoHeightKey: height,
      AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 2_500_000],
    ])
    input.expectsMediaDataInRealTime = false
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
      kCVPixelBufferWidthKey as String: width,
      kCVPixelBufferHeightKey as String: height,
    ])
    writer.add(input)
    guard writer.startWriting() else { throw writer.error ?? ComposeError.writerFailed }
    writer.startSession(atSourceTime: .zero)

    // Constant frame rate: repeat the active card until the next one starts.
    let total = Int(ceil(duration * Double(fps)))
    var buffers: [Int: CVPixelBuffer] = [:]
    for index in 0...total {
      let seconds = min(Double(index) / Double(fps), duration)
      let active = frames.lastIndex(where: { $0.start <= seconds }) ?? 0
      let buffer: CVPixelBuffer
      if let cached = buffers[active] {
        buffer = cached
      } else {
        buffer = try pixelBuffer(from: frames[active].image, width: width, height: height, pool: adaptor.pixelBufferPool)
        buffers = [active: buffer]
      }
      while !input.isReadyForMoreMediaData {
        try await Task.sleep(nanoseconds: 5_000_000)
      }
      let time = CMTime(value: CMTimeValue(index), timescale: fps)
      guard adaptor.append(buffer, withPresentationTime: time) else {
        throw writer.error ?? ComposeError.writerFailed
      }
    }
    input.markAsFinished()
    await writer.finishWriting()
    if writer.status != .completed { throw writer.error ?? ComposeError.writerFailed }
  }

  private static func pixelBuffer(
    from image: CGImage, width: Int, height: Int, pool: CVPixelBufferPool?
  ) throws -> CVPixelBuffer {
    var buffer: CVPixelBuffer?
    if let pool {
      CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
    } else {
      CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32ARGB, nil, &buffer)
    }
    guard let buffer else { throw ComposeError.writerFailed }
    CVPixelBufferLockBaseAddress(buffer, [])
    defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
    guard let context = CGContext(
      data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height,
      bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
    else { throw ComposeError.writerFailed }
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    return buffer
  }

  private static func mux(video: URL, audio: URL, duration: Double, to output: URL) async throws {
    let composition = AVMutableComposition()
    let range = CMTimeRange(start: .zero, duration: CMTime(seconds: duration, preferredTimescale: 600))

    let videoAsset = AVURLAsset(url: video)
    guard let videoTrack = try await videoAsset.loadTracks(withMediaType: .video).first,
          let videoOut = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
    else { throw ComposeError.writerFailed }
    let videoDuration = try await videoAsset.load(.duration)
    try videoOut.insertTimeRange(
      CMTimeRange(start: .zero, duration: min(videoDuration, range.duration)), of: videoTrack, at: .zero)

    let audioAsset = AVURLAsset(url: audio)
    if let audioTrack = try await audioAsset.loadTracks(withMediaType: .audio).first,
       let audioOut = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
      let audioDuration = try await audioAsset.load(.duration)
      try audioOut.insertTimeRange(
        CMTimeRange(start: .zero, duration: min(audioDuration, range.duration)), of: audioTrack, at: .zero)
    }

    guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
    else { throw ComposeError.writerFailed }
    try await export.export(to: output, as: .mp4)
  }

  enum ComposeError: LocalizedError {
    case badArguments, badFrame, writerFailed

    var errorDescription: String? {
      switch self {
      case .badArguments: return "invalid compose arguments"
      case .badFrame: return "unreadable card frame"
      case .writerFailed: return "video writer failed"
      }
    }
  }
}
