import 'dart:convert';
import 'dart:io';

import '../config/app.dart';
import '../core/errors.dart';
import '../post/layers.dart';
import 'specs.dart';

/// A rectangle from the canvas's top left, in pixels.
class Box {
  const Box(this.x, this.y, this.w, this.h);

  factory Box.fromJson(Object? v) {
    if (v is! List || v.length != 4) throw ConfigError('not a box: $v');
    return Box((v[0] as num).toDouble(), (v[1] as num).toDouble(), (v[2] as num).toDouble(), (v[3] as num).toDouble());
  }

  final double x;
  final double y;
  final double w;
  final double h;

  double get right => x + w;
  double get bottom => y + h;

  /// Whether this box lies inside [outer] (to half a pixel).
  bool inside(Box outer) => x >= outer.x - 0.5 && y >= outer.y - 0.5 && right <= outer.right + 0.5 && bottom <= outer.bottom + 0.5;

  List<double> toJson() => [x, y, w, h];

  @override
  String toString() => '${x.round()},${y.round()} ${w.round()}×${h.round()}';
}

/// Right-to-left UI languages: the panel goes to the right, the text block to
/// its left.
const Set<String> rtlLanguages = {'ar', 'he', 'fa', 'ur'};

String directionOf(Storefront? storefront) => storefront != null && rtlLanguages.contains(storefront.uiLocale.split(RegExp('[-_]')).first) ? 'rtl' : 'ltr';

/// The composition the renderer is asked for: the canvas, the safe area, the
/// panel's size and the type sizes, all from the layout's proportions.
class CompositionPlan {
  CompositionPlan({required this.width, required this.height, required this.layout, required this.sourceWidth, required this.sourceHeight});

  final int width;
  final int height;
  final CreativeLayout layout;

  /// The recording's size (the panel shows it scaled down, never up).
  final int sourceWidth;
  final int sourceHeight;

  double _h(double fraction) => (height * fraction).roundToDouble();

  Box get safe {
    final w = (width * layout.safeWidth).roundToDouble();
    final h = (height * layout.safeHeight).roundToDouble();
    return Box(((width - w) / 2).roundToDouble(), ((height - h) / 2).roundToDouble(), w, h);
  }

  /// The panel: the safe area's height (× panel.height), the recording's
  /// aspect; both even (yuv420p).
  ({int w, int h}) get panel {
    final h = (safe.h * layout.panelHeight / 2).floor() * 2;
    final w = (h * sourceWidth / sourceHeight / 2).round() * 2;
    return (w: w, h: h);
  }

  /// Footage scale into the panel (≤ 1: a recording is never enlarged).
  double get scale => panel.h / sourceHeight;

  /// The render_text item that draws the layers and decides the positions.
  Map<String, Object?> textItem({
    required Brand brand,
    required String icon,
    required String root,
    required String? phrase,
    required String direction,
    required String out,
    required String maskOut,
    required String shadowOut,
    required String layoutOut,
  }) {
    final pnl = panel;
    return {
      'kind': 'creative',
      'axis': layout.axis,
      'out': out,
      'mask_out': maskOut,
      'shadow_out': shadowOut,
      'layout_out': layoutOut,
      'width': width,
      'height': height,
      'safe': safe.toJson(),
      'panel_size': [pnl.w, pnl.h],
      'panel_radius': (pnl.w * layout.panelCorner).roundToDouble(),
      'gap': _h(layout.gap),
      'direction': direction,
      'icon': icon,
      'icon_size': _h(layout.iconSize),
      'brand_name': brand.name,
      'name_size': _h(layout.nameSize),
      'brand_space': _h(layout.brandSpace),
      'phrase': phrase,
      'text_size': _h(layout.textSize),
      'max_lines': layout.maxLines,
      'color': brand.onPrimary,
      'shadow_color': brand.scrim,
      'shadow_opacity': layout.shadowOpacity,
      'shadow_blur': _h(layout.shadowBlur),
      'shadow_offset': _h(layout.shadowOffset),
      'stroke_width': (height * layout.edgeWidth).clamp(1.0, 64.0).roundToDouble(),
      'stroke_opacity': layout.edgeOpacity,
      'font': fontSpec(brand, root),
    };
  }
}

/// Where the renderer put everything (render_text's `layout_out`).
class Composition {
  const Composition({
    required this.safe,
    required this.panel,
    required this.block,
    required this.brand,
    required this.text,
    required this.lines,
    required this.scale,
    required this.direction,
  });

  factory Composition.read(String path, {required Box safe, required double scale, required String direction}) {
    final j = jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
    return Composition(
      safe: safe,
      panel: Box.fromJson(j['panel']),
      block: Box.fromJson(j['block']),
      brand: Box.fromJson(j['brand']),
      text: j['text'] == null ? null : Box.fromJson(j['text']),
      lines: (j['lines'] as num).toInt(),
      scale: scale,
      direction: direction,
    );
  }

  factory Composition.fromJson(Map<String, Object?> j) => Composition(
    safe: Box.fromJson(j['safe']),
    panel: Box.fromJson(j['panel']),
    block: Box.fromJson(j['block']),
    brand: Box.fromJson(j['brand']),
    text: j['text'] == null ? null : Box.fromJson(j['text']),
    lines: (j['lines'] as num).toInt(),
    scale: (j['panel_scale'] as num).toDouble(),
    direction: '${j['direction']}',
  );

  final Box safe;
  final Box panel;
  final Box block;
  final Box brand;
  final Box? text;
  final int lines;

  /// The footage's scale into the panel.
  final double scale;
  final String direction;

  Map<String, Object?> toJson() => {
    'safe': safe.toJson(),
    'panel': panel.toJson(),
    'block': block.toJson(),
    'brand': brand.toJson(),
    'text': text?.toJson(),
    'lines': lines,
    'panel_scale': scale,
    'direction': direction,
  };

  /// Every key element inside the safe area, the footage never enlarged.
  List<String> problems() => [
    if (!panel.inside(safe)) 'the panel ($panel) leaves the safe area ($safe)',
    if (!block.inside(safe)) 'the text block ($block) leaves the safe area ($safe)',
    if (scale > 1 + 1e-9) 'the footage is enlarged ×${scale.toStringAsFixed(3)} (a recording is only scaled down)',
  ];
}
