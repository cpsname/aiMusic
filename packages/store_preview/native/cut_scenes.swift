// Cuts a preview's timeline out of a simulator recording into one
// constant-frame-rate ProRes clip (packages/store_preview, post/cuts.dart).
//
// `simctl io recordVideo` writes variable-frame-rate H.264 whose composition
// offsets jump after a static stretch; ffmpeg then guesses frame times from
// the decode timestamps, seconds away from the presentation times the scene
// marks are measured against. AVFoundation reads the presentation times as
// written, so the cut happens here and ffmpeg only scales, captions, mixes and
// encodes a clean clip.
//
//   cut_scenes <spec.json>
//
// spec.json: {"recording": "...mov", "out": "...mov", "fps": 30,
//   "cuts": [{"from": s, "to": s, "factor": f}]} — each cut is the recording
// from `from` to `to`, played `1/factor` times faster (factor < 1 = sped up);
// output frame k of a cut shows the last recorded frame at or before
// `from + k / fps / factor`.
import AVFoundation
import Foundation

struct Cut: Decodable {
  let from: Double
  let to: Double
  let factor: Double
}

struct Spec: Decodable {
  let recording: String
  let out: String
  let fps: Int32
  let cuts: [Cut]
}

func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data("cut_scenes: \(message)\n".utf8))
  exit(1)
}

guard CommandLine.arguments.count == 2 else { fail("usage: cut_scenes <spec.json>") }
let spec: Spec
do {
  spec = try JSONDecoder().decode(Spec.self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
} catch {
  fail("bad spec: \(error)")
}

let asset = AVURLAsset(url: URL(fileURLWithPath: spec.recording))
let semaphore = DispatchSemaphore(value: 0)
var loadedTrack: AVAssetTrack?
var loadedSize = CGSize.zero
Task {
  do {
    loadedTrack = try await asset.loadTracks(withMediaType: .video).first
    if let track = loadedTrack {
      loadedSize = try await track.load(.naturalSize)
    }
  } catch {
    fail("cannot read \(spec.recording): \(error)")
  }
  semaphore.signal()
}
semaphore.wait()
guard let track = loadedTrack else { fail("\(spec.recording) has no video track") }
let size = loadedSize

let outURL = URL(fileURLWithPath: spec.out)
try? FileManager.default.removeItem(at: outURL)
let writer: AVAssetWriter
do {
  writer = try AVAssetWriter(outputURL: outURL, fileType: .mov)
} catch {
  fail("cannot write \(spec.out): \(error)")
}
let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
  AVVideoCodecKey: AVVideoCodecType.proRes422,
  AVVideoWidthKey: Int(size.width),
  AVVideoHeightKey: Int(size.height),
])
input.expectsMediaDataInRealTime = false
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
writer.add(input)
guard writer.startWriting() else { fail("writer: \(String(describing: writer.error))") }
writer.startSession(atSourceTime: .zero)

let frameDuration = CMTime(value: 1, timescale: spec.fps)
var written: Int64 = 0

for cut in spec.cuts {
  let reader: AVAssetReader
  do {
    reader = try AVAssetReader(asset: asset)
  } catch {
    fail("reader: \(error)")
  }
  // Start a little early: the frame on screen at `from` may have been
  // recorded before it (the recorder writes a frame only on change).
  let lead = 5.0
  let start = max(0, cut.from - lead)
  reader.timeRange = CMTimeRange(
    start: CMTime(seconds: start, preferredTimescale: 600),
    end: CMTime(seconds: cut.to + 0.5, preferredTimescale: 600)
  )
  let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
  ])
  output.alwaysCopiesSampleData = false
  reader.add(output)
  guard reader.startReading() else { fail("reader: \(String(describing: reader.error))") }

  let frames = Int((((cut.to - cut.from) * cut.factor) * Double(spec.fps)).rounded())
  var current: CVPixelBuffer?
  var pending = output.copyNextSampleBuffer()
  for k in 0..<frames {
    let sourceTime = cut.from + Double(k) / Double(spec.fps) / cut.factor
    // Advance to the last recorded frame at or before sourceTime.
    while let sample = pending, CMSampleBufferGetPresentationTimeStamp(sample).seconds <= sourceTime + 1e-4 {
      if let image = CMSampleBufferGetImageBuffer(sample) { current = image }
      pending = output.copyNextSampleBuffer()
    }
    guard let frame = current else { fail("no recorded frame at or before \(sourceTime)s") }
    while !input.isReadyForMoreMediaData { Thread.sleep(forTimeInterval: 0.002) }
    let time = CMTimeMultiply(frameDuration, multiplier: Int32(written))
    guard adaptor.append(frame, withPresentationTime: time) else {
      fail("append at \(time.seconds)s: \(String(describing: writer.error))")
    }
    written += 1
  }
  reader.cancelReading()
}

input.markAsFinished()
writer.endSession(atSourceTime: CMTimeMultiply(frameDuration, multiplier: Int32(written)))
let done = DispatchSemaphore(value: 0)
writer.finishWriting { done.signal() }
done.wait()
guard writer.status == .completed else { fail("writer: \(String(describing: writer.error))") }
