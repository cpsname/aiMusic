import PhotosUI
import SwiftUI
import UIKit

/// PhotosPicker for image-to-song (PRD F04 / §9.2): the system picker only (no
/// photo-library permission, no network images), up to `max` images, each
/// downscaled to a 1024 px long side and re-encoded as JPEG at quality 0.8.
/// Nothing is written to disk — the JPEG bytes go straight back over the bridge
/// (PRD: "本地不保留副本").
@MainActor
final class PhotoPickerService {
  static let longSide: CGFloat = 1024
  static let jpegQuality: CGFloat = 0.8

  private var host: UIViewController?

  func pick(max: Int, completion: @escaping (Result<[FlutterStandardTypedData], Error>) -> Void) {
    guard host == nil, let presenter = UIApplication.shared.songletTopViewController else {
      completion(.failure(PigeonError(code: "unavailable", message: "no presenter", details: nil)))
      return
    }
    let limit = Swift.max(1, Swift.min(max, 10))
    let view = PhotoPickerHost(maxSelection: limit) { [weak self] items in
      guard let self else { return }
      self.host?.dismiss(animated: false)
      self.host = nil
      Task {
        let images = await Self.load(items)
        completion(.success(images.map { FlutterStandardTypedData(bytes: $0) }))
      }
    }
    let controller = UIHostingController(rootView: view)
    controller.view.backgroundColor = .clear
    controller.modalPresentationStyle = .overFullScreen
    host = controller
    presenter.present(controller, animated: false)
  }

  private static func load(_ items: [PhotosPickerItem]) async -> [Data] {
    var result: [Data] = []
    for item in items {
      guard let data = try? await item.loadTransferable(type: Data.self),
            let image = UIImage(data: data),
            let jpeg = compress(image)
      else { continue }
      result.append(jpeg)
    }
    return result
  }

  /// Long side ≤ 1024 px (never upscaled), orientation baked in, JPEG 0.8.
  static func compress(_ image: UIImage) -> Data? {
    let size = image.size
    let longest = Swift.max(size.width, size.height)
    guard longest > 0 else { return nil }
    let scale = Swift.min(1, longSide / longest)
    let target = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    format.opaque = true
    let rendered = UIGraphicsImageRenderer(size: target, format: format).image { _ in
      image.draw(in: CGRect(origin: .zero, size: target))
    }
    return rendered.jpegData(compressionQuality: jpegQuality)
  }
}

/// Transparent SwiftUI host that immediately presents `PhotosPicker` and reports
/// the selection (empty on cancel) once the sheet is gone.
private struct PhotoPickerHost: View {
  let maxSelection: Int
  let onFinish: ([PhotosPickerItem]) -> Void

  @State private var isPresented = false
  @State private var selection: [PhotosPickerItem] = []
  @State private var finished = false

  var body: some View {
    Color.clear
      .ignoresSafeArea()
      .photosPicker(
        isPresented: $isPresented,
        selection: $selection,
        maxSelectionCount: maxSelection,
        selectionBehavior: .ordered,
        matching: .images,
        preferredItemEncoding: .compatible)
      .onAppear { isPresented = true }
      .onChange(of: isPresented) { _, presented in
        guard !presented, !finished else { return }
        finished = true
        // The selection binding settles in the same transaction as the
        // dismissal; read it on the next turn of the run loop.
        DispatchQueue.main.async { onFinish(selection) }
      }
  }
}

extension UIApplication {
  /// The top-most presented view controller of the foreground key window.
  var songletTopViewController: UIViewController? {
    let window = connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first(where: \.isKeyWindow)
    var top = window?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }
}
