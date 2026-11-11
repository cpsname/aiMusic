import 'package:path/path.dart' as p;

import '../core/errors.dart';
import '../core/fields.dart';

/// An App Store placement for creative assets (defaults/creative.yaml
/// `placements`).
class CreativePlacement {
  const CreativePlacement({required this.id, required this.asc, required this.typePrefix, this.manifestTypes = const {}});

  /// The contract's placement intent: `product_page_header`,
  /// `app_store_search_results`.
  final String id;

  /// App Store Connect's placement type.
  final String asc;

  /// `header` / `search`: the manifest type is `<prefix>_image` or
  /// `<prefix>_video`.
  final String typePrefix;
  final Map<String, String> manifestTypes;

  String typeFor(String media) => manifestTypes[media] ?? '${typePrefix}_$media';
}

/// The sizes a spec accepts: one exact size, or a range whose sizes hold the
/// aspect ratio exactly.
class SizeRule {
  const SizeRule.exact(int width, int height)
    : minWidth = width,
      maxWidth = width,
      minHeight = height,
      maxHeight = height,
      renderWidth = width,
      renderHeight = height;

  const SizeRule.range({
    required this.minWidth,
    required this.minHeight,
    required this.maxWidth,
    required this.maxHeight,
    required this.renderWidth,
    required this.renderHeight,
  });

  final int minWidth;
  final int maxWidth;
  final int minHeight;
  final int maxHeight;

  /// The size this tool renders at.
  final int renderWidth;
  final int renderHeight;

  bool get exact => minWidth == maxWidth && minHeight == maxHeight;

  /// Whether [width]×[height] is accepted for the nominal [aspect] (`a:b`).
  ///
  /// An exact size is matched pixel for pixel and nothing else: a fixed size
  /// need not equal its nominal ratio (3840×1646 is 2.3329…, 21:9 is
  /// 2.3333…), so a ratio test would refuse Apple's own size. A range size
  /// must lie in the range and hold the ratio exactly in integers
  /// (w·b = h·a): Apple states no tolerance, so none is assumed.
  bool fits(int width, int height, String aspect) {
    if (width < minWidth || width > maxWidth || height < minHeight || height > maxHeight) return false;
    if (exact) return true;
    final (a, b) = parseAspect(aspect);
    return width * b == height * a;
  }

  String describe(String aspect) => exact ? '$minWidth×$minHeight' : '$minWidth×$minHeight – $maxWidth×$maxHeight at exactly $aspect';
}

/// `21:9` → (21, 9).
(int, int) parseAspect(String aspect) {
  final m = RegExp(r'^(\d+):(\d+)$').firstMatch(aspect) ?? (throw ConfigError('aspect "$aspect" is not a:b'));
  return (int.parse(m.group(1)!), int.parse(m.group(2)!));
}

/// What one kind of file (image or video) of a spec must be.
class MediaRule {
  const MediaRule({required this.size, required this.extensions, this.fps = const [], this.minSeconds, this.maxSeconds});

  factory MediaRule.read(Fields f, {required bool video}) {
    f.only({
      'width',
      'height',
      'min',
      'max',
      'render',
      'extensions',
      if (video) ...{'fps', 'min_seconds', 'max_seconds'},
    });
    final SizeRule size;
    if (f.has('width')) {
      size = SizeRule.exact(f.integer('width'), f.integer('height'));
    } else {
      List<int> pair(String key) {
        final v = f.list(key);
        if (v.length != 2 || v.any((x) => x is! int)) throw ConfigError('${f.where} › $key: [width, height]');
        return v.cast<int>();
      }

      final min = pair('min');
      final max = pair('max');
      final render = pair('render');
      size = SizeRule.range(minWidth: min[0], minHeight: min[1], maxWidth: max[0], maxHeight: max[1], renderWidth: render[0], renderHeight: render[1]);
    }
    final extensions = f.strings('extensions');
    if (extensions.isEmpty || extensions.any((e) => !e.startsWith('.'))) throw ConfigError('${f.where} › extensions: [.png, …]');
    return MediaRule(
      size: size,
      extensions: extensions,
      fps: video ? [for (final v in f.list('fps')) v is int ? v : throw ConfigError('${f.where} › fps: whole numbers')] : const [],
      minSeconds: video ? f.number('min_seconds') : null,
      maxSeconds: video ? f.number('max_seconds') : null,
    );
  }

  final SizeRule size;

  /// Accepted extensions, lower case with the dot.
  final List<String> extensions;

  /// Accepted frame rates (exact).
  final List<int> fps;
  final double? minSeconds;
  final double? maxSeconds;
}

/// One creative asset spec (defaults/creative.yaml `specs`).
class CreativeSpec {
  const CreativeSpec({required this.id, required this.placements, required this.aspect, required this.image, required this.video});

  final String id;
  final List<String> placements;

  /// Apple's nominal ratio (`21:9`): the manifest's `aspect_ratio`.
  final String aspect;
  final MediaRule? image;
  final MediaRule? video;

  MediaRule? rule(String kind) => kind == 'video' ? video : image;
}

/// A composition's proportions (defaults/creative.yaml `layouts`).
class CreativeLayout {
  const CreativeLayout({
    this.axis = 'horizontal',
    required this.safeWidth,
    required this.safeHeight,
    required this.panelHeight,
    required this.panelCorner,
    required this.gap,
    required this.iconSize,
    required this.nameSize,
    required this.brandSpace,
    required this.textSize,
    required this.maxLines,
    required this.zoom,
    required this.blur,
    required this.brightness,
    required this.saturation,
    required this.shadowOpacity,
    required this.shadowBlur,
    required this.shadowOffset,
    required this.edgeWidth,
    required this.edgeOpacity,
  });

  factory CreativeLayout.read(Fields f) {
    f.only({'axis', 'safe', 'panel', 'gap', 'brand', 'text', 'backdrop', 'shadow'});
    final axis = f.optString('axis') ?? 'horizontal';
    if (!{'horizontal', 'vertical'}.contains(axis)) throw ConfigError('${f.where}: axis must be horizontal or vertical');
    final safe = f.map('safe')..only({'width', 'height'});
    final panel = f.map('panel')..only({'height', 'corner', 'edge'});
    final edge = panel.map('edge')..only({'width', 'opacity'});
    final brand = f.map('brand')..only({'icon', 'name', 'space'});
    final text = f.map('text')..only({'size', 'max_lines'});
    final backdrop = f.map('backdrop')..only({'zoom', 'blur', 'brightness', 'saturation'});
    final shadow = f.map('shadow')..only({'opacity', 'blur', 'offset'});
    double fraction(Fields m, String key) {
      final v = m.number(key);
      if (v <= 0 || v > 1) throw ConfigError('${m.where} › $key: a fraction in (0, 1]');
      return v;
    }

    return CreativeLayout(
      axis: axis,
      safeWidth: fraction(safe, 'width'),
      safeHeight: fraction(safe, 'height'),
      panelHeight: fraction(panel, 'height'),
      panelCorner: fraction(panel, 'corner'),
      gap: fraction(f, 'gap'),
      iconSize: fraction(brand, 'icon'),
      nameSize: fraction(brand, 'name'),
      brandSpace: fraction(brand, 'space'),
      textSize: fraction(text, 'size'),
      maxLines: text.integer('max_lines'),
      zoom: fraction(backdrop, 'zoom'),
      blur: fraction(backdrop, 'blur'),
      brightness: backdrop.number('brightness'),
      saturation: backdrop.number('saturation'),
      shadowOpacity: fraction(shadow, 'opacity'),
      shadowBlur: fraction(shadow, 'blur'),
      shadowOffset: fraction(shadow, 'offset'),
      edgeWidth: fraction(edge, 'width'),
      edgeOpacity: fraction(edge, 'opacity'),
    );
  }

  final String axis;
  final double safeWidth;
  final double safeHeight;
  final double panelHeight;
  final double panelCorner;
  final double gap;
  final double iconSize;
  final double nameSize;
  final double brandSpace;
  final double textSize;
  final int maxLines;
  final double zoom;
  final double blur;
  final double brightness;
  final double saturation;
  final double shadowOpacity;
  final double shadowBlur;
  final double shadowOffset;

  /// A hairline round the panel (of the canvas height) and its opacity.
  final double edgeWidth;
  final double edgeOpacity;

  /// This layout as an app tightens it (app.yaml `creatives.layouts.<aspect>`):
  /// a smaller safe area, a smaller phrase, fewer lines, a darker backdrop —
  /// never the other way, so an app cannot loosen what the defaults hold.
  CreativeLayout tightened(Fields f) {
    f.only({'safe', 'text', 'backdrop'});
    final safe = f.optMap('safe')?..only({'width', 'height'});
    final text = f.optMap('text')?..only({'size', 'max_lines'});
    final backdrop = f.optMap('backdrop')?..only({'brightness'});
    T tighter<T extends num>(Fields? m, String key, T current, T Function(Fields, String) read, {required bool lower}) {
      if (m == null || !m.has(key)) return current;
      final v = read(m, key);
      final ok = lower ? v <= current && v > 0 : v <= current;
      if (!ok) throw ConfigError('${m.where} › $key: $v loosens the default $current (an app may only tighten a layout)');
      return v;
    }

    return CreativeLayout(
      axis: axis,
      safeWidth: tighter(safe, 'width', safeWidth, (m, k) => m.number(k), lower: true),
      safeHeight: tighter(safe, 'height', safeHeight, (m, k) => m.number(k), lower: true),
      panelHeight: panelHeight,
      panelCorner: panelCorner,
      gap: gap,
      iconSize: iconSize,
      nameSize: nameSize,
      brandSpace: brandSpace,
      textSize: tighter(text, 'size', textSize, (m, k) => m.number(k), lower: true),
      maxLines: tighter(text, 'max_lines', maxLines, (m, k) => m.integer(k), lower: true),
      zoom: zoom,
      blur: blur,
      brightness: tighter(backdrop, 'brightness', brightness, (m, k) => m.number(k), lower: false),
      saturation: saturation,
      shadowOpacity: shadowOpacity,
      shadowBlur: shadowBlur,
      shadowOffset: shadowOffset,
      edgeWidth: edgeWidth,
      edgeOpacity: edgeOpacity,
    );
  }
}

/// The creative video encode and transitions (defaults/creative.yaml
/// `encoding`).
class CreativeEncoding {
  const CreativeEncoding({
    required this.profile,
    required this.level,
    required this.crf,
    required this.maxBitrate,
    required this.preset,
    required this.fps,
    required this.gopSeconds,
    required this.sceneDissolve,
    required this.loopDissolve,
  });

  factory CreativeEncoding.read(Fields f) {
    f.only({'video', 'scene_dissolve', 'loop_dissolve'});
    final v = f.map('video')..only({'profile', 'level', 'crf', 'max_bitrate', 'preset', 'fps', 'gop_seconds'});
    return CreativeEncoding(
      profile: v.string('profile'),
      level: v.string('level'),
      crf: v.integer('crf'),
      maxBitrate: v.integer('max_bitrate'),
      preset: v.string('preset'),
      fps: v.integer('fps'),
      gopSeconds: v.integer('gop_seconds'),
      sceneDissolve: f.number('scene_dissolve'),
      loopDissolve: f.number('loop_dissolve'),
    );
  }

  final String profile;
  final String level;
  final int crf;
  final int maxBitrate;
  final String preset;
  final int fps;
  final int gopSeconds;
  final double sceneDissolve;
  final double loopDissolve;
}

/// The thresholds measured on every rendered creative.
class CreativeChecks {
  const CreativeChecks({required this.minContrastMean, required this.minContrastP90, required this.minLoopPsnr});

  final double minContrastMean;
  final double minContrastP90;
  final double minLoopPsnr;
}

/// defaults/creative.yaml.
class CreativeDefaults {
  const CreativeDefaults({
    required this.placements,
    required this.specs,
    required this.layouts,
    required this.maxBytes,
    required this.videoCodecs,
    required this.encoding,
    required this.checks,
    required this.ascLocales,
  });

  factory CreativeDefaults.read(Fields f) {
    f.only({'placements', 'specs', 'asc_locales', 'limits', 'layouts', 'encoding', 'checks'});
    final placementsField = f.map('placements');
    final placements = <String, CreativePlacement>{
      for (final id in placementsField.raw.keys)
        id: () {
          final m = placementsField.map(id)..only({'asc', 'type_prefix', 'manifest_types'});
          final types = m.optMap('manifest_types')?..only({'image', 'video'});
          return CreativePlacement(
            id: id,
            asc: m.string('asc'),
            typePrefix: m.optString('type_prefix') ?? '',
            manifestTypes: {for (final k in types?.raw.keys ?? const <String>[]) k: types!.string(k)},
          );
        }(),
    };
    final specsField = f.map('specs');
    final specs = <String, CreativeSpec>{};
    for (final id in specsField.raw.keys) {
      final s = specsField.map(id)..only({'placements', 'aspect', 'image', 'video'});
      final ps = s.strings('placements');
      for (final pl in ps) {
        if (!placements.containsKey(pl)) throw ConfigError('${s.where} › placements: unknown placement $pl');
      }
      final aspect = s.string('aspect');
      parseAspect(aspect);
      specs[id] = CreativeSpec(
        id: id,
        placements: ps,
        aspect: aspect,
        image: s.has('image') ? MediaRule.read(s.map('image'), video: false) : null,
        video: s.has('video') ? MediaRule.read(s.map('video'), video: true) : null,
      );
    }
    final limits = f.map('limits')..only({'max_bytes', 'video_codecs'});
    final layoutsField = f.map('layouts');
    final checks = f.map('checks')..only({'min_contrast_mean', 'min_contrast_p90', 'min_loop_psnr'});
    final layouts = {for (final a in layoutsField.raw.keys) a: CreativeLayout.read(layoutsField.map(a))};
    for (final s in specs.values) {
      if (!layouts.containsKey(s.aspect)) throw ConfigError('${f.where} › layouts: no layout for ${s.aspect} (spec ${s.id})');
    }
    return CreativeDefaults(
      placements: placements,
      specs: specs,
      layouts: layouts,
      maxBytes: limits.integer('max_bytes'),
      videoCodecs: limits.strings('video_codecs'),
      encoding: CreativeEncoding.read(f.map('encoding')),
      checks: CreativeChecks(
        minContrastMean: checks.number('min_contrast_mean'),
        minContrastP90: checks.number('min_contrast_p90'),
        minLoopPsnr: checks.number('min_loop_psnr'),
      ),
      ascLocales: f.strings('asc_locales'),
    );
  }

  final Map<String, CreativePlacement> placements;
  final Map<String, CreativeSpec> specs;

  /// aspect → layout.
  final Map<String, CreativeLayout> layouts;
  final int maxBytes;
  final List<String> videoCodecs;
  final CreativeEncoding encoding;
  final CreativeChecks checks;

  /// App Store Connect's localizations: a per-storefront asset's locale is
  /// one of them.
  final List<String> ascLocales;

  /// These defaults with an app's tightened layouts ([tightenings]: aspect →
  /// app.yaml `creatives.layouts.<aspect>`).
  CreativeDefaults forApp(Map<String, Fields> tightenings) {
    if (tightenings.isEmpty) return this;
    final next = {...layouts};
    for (final MapEntry(key: aspect, value: f) in tightenings.entries) {
      final base = layouts[aspect] ?? (throw ConfigError('${f.where}: no layout for $aspect (${layouts.keys.join(', ')})'));
      next[aspect] = base.tightened(f);
    }
    return CreativeDefaults(
      placements: placements,
      specs: specs,
      layouts: next,
      maxBytes: maxBytes,
      videoCodecs: videoCodecs,
      encoding: encoding,
      checks: checks,
      ascLocales: ascLocales,
    );
  }
}

CreativeDefaults loadCreativeDefaults(String packageRoot) => CreativeDefaults.read(readYamlFile(p.join(packageRoot, 'defaults', 'creative.yaml')));
