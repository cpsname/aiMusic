import UIKit
import UniformTypeIdentifiers

/// "Export to Files" (PRD F09): presents the system document picker in export
/// mode so the user chooses where the MP3 (or a folder with the MP3, the
/// lyrics and the license PDF) is saved. `name` becomes the exported item's
/// name. Completes after the user saved (success) or dismissed the picker
/// (`PigeonError(code: "cancelled")`).
@MainActor
final class FileExportService: NSObject, UIDocumentPickerDelegate {
  private var completion: ((Result<Void, Error>) -> Void)?
  private var staging: URL?

  func export(path: String, name: String, completion: @escaping (Result<Void, Error>) -> Void) {
    guard self.completion == nil else {
      completion(.failure(PigeonError(code: "busy", message: "export in progress", details: nil)))
      return
    }
    let source = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: source.path),
          let presenter = UIApplication.shared.songletTopViewController
    else {
      completion(.failure(PigeonError(code: "not_found", message: "nothing to export", details: nil)))
      return
    }

    do {
      let staged = try stage(source, as: name)
      staging = staged.deletingLastPathComponent()
      self.completion = completion
      let picker = UIDocumentPickerViewController(forExporting: [staged], asCopy: true)
      picker.delegate = self
      picker.shouldShowFileExtensions = true
      presenter.present(picker, animated: true)
    } catch {
      completion(.failure(PigeonError(code: "stage_failed", message: error.localizedDescription, details: nil)))
    }
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    finish(.success(()))
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    finish(.failure(PigeonError(code: "cancelled", message: nil, details: nil)))
  }

  private func finish(_ result: Result<Void, Error>) {
    if let staging { try? FileManager.default.removeItem(at: staging) }
    staging = nil
    let done = completion
    completion = nil
    done?(result)
  }

  /// Copies `source` into a fresh temp directory under the export `name` (the
  /// picker exports the item under its own file name).
  private func stage(_ source: URL, as name: String) throws -> URL {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("songlet-export-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let safeName = name.replacingOccurrences(of: "/", with: "-")
    let target = directory.appendingPathComponent(safeName.isEmpty ? source.lastPathComponent : safeName)
    try FileManager.default.copyItem(at: source, to: target)
    return target
  }
}
