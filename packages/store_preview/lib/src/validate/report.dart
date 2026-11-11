import '../core/errors.dart';
import 'spec.dart';

/// The three layers on one rendered preview.
class OutputReport {
  OutputReport({
    required this.storefront,
    required this.script,
    required this.slot,
    required this.spec,
    required this.compliance,
    required this.narrative,
    required this.footage,
    required this.poster,
  });

  final String storefront;
  final String script;
  final String slot;
  final SpecCheck spec;
  final Problems compliance;
  final Problems narrative;

  /// Footage share, e.g. `86.0%`.
  final String footage;
  final String poster;

  bool get ok => spec.ok && compliance.isEmpty && narrative.isEmpty;

  List<String> get failures => [
    for (final f in spec.failures) 'spec: $f',
    for (final f in compliance.items) 'compliance: $f',
    for (final f in narrative.items) 'narrative: $f',
  ];
}

/// A plain-text table of [reports], then every failure.
String reportTable(List<OutputReport> reports) {
  String mark(bool ok) => ok ? 'pass' : 'FAIL';
  final rows = <List<String>>[
    ['storefront', 'script', 'slot', 'resolution', 'duration', 'fps', 'video', 'audio', 'size', 'footage', 'poster', 'spec', 'compliance', 'narrative', 'result'],
    for (final r in reports)
      [
        r.storefront, r.script, r.slot, r.spec.resolution, r.spec.duration, r.spec.fps, r.spec.video, r.spec.audio, r.spec.size, //
        r.footage, r.poster, mark(r.spec.ok), mark(r.compliance.isEmpty), mark(r.narrative.isEmpty), r.ok ? 'PASS' : 'FAIL',
      ],
  ];
  final widths = [for (var i = 0; i < rows.first.length; i++) rows.map((r) => r[i].runes.length).reduce((a, b) => a > b ? a : b)];
  final out = StringBuffer();
  for (final (n, r) in rows.indexed) {
    out.writeln([for (var i = 0; i < r.length; i++) r[i].padRight(widths[i] + r[i].length - r[i].runes.length)].join('  ').trimRight());
    if (n == 0) out.writeln([for (final w in widths) '─' * w].join('  '));
  }
  for (final r in reports.where((r) => !r.ok)) {
    for (final f in r.failures) {
      out.writeln('✗ ${r.storefront}/${r.script}/${r.slot} $f');
    }
  }
  return out.toString();
}
