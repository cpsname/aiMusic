import '../config/app.dart';
import '../config/defaults.dart';

/// The type and colours text layers are drawn with (native/render_text.swift).
Map<String, Object?> fontSpec(Brand brand, String root) => {
  'family': brand.fontFamily,
  'weight': brand.fontWeight,
  'file': brand.fontFile == null ? null : '$root/${brand.fontFile}',
};

/// A caption plate: white text on the brand's scrim colour at [opacity].
Map<String, Object?> captionLayer({
  required String text,
  required String out,
  required DeviceSlot slot,
  required Brand brand,
  required double opacity,
  required double radius,
  required String root,
}) => {
  'kind': 'caption',
  'text': text,
  'out': out,
  'width': slot.width,
  'font_size': slot.captionSize,
  'color': brand.onPrimary,
  'plate': brand.scrim,
  'plate_opacity': opacity,
  'radius': radius,
  'font': fontSpec(brand, root),
};

/// A card's foreground on a transparent full frame: the icon, then its
/// lines; the [footnote] near the bottom, above the home indicator.
Map<String, Object?> cardLayer({
  required String out,
  required DeviceSlot slot,
  required Brand brand,
  required String icon,
  required List<({String text, double size, String weight})> lines,
  required String? footnote,
  required String root,
}) {
  final unit = slot.width / 886;
  return {
    'kind': 'card',
    'out': out,
    'width': slot.width,
    'height': slot.height,
    'icon': icon,
    'icon_size': (220 * unit).round(),
    'icon_center_y': (slot.height * 0.36).round(),
    'gap': (64 * unit).round(),
    'text_width': (slot.width * 0.82).round(),
    'color': brand.onPrimary,
    'lines': [
      for (final l in lines) {'text': l.text, 'size': l.size * unit, 'weight': l.weight},
    ],
    'footnote': footnote == null ? null : {'text': footnote, 'size': 28 * unit, 'bottom': slot.captionBottom + (24 * unit).round()},
    'font': fontSpec(brand, root),
  };
}
