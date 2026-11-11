// Renders the text layers of an App Store preview to transparent PNGs
// (packages/store_preview, post/layers.dart).
//
// ffmpeg builds here carry no text filter (no freetype / libass), so text is
// typeset with CoreText — the system font (SF Pro) and its cascade for the
// scripts SF Pro lacks (Hiragino, PingFang, Apple SD Gothic, Kohinoor
// Devanagari, …), or the app's font — and composited by ffmpeg.
//
//   render_text <spec.json>
//
// spec.json: {"items": [<caption> | <card>]}
//   caption: {"kind": "caption", "text", "out", "width", "font_size", "color",
//             "plate", "plate_opacity", "radius", "font"}
//            → a PNG as wide as its text box (at most 86 % of `width`; long
//              lines wrap), the text on a rounded plate.
//   card:    {"kind": "card", "out", "width", "height", "icon", "icon_size",
//             "icon_center_y", "gap", "text_width", "color", "lines": [{"text",
//             "size", "weight"}], "footnote": {"text", "size", "bottom"} | null,
//             "font"}
//            → a full-frame PNG: the icon (rounded like a home-screen icon)
//              centred at `icon_center_y`, the lines below it, the footnote
//              `bottom` px above the bottom edge.
//   creative: {"kind": "creative", "out", "mask_out", "shadow_out", "layout_out",
//             "width", "height", "safe": [x, y, w, h], "panel_size": [w, h],
//             "panel_radius", "gap", "direction": "ltr" | "rtl", "icon",
//             "icon_size", "brand_name", "name_size", "brand_space",
//             "phrase": <text> | null, "text_size", "max_lines", "color",
//             "shadow_color", "shadow_opacity", "shadow_blur", "shadow_offset",
//             "font"}
//            → a creative asset's layers (creative/composer.dart): the phone
//              panel and a text block (the brand row, then the phrase) side by
//              side, centred together in the safe area. `out`: the text block
//              on a transparent canvas; `mask_out`: the panel's rounded shape
//              (white on black, panel size); `shadow_out`: the panel's shadow
//              (canvas); `layout_out`: JSON of where everything went
//              ({"panel", "block", "brand", "text", "lines"}, [x, y, w, h] from
//              the top left). The phrase wraps at the room beside the panel;
//              more than `max_lines` lines, or a block that does not fit the
//              safe area, fails.
//   font:    {"family": "system" | <name>, "weight", "file": <path> | null}
import AppKit
import CoreText
import Foundation

struct FontSpec: Decodable {
  let family: String
  let weight: String
  let file: String?
}

struct Line: Decodable {
  let text: String
  let size: Double
  let weight: String
}

struct Footnote: Decodable {
  let text: String
  let size: Double
  let bottom: Double
}

struct Item: Decodable {
  let kind: String
  let out: String
  let text: String?
  let width: Double
  let height: Double?
  let font_size: Double?
  let color: String
  let plate: String?
  let plate_opacity: Double?
  let radius: Double?
  let icon: String?
  let icon_size: Double?
  let icon_center_y: Double?
  let gap: Double?
  let text_width: Double?
  let lines: [Line]?
  let footnote: Footnote?
  let font: FontSpec
  let mask_out: String?
  let shadow_out: String?
  let layout_out: String?
  let safe: [Double]?
  let panel_size: [Double]?
  let panel_radius: Double?
  let direction: String?
  let axis: String?
  let brand_name: String?
  let name_size: Double?
  let brand_space: Double?
  let phrase: String?
  let text_size: Double?
  let max_lines: Int?
  let shadow_color: String?
  let shadow_opacity: Double?
  let shadow_blur: Double?
  let shadow_offset: Double?
  let stroke_width: Double?
  let stroke_opacity: Double?
}

struct Spec: Decodable {
  let items: [Item]
}

func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data("render_text: \(message)\n".utf8))
  exit(1)
}

func color(_ hex: String, alpha: Double = 1) -> NSColor {
  var s = hex.trimmingCharacters(in: .whitespaces)
  if s.hasPrefix("#") { s.removeFirst() }
  guard let v = UInt64(s, radix: 16), s.count == 6 || s.count == 8 else { fail("bad colour \(hex)") }
  let rgba = s.count == 6 ? (v << 8) | 0xFF : v
  return NSColor(
    srgbRed: CGFloat((rgba >> 24) & 0xFF) / 255,
    green: CGFloat((rgba >> 16) & 0xFF) / 255,
    blue: CGFloat((rgba >> 8) & 0xFF) / 255,
    alpha: CGFloat(rgba & 0xFF) / 255 * CGFloat(alpha)
  )
}

func weight(_ name: String) -> NSFont.Weight {
  switch name {
  case "regular": return .regular
  case "medium": return .medium
  case "bold": return .bold
  case "heavy": return .heavy
  default: return .semibold
  }
}

var registered = Set<String>()

func font(_ spec: FontSpec, size: Double, weightName: String? = nil) -> NSFont {
  let w = weight(weightName ?? spec.weight)
  if let file = spec.file, !registered.contains(file) {
    var error: Unmanaged<CFError>?
    if !CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: file) as CFURL, .process, &error) {
      fail("cannot register font \(file)")
    }
    registered.insert(file)
  }
  if spec.family == "system" { return NSFont.systemFont(ofSize: size, weight: w) }
  let descriptor = NSFontDescriptor(fontAttributes: [
    .family: spec.family,
    .traits: [NSFontDescriptor.TraitKey.weight: w],
  ])
  guard let f = NSFont(descriptor: descriptor, size: size) else { fail("no font family \(spec.family)") }
  return f
}

func attributed(_ text: String, font: NSFont, color: NSColor, shadow: Bool) -> NSAttributedString {
  let paragraph = NSMutableParagraphStyle()
  paragraph.alignment = .center
  paragraph.lineBreakMode = .byWordWrapping
  var attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: paragraph]
  if shadow {
    let s = NSShadow()
    s.shadowColor = NSColor.black.withAlphaComponent(0.35)
    s.shadowOffset = NSSize(width: 0, height: -1)
    s.shadowBlurRadius = font.pointSize * 0.06
    attributes[.shadow] = s
  }
  return NSAttributedString(string: text, attributes: attributes)
}

func canvas(_ w: Int, _ h: Int, draw: () -> Void) -> Data {
  guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
  ) else { fail("cannot allocate \(w)x\(h)") }
  rep.size = NSSize(width: w, height: h)
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
  draw()
  NSGraphicsContext.restoreGraphicsState()
  guard let png = rep.representation(using: .png, properties: [:]) else { fail("cannot encode PNG") }
  return png
}

func caption(_ item: Item) -> Data {
  guard let text = item.text, let size = item.font_size else { fail("a caption needs text and font_size") }
  let f = font(item.font, size: size)
  let string = attributed(text, font: f, color: color(item.color), shadow: true)
  let padX = (size * 0.62).rounded()
  let padY = (size * 0.38).rounded()
  let maxTextWidth = item.width * 0.86 - 2 * padX
  let bounds = string.boundingRect(
    with: NSSize(width: maxTextWidth, height: 10_000),
    options: [.usesLineFragmentOrigin, .usesFontLeading]
  )
  let w = Int((bounds.width + 2 * padX).rounded(.up))
  let h = Int((bounds.height + 2 * padY).rounded(.up))
  return canvas(w, h) {
    let r = size * (item.radius ?? 0.5)
    let plate = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: w, height: h), xRadius: r, yRadius: r)
    color(item.plate ?? "#000000", alpha: item.plate_opacity ?? 0.62).setFill()
    plate.fill()
    string.draw(
      with: NSRect(x: padX, y: padY, width: Double(w) - 2 * padX, height: bounds.height),
      options: [.usesLineFragmentOrigin, .usesFontLeading]
    )
  }
}

func card(_ item: Item) -> Data {
  guard let height = item.height, let iconPath = item.icon, let iconSize = item.icon_size,
        let iconCenter = item.icon_center_y, let gap = item.gap, let textWidth = item.text_width
  else { fail("a card needs height, icon, icon_size, icon_center_y, gap, text_width") }
  guard let icon = NSImage(contentsOfFile: iconPath) else { fail("cannot read icon \(iconPath)") }
  let w = Int(item.width)
  let h = Int(height)
  let ink = color(item.color)
  // Top-left layout, drawn in AppKit's bottom-left coordinates.
  func rect(x: Double, top: Double, width: Double, height: Double) -> NSRect {
    NSRect(x: x, y: Double(h) - top - height, width: width, height: height)
  }
  return canvas(w, h) {
    let iconTop = iconCenter - iconSize / 2
    let iconRect = rect(x: (Double(w) - iconSize) / 2, top: iconTop, width: iconSize, height: iconSize)
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: iconRect, xRadius: iconSize * 0.2237, yRadius: iconSize * 0.2237).addClip()
    icon.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    var top = iconTop + iconSize + gap
    for line in item.lines ?? [] {
      let string = attributed(line.text, font: font(item.font, size: line.size, weightName: line.weight), color: ink, shadow: true)
      let bounds = string.boundingRect(
        with: NSSize(width: textWidth, height: 10_000),
        options: [.usesLineFragmentOrigin, .usesFontLeading]
      )
      string.draw(
        with: rect(x: (Double(w) - textWidth) / 2, top: top, width: textWidth, height: bounds.height),
        options: [.usesLineFragmentOrigin, .usesFontLeading]
      )
      top += bounds.height + line.size * 0.4
    }
    if let note = item.footnote {
      let string = attributed(
        note.text,
        font: font(item.font, size: note.size, weightName: "regular"),
        color: ink.withAlphaComponent(0.82),
        shadow: false
      )
      let bounds = string.boundingRect(
        with: NSSize(width: textWidth, height: 10_000),
        options: [.usesLineFragmentOrigin, .usesFontLeading]
      )
      string.draw(
        with: rect(x: (Double(w) - textWidth) / 2, top: Double(h) - note.bottom - bounds.height, width: textWidth, height: bounds.height),
        options: [.usesLineFragmentOrigin, .usesFontLeading]
      )
    }
  }
}

/// A paragraph set by CoreText at `width`: its lines, the widest line's
/// width and the frame's height — measured and drawn by the same frame.
struct SetText {
  let frame: CTFrame
  let lines: Int
  let width: Double
  let height: Double
}

func setText(_ string: NSAttributedString, width: Double) -> SetText {
  let framesetter = CTFramesetterCreateWithAttributedString(string)
  let constraint = CGSize(width: width, height: 100_000)
  let size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(location: 0, length: 0), nil, constraint, nil)
  let height = size.height.rounded(.up)
  let path = CGPath(rect: CGRect(x: 0, y: 0, width: width, height: height), transform: nil)
  let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
  let lines = CTFrameGetLines(frame) as! [CTLine]
  var widest = 0.0
  for line in lines {
    widest = max(widest, CTLineGetTypographicBounds(line, nil, nil, nil) - CTLineGetTrailingWhitespaceWidth(line))
  }
  return SetText(frame: frame, lines: lines.count, width: widest.rounded(.up), height: height)
}

func paragraph(_ text: String, font: NSFont, color: NSColor, alignment: NSTextAlignment) -> NSAttributedString {
  let style = NSMutableParagraphStyle()
  style.alignment = alignment
  style.lineBreakMode = .byWordWrapping
  style.lineHeightMultiple = 1.05
  let s = NSShadow()
  s.shadowColor = NSColor.black.withAlphaComponent(0.3)
  s.shadowOffset = NSSize(width: 0, height: -font.pointSize * 0.02)
  s.shadowBlurRadius = font.pointSize * 0.08
  return NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color, .paragraphStyle: style, .shadow: s])
}

func creative(_ item: Item) -> Data {
  guard let height = item.height, let safe = item.safe, safe.count == 4, let panelSize = item.panel_size, panelSize.count == 2,
        let radius = item.panel_radius, let gap = item.gap, let iconPath = item.icon, let iconSize = item.icon_size,
        let brandName = item.brand_name, let nameSize = item.name_size, let brandSpace = item.brand_space,
        let maskOut = item.mask_out, let shadowOut = item.shadow_out, let layoutOut = item.layout_out
  else { fail("a creative needs height, safe, panel_size, panel_radius, gap, icon, icon_size, brand_name, name_size, brand_space, mask_out, shadow_out, layout_out") }
  guard let icon = NSImage(contentsOfFile: iconPath) else { fail("cannot read icon \(iconPath)") }
  let w = Int(item.width)
  let h = Int(height)
  let rtl = item.direction == "rtl"
  let ink = color(item.color)
  let (sx, sy, sw, sh) = (safe[0], safe[1], safe[2], safe[3])
  let (pw, ph) = (panelSize[0], panelSize[1])
  let vertical = item.axis == "vertical"
  let room = vertical ? sw : sw - pw - gap
  if room <= 0 { fail("the panel (\(Int(pw)) px) and the gap leave no room for text in the safe area (\(Int(sw)) px)") }

  // The brand row: the icon, then the name on one line.
  let nameString = paragraph(brandName, font: font(item.font, size: nameSize, weightName: "semibold"), color: ink, alignment: .natural)
  let nameSet = setText(nameString, width: 100_000)
  let iconGap = (iconSize * 0.28).rounded()
  let brandWidth = iconSize + iconGap + nameSet.width
  if brandWidth > room { fail("the brand row is \(Int(brandWidth)) px wide, the room beside the panel \(Int(room)) px") }

  // The phrase, wrapped at the room beside the panel.
  var phraseSet: SetText?
  if let phrase = item.phrase {
    guard let size = item.text_size, let maxLines = item.max_lines else { fail("a phrase needs text_size and max_lines") }
    let string = paragraph(phrase, font: font(item.font, size: size, weightName: "bold"), color: ink, alignment: rtl ? .right : .left)
    var set = setText(string, width: room)
    if set.lines > maxLines {
      fail("\"\(phrase)\" sets in \(set.lines) lines at \(Int(size)) px (at most \(maxLines)): shorten it")
    }
    // Balanced lines: the narrowest width that keeps the line count, so a
    // wrapped phrase never leaves a lone word on its last line.
    if set.lines > 1 {
      var lo = set.width / Double(set.lines)
      var hi = room
      while hi - lo > 2 {
        let mid = ((lo + hi) / 2).rounded()
        if setText(string, width: mid).lines == set.lines { hi = mid } else { lo = mid }
      }
      set = setText(string, width: hi)
    }
    phraseSet = set
  }
  let blockWidth = max(brandWidth, phraseSet?.width ?? 0)
  let blockHeight = iconSize + (phraseSet.map { brandSpace + $0.height } ?? 0)
  if blockHeight > sh { fail("the text block is \(Int(blockHeight)) px tall, the safe area \(Int(sh)) px") }

  // The panel and the block, centred together in the safe area.
  if vertical && (blockHeight + gap + ph > sh || pw > sw) {
    fail("the portrait panel and text exceed the safe area; change the declared layout or copy")
  }
  let groupWidth = vertical ? max(pw, blockWidth) : pw + gap + blockWidth
  let groupX = (sx + (sw - groupWidth) / 2).rounded()
  let panelX = vertical ? (sx + (sw - pw) / 2).rounded() : (rtl ? groupX + blockWidth + gap : groupX)
  let groupTop = (sy + (sh - blockHeight - gap - ph) / 2).rounded()
  let panelY = vertical ? groupTop + blockHeight + gap : (sy + (sh - ph) / 2).rounded()
  let blockX = vertical ? (sx + (sw - blockWidth) / 2).rounded() : (rtl ? groupX : groupX + pw + gap)
  let blockY = vertical ? groupTop : (panelY + ph / 2 - blockHeight / 2).rounded()
  func rect(x: Double, top: Double, width: Double, height: Double) -> NSRect {
    NSRect(x: x, y: Double(h) - top - height, width: width, height: height)
  }
  let brandX = rtl ? blockX + blockWidth - brandWidth : blockX
  let textTop = blockY + iconSize + brandSpace

  let text = canvas(w, h) {
    // Icon (rounded like a home-screen icon) and name; mirrored for RTL.
    let iconX = rtl ? brandX + brandWidth - iconSize : brandX
    let iconRect = rect(x: iconX, top: blockY, width: iconSize, height: iconSize)
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: iconRect, xRadius: iconSize * 0.2237, yRadius: iconSize * 0.2237).addClip()
    icon.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    let nameX = rtl ? brandX : brandX + iconSize + iconGap
    let nameTop = blockY + (iconSize - nameSet.height) / 2
    guard let cg = NSGraphicsContext.current?.cgContext else { fail("no graphics context") }
    func draw(_ set: SetText, x: Double, top: Double) {
      cg.saveGState()
      cg.translateBy(x: x, y: Double(h) - top - set.height)
      CTFrameDraw(set.frame, cg)
      cg.restoreGState()
    }
    draw(nameSet, x: nameX, top: nameTop)
    if let set = phraseSet {
      // Set at the full room: left-aligned from the block's start, or
      // right-aligned to its end for RTL.
      let frameWidth = CTFrameGetPath(set.frame).boundingBox.width
      draw(set, x: rtl ? blockX + blockWidth - frameWidth : blockX, top: textTop)
    }
    // A hairline round the panel: the screen's edge stays visible on a dark
    // backdrop.
    if let width = item.stroke_width, width > 0 {
      let edge = NSBezierPath(
        roundedRect: rect(x: panelX + width / 2, top: panelY + width / 2, width: pw - width, height: ph - width),
        xRadius: radius - width / 2, yRadius: radius - width / 2
      )
      edge.lineWidth = width
      ink.withAlphaComponent(item.stroke_opacity ?? 0.2).setStroke()
      edge.stroke()
    }
  }
  let mask = canvas(Int(pw), Int(ph)) {
    NSColor.black.setFill()
    NSRect(x: 0, y: 0, width: pw, height: ph).fill()
    NSColor.white.setFill()
    NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: pw, height: ph), xRadius: radius, yRadius: radius).fill()
  }
  let shadow = canvas(w, h) {
    // The shape is drawn off the canvas; only its shadow falls on it.
    let away = Double(w) * 2
    let s = NSShadow()
    s.shadowColor = color(item.shadow_color ?? "#000000", alpha: item.shadow_opacity ?? 0.45)
    s.shadowBlurRadius = item.shadow_blur ?? 0
    s.shadowOffset = NSSize(width: -away, height: -(item.shadow_offset ?? 0))
    s.set()
    NSColor.black.setFill()
    NSBezierPath(roundedRect: rect(x: panelX + away, top: panelY, width: pw, height: ph), xRadius: radius, yRadius: radius).fill()
  }
  let layout: [String: Any] = [
    "panel": [panelX, panelY, pw, ph],
    "block": [blockX, blockY, blockWidth, blockHeight],
    "brand": [brandX, blockY, brandWidth, iconSize],
    "text": phraseSet.map { [rtl ? blockX + blockWidth - $0.width : blockX, textTop, $0.width, $0.height] as Any } ?? NSNull(),
    "lines": phraseSet?.lines ?? 0,
  ]
  do {
    try mask.write(to: URL(fileURLWithPath: maskOut))
    try shadow.write(to: URL(fileURLWithPath: shadowOut))
    try JSONSerialization.data(withJSONObject: layout, options: [.sortedKeys]).write(to: URL(fileURLWithPath: layoutOut))
  } catch {
    fail("cannot write the creative layers: \(error)")
  }
  return text
}

guard CommandLine.arguments.count == 2 else { fail("usage: render_text <spec.json>") }
let spec: Spec
do {
  spec = try JSONDecoder().decode(Spec.self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
} catch {
  fail("bad spec: \(error)")
}
for item in spec.items {
  let png: Data
  switch item.kind {
  case "caption": png = caption(item)
  case "card": png = card(item)
  case "creative": png = creative(item)
  default: fail("unknown kind \(item.kind)")
  }
  do {
    try png.write(to: URL(fileURLWithPath: item.out))
  } catch {
    fail("cannot write \(item.out): \(error)")
  }
}
