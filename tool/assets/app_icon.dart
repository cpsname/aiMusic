// Builds the single-size 1024 × 1024 AppIcon (ADR-0014) from the design
// export at the repository root: the tile's rounded corners are filled with
// the tile colour (iOS applies its own mask; an icon must be opaque and
// full-bleed), then it is resized and written without alpha.
//
//   dart run tool/assets/app_icon.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const String source = 'ChatGPT Image Sep 24, 2026, 10_43_17 AM.png';
const String target = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png';
const int size = 1024;

/// Corner radius of the source tile as a share of its side.
const double cornerRatio = 0.21;

void main() {
  final decoded = img.decodeImage(File(source).readAsBytesSync());
  if (decoded == null) throw StateError('cannot decode $source');
  final w = decoded.width, h = decoded.height;
  // Tile colour, sampled inside the tile's left edge at mid height.
  final fill = decoded.getPixel((w * 0.06).round(), h ~/ 2);
  final r = w * cornerRatio;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final cx = x < r ? r : (x > w - r ? w - r : x.toDouble());
      final cy = y < r ? r : (y > h - r ? h - r : y.toDouble());
      if (math.sqrt(math.pow(x - cx, 2) + math.pow(y - cy, 2)) > r - 2) {
        decoded.setPixel(x, y, fill);
      }
    }
  }
  final resized = img.copyResize(decoded, width: size, height: size, interpolation: img.Interpolation.cubic);
  // RGB, no alpha: App Store icons must be opaque (the package default).
  final opaque = img.Image(width: size, height: size)
    ..clear(img.ColorRgb8(fill.r.toInt(), fill.g.toInt(), fill.b.toInt()));
  img.compositeImage(opaque, resized);
  File(target).writeAsBytesSync(img.encodePng(opaque));
  stdout.writeln('wrote $target');
}
