// Generates the Songlet app icon (ADR-0014) — every size the AppIcon set
// needs — from one vector drawing, so the mark stays crisp at 20 pt and at
// 1024 pt without shipping a raster master.
//
// The concept: *a song is a small record in a sleeve.* A vermilion plate, a
// cream sleeve spine down the leading edge, and the disc sliding out of it with
// its label and grooves. No note, no play triangle, no equaliser, no gradient —
// the metaphors every music app already uses.
//
//   dart run tool/assets/app_icon.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Design grid (the drawing is described in these units).
const int _grid = 1024;

/// Palette — kept in step with `SongletPalette` (packages/ui_kit).
const int _plateR = 0xC9, _plateG = 0x3C, _plateB = 0x17; // vermilion
const int _creamR = 0xFF, _creamG = 0xF6, _creamB = 0xEC; // cream
const int _grooveR = 0xE8, _grooveG = 0x9C, _grooveB = 0x7C; // grooved cream
const int _labelInkR = 0x7A, _labelInkG = 0x24, _labelInkB = 0x0E;

/// Every file the AppIcon set declares, with its pixel size.
const Map<String, int> _targets = {
  'Icon-App-20x20@1x.png': 20,
  'Icon-App-20x20@2x.png': 40,
  'Icon-App-20x20@3x.png': 60,
  'Icon-App-29x29@1x.png': 29,
  'Icon-App-29x29@2x.png': 58,
  'Icon-App-29x29@3x.png': 87,
  'Icon-App-40x40@1x.png': 40,
  'Icon-App-40x40@2x.png': 80,
  'Icon-App-40x40@3x.png': 120,
  'Icon-App-60x60@2x.png': 120,
  'Icon-App-60x60@3x.png': 180,
  'Icon-App-76x76@1x.png': 76,
  'Icon-App-76x76@2x.png': 152,
  'Icon-App-83.5x83.5@2x.png': 167,
  'Icon-App-1024x1024@1x.png': 1024,
};

const String _dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

img.Color _rgb(int r, int g, int b) => img.ColorRgb8(r, g, b);

void main() {
  final master = _draw();
  for (final entry in _targets.entries) {
    final size = entry.value;
    final img.Image out = size == _grid
        ? master
        : img.copyResize(
            master,
            width: size,
            height: size,
            interpolation: img.Interpolation.cubic,
          );
    // Opaque RGB: the App Store rejects icons with an alpha channel.
    final opaque = img.Image(width: size, height: size)
      ..clear(_rgb(_plateR, _plateG, _plateB));
    img.compositeImage(opaque, out);
    final path = '$_dir/${entry.key}';
    File(path).writeAsBytesSync(img.encodePng(opaque));
    stdout.writeln('wrote $path ($size×$size)');
  }
}

/// Draws the mark on the 1024 grid.
img.Image _draw() {
  final image = img.Image(width: _grid, height: _grid)
    ..clear(_rgb(_plateR, _plateG, _plateB));

  final cream = _rgb(_creamR, _creamG, _creamB);
  final groove = _rgb(_grooveR, _grooveG, _grooveB);

  // The sleeve: a cream spine down the leading edge, with a printed rule.
  const spineRight = 190;
  img.fillRect(
    image,
    x1: 0,
    y1: 0,
    x2: spineRight,
    y2: _grid - 1,
    color: cream,
  );

  // The disc, sliding out of the sleeve: it overlaps the spine by a hair, so
  // the two shapes read as one object rather than as a bar and a circle.
  const cx = 528, cy = 512, disc = 322;
  img.fillCircle(image, x: cx, y: cy, radius: disc, color: cream, antialias: true);

  // One groove, quiet: enough to say "record", not enough to speckle at 40 pt.
  img.drawCircle(
    image,
    x: cx,
    y: cy,
    radius: 268,
    color: groove,
    antialias: true,
  );

  // The label and its spindle hole — the plate colour again, so the icon is
  // two inks on one stock and nothing else.
  img.fillCircle(
    image,
    x: cx,
    y: cy,
    radius: 112,
    color: _rgb(_plateR, _plateG, _plateB),
    antialias: true,
  );
  img.fillCircle(image, x: cx, y: cy, radius: 22, color: cream, antialias: true);

  // A single sound line on the spine: the only gesture on the plate, and the
  // thing that says "song" rather than "record".
  final wave = _rgb(_plateR, _plateG, _plateB);
  const waveLeft = 26.0, waveRight = 168.0, waveMid = 512.0, waveHeight = 74.0;
  for (var x = waveLeft; x <= waveRight; x += 2) {
    final phase = (x - waveLeft) / (waveRight - waveLeft) * 2 * math.pi * 1.15;
    final y = waveMid + waveHeight * math.sin(phase);
    img.fillCircle(
      image,
      x: x.round(),
      y: y.round(),
      radius: 15,
      color: wave,
      antialias: true,
    );
  }

  return image;
}
