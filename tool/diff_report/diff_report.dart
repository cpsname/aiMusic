// Prototype fidelity report (ADR-0007): docs/ui/P*.png vs the app rendered at
// the same 393×852 pt design size (test/pages/design_capture_test.dart).
//
//   make diff-report      (captures, then runs this)
//
// Writes docs/ui/diff-report.md and docs/ui/diff/<page>.jpg
// (prototype | app | 50 % overlay). Exits non-zero when a scored metric fails.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

import 'color.dart';

/// Design canvas in points and the working scale (the capture's 2×).
const double designWidth = 393;
const double designHeight = 852;
const int scale = 2;

/// ADR-0007 thresholds.
const double maxDeltaE = 2;
const double maxGeometryPt = 2;

/// A token counts as "used by a page" when a prominent prototype colour lies
/// within this ΔE of it; beyond, the page simply does not show that role.
const double presenceDeltaE = 10;

/// A colour is "prominent" from this share of the canvas (flat fills, not
/// anti-aliasing or photo noise).
const double prominentShare = 0.002;

/// Primary call to action: a wide accent pill.
const double ctaMinWidthPt = 200;
const double ctaMinHeightPt = 36;
const double ctaMaxHeightPt = 72;
const double ctaAccentDeltaE = 15;

/// Content gutter: first non-canvas column, measured over the middle band.
const double gutterCanvasDeltaE = 4;
const double gutterMaxPt = 60;

/// `tool/diff_report/config.json`: sampled roles, exemptions and waivers,
/// each with its reason.
late final Map<String, dynamic> config;

/// iOS system chrome drawn in the prototypes (status bar, home indicator),
/// excluded from every measurement.
double get chromeTop => ((config['systemChromePt'] as Map)['top'] as num).toDouble();
double get chromeBottom => ((config['systemChromePt'] as Map)['bottom'] as num).toDouble();

void main(List<String> args) {
  final root = Directory.current.path;
  config = jsonDecode(File('$root/tool/diff_report/config.json').readAsStringSync()) as Map<String, dynamic>;
  final allTokens = (jsonDecode(File('$root/build/diff_report/tokens.json').readAsStringSync()) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v as String));
  final tokens = {for (final t in config['sampledTokens'] as List) t as String: allTokens[t]!};
  final captured = Directory('$root/build/diff_report/actual')
      .listSync()
      .whereType<File>()
      .map((f) => f.uri.pathSegments.last.replaceAll('.png', ''))
      .toList();
  final pages = captured.where((id) => File('$root/docs/ui/$id.png').existsSync()).toList()..sort(_pageOrder);
  // Pages specified without a prototype (P19–P30, ADR-0027): captured for
  // review, not scored until their prototypes exist.
  final unscored = captured.where((id) => !pages.contains(id)).toList()..sort(_pageOrder);
  for (final id in unscored) {
    File('$root/build/diff_report/actual/$id.png').copySync('$root/docs/ui/diff/$id.png');
  }
  Directory('$root/docs/ui/diff').createSync(recursive: true);

  final results = <PageResult>[];
  for (final id in pages) {
    final proto = _normalise(img.decodePng(File('$root/docs/ui/$id.png').readAsBytesSync())!);
    final actual = _normalise(img.decodePng(File('$root/build/diff_report/actual/$id.png').readAsBytesSync())!);
    results.add(
      PageResult(
        id: id,
        tokenDeltas: _tokenDeltas(proto, tokens),
        cta: (proto: _cta(proto, tokens['accent']!), app: _cta(actual, tokens['accent']!)),
        gutter: (proto: _gutter(proto, tokens['canvas']!), app: _gutter(actual, tokens['canvas']!)),
      ),
    );
    File('$root/docs/ui/diff/$id.jpg').writeAsBytesSync(img.encodeJpg(_review(proto, actual), quality: 78));
    stdout.writeln('· $id');
  }

  final report = _markdown(results, tokens, allTokens, unscored: unscored);
  File('$root/docs/ui/diff-report.md').writeAsStringSync(report.text);
  stdout.writeln(
    report.passed ? '✓ diff report: all scored metrics within threshold' : '✗ diff report: see docs/ui/diff-report.md',
  );
  exitCode = report.passed ? 0 : 1;
}

int _pageOrder(String a, String b) {
  int n(String s) => int.parse(RegExp(r'\d+').firstMatch(s)!.group(0)!);
  return n(a) != n(b) ? n(a) - n(b) : a.compareTo(b);
}

/// Scales to the 393-pt design width at [scale]× and keeps the first screen
/// (tall prototypes are scroll captures).
img.Image _normalise(img.Image source) {
  final width = (designWidth * scale).round();
  final resized = source.width == width
      ? source
      : img.copyResize(source, width: width, interpolation: img.Interpolation.average);
  final height = (designHeight * scale).round();
  if (resized.height == height) return resized;
  final canvas = img.Image(width: width, height: height);
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(canvas, resized);
  return canvas;
}

// ── colour tokens ──────────────────────────────────────────────────────────

/// The nearest prominent colour of a page to a token.
typedef TokenMatch = ({double d, String hex});

/// For every token, the nearest prominent colour of [image] and its ΔE2000,
/// or null when the page does not show that role.
Map<String, TokenMatch?> _tokenDeltas(img.Image image, Map<String, String> tokens) {
  final buckets = <int, ({int n, int r, int g, int b})>{};
  final top = (chromeTop * scale).round(), bottom = image.height - (chromeBottom * scale).round();
  for (final p in image) {
    if (p.y < top || p.y >= bottom) continue;
    final key = (p.r.toInt() >> 3) << 10 | (p.g.toInt() >> 3) << 5 | (p.b.toInt() >> 3);
    final s = buckets[key];
    buckets[key] = s == null
        ? (n: 1, r: p.r.toInt(), g: p.g.toInt(), b: p.b.toInt())
        : (n: s.n + 1, r: s.r + p.r.toInt(), g: s.g + p.g.toInt(), b: s.b + p.b.toInt());
  }
  final total = image.width * (bottom - top);
  String hex(int r, int g, int b) => '#${[r, g, b].map((v) => v.toRadixString(16).padLeft(2, '0')).join()}';
  final prominent = [
    for (final s in buckets.values)
      if (s.n / total >= prominentShare)
        (lab: labOf(s.r ~/ s.n, s.g ~/ s.n, s.b ~/ s.n), hex: hex(s.r ~/ s.n, s.g ~/ s.n, s.b ~/ s.n)),
  ];
  return {
    for (final MapEntry(:key, :value) in tokens.entries)
      key: () {
        final target = labOfHex(value);
        TokenMatch? best;
        for (final c in prominent) {
          final d = deltaE2000(target, c.lab);
          if (d <= presenceDeltaE && (best == null || d < best.d)) best = (d: d, hex: c.hex);
        }
        return best;
      }(),
  };
}

// ── geometry ───────────────────────────────────────────────────────────────

/// A box in design points.
typedef Box = ({double x, double y, double w, double h});

/// The primary call to action: the widest accent pill, found as the largest
/// connected accent region with pill proportions.
Box? _cta(img.Image image, String accentHex) {
  final accent = labOfHex(accentHex);
  final w = designWidth.round(), h = designHeight.round();
  // Work at 1 pt resolution: one sample per point.
  final mask = List<bool>.generate(w * h, (i) {
    final y = i ~/ w;
    if (y < chromeTop || y >= h - chromeBottom) return false;
    final p = image.getPixel((i % w) * scale + scale ~/ 2, (i ~/ w) * scale + scale ~/ 2);
    return deltaE2000(accent, labOf(p.r.toInt(), p.g.toInt(), p.b.toInt())) <= ctaAccentDeltaE;
  });
  final seen = List<bool>.filled(w * h, false);
  Box? best;
  for (var start = 0; start < w * h; start++) {
    if (!mask[start] || seen[start]) continue;
    var minX = w, minY = h, maxX = 0, maxY = 0;
    final stack = [start];
    seen[start] = true;
    while (stack.isNotEmpty) {
      final i = stack.removeLast();
      final x = i % w, y = i ~/ w;
      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
      for (final n in [if (x > 0) i - 1, if (x < w - 1) i + 1, if (y > 0) i - w, if (y < h - 1) i + w]) {
        if (mask[n] && !seen[n]) {
          seen[n] = true;
          stack.add(n);
        }
      }
    }
    final box = (
      x: minX.toDouble(),
      y: minY.toDouble(),
      w: (maxX - minX + 1).toDouble(),
      h: (maxY - minY + 1).toDouble(),
    );
    final pill = box.w >= ctaMinWidthPt && box.h >= ctaMinHeightPt && box.h <= ctaMaxHeightPt;
    if (pill && (best == null || box.w * box.h > best.w * best.h)) best = box;
  }
  return best;
}

/// The content gutter: the most common first non-canvas column over the
/// middle third of the screen (cards, fields and images start there).
double? _gutter(img.Image image, String canvasHex) {
  final canvas = labOfHex(canvasHex);
  final counts = <int, int>{};
  final top = (designHeight / 3).round(), bottom = (designHeight * 2 / 3).round();
  for (var y = top; y < bottom; y++) {
    for (var x = 0; x < gutterMaxPt; x++) {
      final p = image.getPixel(x * scale + scale ~/ 2, y * scale + scale ~/ 2);
      if (deltaE2000(canvas, labOf(p.r.toInt(), p.g.toInt(), p.b.toInt())) > gutterCanvasDeltaE) {
        counts[x] = (counts[x] ?? 0) + 1;
        break;
      }
    }
  }
  if (counts.isEmpty) return null;
  final mode = counts.entries.reduce((a, b) => b.value > a.value ? b : a);
  // A gutter is a consistent edge: most measured rows agree on it.
  return mode.value >= (bottom - top) / 4 ? mode.key.toDouble() : null;
}

// ── review image ───────────────────────────────────────────────────────────

/// Prototype | app | 50 % overlay, at 1×.
img.Image _review(img.Image proto, img.Image actual) {
  final w = designWidth.round(), h = designHeight.round();
  final p = img.copyResize(proto, width: w, height: h, interpolation: img.Interpolation.average);
  final a = img.copyResize(actual, width: w, height: h, interpolation: img.Interpolation.average);
  final overlay = img.Image.from(p);
  for (final px in overlay) {
    final q = a.getPixel(px.x, px.y);
    px
      ..r = (px.r + q.r) / 2
      ..g = (px.g + q.g) / 2
      ..b = (px.b + q.b) / 2;
  }
  final out = img.Image(width: w * 3, height: h);
  img.compositeImage(out, p);
  img.compositeImage(out, a, dstX: w);
  img.compositeImage(out, overlay, dstX: w * 2);
  return out;
}

// ── report ─────────────────────────────────────────────────────────────────

class PageResult {
  PageResult({required this.id, required this.tokenDeltas, required this.cta, required this.gutter});

  final String id;
  final Map<String, TokenMatch?> tokenDeltas;
  final ({Box? proto, Box? app}) cta;
  final ({double? proto, double? app}) gutter;

  /// CTA height / width / inset deltas, when both sides have one.
  ({double h, double w, double x})? get ctaDelta {
    final p = cta.proto, a = cta.app;
    if (p == null || a == null) return null;
    return (h: (a.h - p.h).abs(), w: (a.w - p.w).abs(), x: (a.x - p.x).abs());
  }

  double? get gutterDelta {
    final p = gutter.proto, a = gutter.app;
    return p == null || a == null ? null : (a - p).abs();
  }
}

({String text, bool passed}) _markdown(
  List<PageResult> results,
  Map<String, String> tokens,
  Map<String, String> allTokens, {
  List<String> unscored = const [],
}) {
  final spec = (config['specTokens'] as Map<String, dynamic>)..remove('_doc');
  final unsampled = (config['unsampledTokens'] as Map<String, dynamic>).cast<String, String>();
  final notes = (config['tokenNotes'] as Map<String, dynamic>).cast<String, String>();
  final waivers = (config['geometryWaivers'] as Map<String, dynamic>).cast<String, String>();
  final pageWaivers = {
    for (final MapEntry(:key, :value) in (config['pageWaivers'] as Map<String, dynamic>).entries)
      if (!key.startsWith('_')) key: (value as Map<String, dynamic>).cast<String, String>(),
  };
  String n(double? v) => v == null ? '—' : v.toStringAsFixed(1);
  String e(double v) => v.toStringAsFixed(2);
  final open = <String>[];
  String mark(bool ok) => ok ? '✅' : '❌';
  var passed = true;
  final b = StringBuffer()
    ..writeln('# Prototype diff report')
    ..writeln()
    ..writeln('Generated by `tool/diff_report` (`make diff-report`) — method and thresholds in')
    ..writeln('[ADR-0007](../adr/0007-prototype-diff-method.md). The app is rendered at the')
    ..writeln('prototypes\' 393×852 pt canvas (light, reduce-motion, SF Pro) by')
    ..writeln('`test/pages/design_capture_test.dart`; the prototypes are `docs/ui/P*.png`.')
    ..writeln()
    ..writeln('## 1. Colour tokens (ΔE2000 ≤ $maxDeltaE)')
    ..writeln()
    ..writeln(
      'For each token, the nearest prominent colour (≥ ${(prominentShare * 100).toStringAsFixed(1)} % of the screen) of every',
    )
    ..writeln('prototype that shows the role (within ΔE $presenceDeltaE), outside the iOS status bar and home')
    ..writeln('indicator. Scored on the median over those pages; the worst page is listed for review.')
    ..writeln('Tokens whose value the phase-1 spec fixes keep the spec value when a prototype raster')
    ..writeln('disagrees (📌 = reported, not changed).')
    ..writeln()
    ..writeln('| Token | Value | Prototype (median page) | Pages | Median ΔE | Worst ΔE (page) | |')
    ..writeln('| --- | --- | --- | ---: | ---: | --- | --- |');
  for (final MapEntry(key: token, value: hex) in tokens.entries) {
    final hits = [
      for (final r in results)
        if (r.tokenDeltas[token] case final m?) (page: r.id, d: m.d, hex: m.hex),
    ]..sort((a, b) => a.d.compareTo(b.d));
    if (hits.isEmpty) {
      b.writeln('| `$token` | `$hex` | — | 0 | — | — | not shown in the prototypes |');
      continue;
    }
    final median = hits[hits.length ~/ 2];
    final worst = hits.last;
    final ok = median.d <= maxDeltaE;
    final pinned = !ok && spec.containsKey(token);
    passed &= ok || pinned;
    if (!ok && !pinned) open.add('`$token` median ΔE ${e(median.d)}');
    b.writeln(
      '| `$token` | `$hex` | `${median.hex}` (${median.page}) | ${hits.length} | ${e(median.d)} | '
      '${e(worst.d)} (${worst.page}) | ${pinned ? '📌 spec value' : mark(ok)} |',
    );
  }

  b
    ..writeln()
    ..writeln([for (final MapEntry(:key, :value) in notes.entries) '\n**`$key`:** $value.'].join('\n'))
    ..writeln()
    ..writeln('Not sampled (no flat area of that role in the prototypes):')
    ..writeln();
  for (final MapEntry(:key, :value) in unsampled.entries) {
    b.writeln('- `$key` (`${allTokens[key]}`) — $value.');
  }

  b
    ..writeln()
    ..writeln('## 2. Geometry (≤ $maxGeometryPt pt)')
    ..writeln()
    ..writeln('Measured the same way on both images: the primary call to action (the widest accent')
    ..writeln('pill: height, width, start inset) and the content gutter (first non-canvas column over')
    ..writeln('the middle third). "—" = not present on one side (no CTA on that screen, or a full-bleed')
    ..writeln('page without a gutter edge).')
    ..writeln()
    ..writeln('Waived (measured and shown, not scored):')
    ..writeln()
    ..writeln([for (final MapEntry(:key, :value) in waivers.entries) '- `$key` — $value.'].join('\n'))
    ..writeln(
      [
        for (final MapEntry(key: page, value: metrics) in pageWaivers.entries)
          for (final MapEntry(key: metric, value: reason) in metrics.entries) '- $page `$metric` — $reason.',
      ].join('\n'),
    )
    ..writeln()
    ..writeln('| Page | CTA h (proto → app) | CTA w | CTA inset | Gutter (proto → app) | | Review |')
    ..writeln('| --- | --- | --- | --- | --- | --- | --- |');
  for (final r in results) {
    final c = r.ctaDelta;
    final g = r.gutterDelta;
    final waived = {...waivers.keys, ...?pageWaivers[r.id]?.keys};
    bool within(String metric, double? delta) => waived.contains(metric) || delta == null || delta <= maxGeometryPt;
    final ok = within('ctaHeight', c?.h) && within('ctaWidth', c?.w) && within('ctaInset', c?.x) && within('gutter', g);
    passed &= ok;
    open.addAll([
      if (!within('ctaWidth', c?.w)) '${r.id} CTA width Δ${n(c!.w)} pt',
      if (!within('ctaInset', c?.x)) '${r.id} CTA inset Δ${n(c!.x)} pt',
      if (!within('gutter', g)) '${r.id} gutter Δ${n(g)} pt',
    ]);
    String pair(double? p, double? a, String metric) {
      if (p == null || a == null) return '—';
      final note = waived.contains(metric) && (a - p).abs() > maxGeometryPt ? ' (waived)' : '';
      return '${n(p)} → ${n(a)}$note';
    }

    b.writeln(
      '| ${r.id} | ${pair(r.cta.proto?.h, r.cta.app?.h, 'ctaHeight')} | ${pair(r.cta.proto?.w, r.cta.app?.w, 'ctaWidth')} | '
      '${pair(r.cta.proto?.x, r.cta.app?.x, 'ctaInset')} | ${pair(r.gutter.proto, r.gutter.app, 'gutter')} | '
      '${c == null && g == null ? '—' : mark(ok)} | [${r.id}](diff/${r.id}.jpg) |',
    );
  }

  b
    ..writeln()
    ..writeln('## 3. Visual review')
    ..writeln()
    ..writeln('Each `diff/<page>.jpg` is prototype | app | 50 % overlay at 1×. Art, copy and live')
    ..writeln('data differ by design (ADR-0007, ADR-0008) and are reviewed, not scored.')
    ..writeln()
    ..writeln();
  if (unscored.isNotEmpty) {
    b
      ..writeln('## 4. Pages without a prototype')
      ..writeln()
      ..writeln('Derived from PRD ch.15 and the component library ([ADR-0027](../adr/0027-mv-pages-without-prototypes.md));')
      ..writeln('each is captured as `diff/<page>.png` for review and is scored once `docs/ui/<page>.png` exists.')
      ..writeln()
      ..writeln(unscored.map((id) => '`$id`').join(' · '))
      ..writeln();
  }
  b.writeln(
    '**Result:** ${passed ? 'all scored metrics within threshold.' : '${open.length} open deviations — ${open.join('; ')}.'}',
  );
  return (text: b.toString(), passed: passed);
}
