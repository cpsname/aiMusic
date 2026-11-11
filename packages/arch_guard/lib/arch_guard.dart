import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;

/// A single architecture-boundary violation found in a source file.
class ArchViolation {
  const ArchViolation({
    required this.rule,
    required this.filePath,
    required this.line,
    required this.detail,
    this.importUri = '',
  });

  /// Stable rule id, e.g. `no_reverse_dependency`.
  final String rule;

  /// Absolute, forward-slash path of the offending file.
  final String filePath;

  /// 1-based line of the offending directive (1 for path-only rules).
  final int line;

  /// Human-readable explanation of the violation.
  final String detail;

  /// The offending import/export URI (empty for path-only rules).
  final String importUri;

  @override
  String toString() {
    final origin = importUri.isEmpty ? '' : '  (import: $importUri)';
    return '$filePath:$line  [$rule]  $detail$origin';
  }
}

/// Flutter UI libraries the pure domain layer must never import.
const Set<String> _flutterUiLibraries = {
  'package:flutter/material.dart',
  'package:flutter/cupertino.dart',
  'package:flutter/widgets.dart',
};

bool _isPackageLib(String path) =>
    path.contains('/packages/') && path.contains('/lib/');

bool _isInPackageLib(String path, String pkg) =>
    path.contains('/packages/$pkg/lib/');

bool _isBusinessPackageLib(String path) =>
    _isInPackageLib(path, 'infra_core') ||
    _isInPackageLib(path, 'commerce_kit') ||
    _isInPackageLib(path, 'songlet_kit');

bool _isDomainFile(String path) => path.contains('/domain/');

bool _isApplicationLayerFile(String path) =>
    _isPackageLib(path) && path.contains('/application/');

bool _isCompositionRoot(String path) =>
    p.basename(path).endsWith('_providers.dart');

/// Whether [uri], as written inside [fromPath], targets the sibling [layer]
/// (`data` / `application`). Handles `package:` and relative URIs alike.
bool _importTargetsLayer(String fromPath, String uri, String layer) {
  final segment = '/$layer/';
  if (uri.startsWith('dart:')) return false;
  if (uri.startsWith('package:')) return uri.contains(segment);
  final resolved =
      p.normalize(p.join(p.dirname(fromPath), uri)).replaceAll(r'\', '/');
  return resolved.contains(segment);
}

/// Analyses one Dart source [content] located at [filePath] and returns the
/// architecture-boundary violations it contains. Pure (no IO) and therefore
/// unit-testable with in-memory fixtures.
List<ArchViolation> analyzeSource({
  required String filePath,
  required String content,
}) {
  final path = filePath.replaceAll(r'\', '/');
  final violations = <ArchViolation>[];

  if (path.contains('/presentation/')) {
    violations.add(ArchViolation(
      rule: 'no_presentation_dir',
      filePath: path,
      line: 1,
      detail: 'A `presentation/` directory is forbidden; UI lives under the '
          "app's lib/ui/ and reuses ui_kit.",
    ));
  }

  final parsed = parseString(content: content, throwIfDiagnostics: false);
  final lineInfo = parsed.lineInfo;

  for (final directive in parsed.unit.directives) {
    if (directive is! NamespaceDirective) continue;
    final uri = directive.uri.stringValue;
    if (uri == null) continue;
    final line = lineInfo.getLocation(directive.uri.offset).lineNumber;

    void report(String rule, String detail) {
      violations.add(ArchViolation(
        rule: rule,
        filePath: path,
        line: line,
        detail: detail,
        importUri: uri,
      ));
    }

    if (_isPackageLib(path) && uri.startsWith('package:songlet/')) {
      report(
        'no_reverse_dependency',
        'A reusable package must not import the app (package:songlet/...); '
            'dependencies flow app → packages, never the reverse.',
      );
    }

    if (_isBusinessPackageLib(path) && uri.startsWith('package:ui_kit/')) {
      report(
        'no_ui_in_business',
        'Business code (infra_core/commerce_kit/songlet_kit) must not import '
            'package:ui_kit/; UI composition belongs in the app layer.',
      );
    }

    if (_isDomainFile(path)) {
      if (_flutterUiLibraries.contains(uri)) {
        report(
          'domain_purity',
          'The domain layer must not import Flutter UI '
              '(material/cupertino/widgets).',
        );
      } else if (uri.startsWith('package:dio/')) {
        report(
          'domain_purity',
          'The domain layer must be transport-agnostic — no package:dio/.',
        );
      } else if (uri.startsWith('package:flutter_riverpod/') ||
          uri.startsWith('package:riverpod/')) {
        report(
          'domain_purity',
          'The domain layer must not depend on Riverpod (that belongs to the '
              'application layer).',
        );
      } else if (_importTargetsLayer(path, uri, 'data')) {
        report(
          'domain_purity',
          'The domain layer must not import the data layer '
              '(dependencies point inward).',
        );
      } else if (_importTargetsLayer(path, uri, 'application')) {
        report(
          'domain_purity',
          'The domain layer must not import the application layer '
              '(dependencies point inward).',
        );
      }
    }

    if (_isApplicationLayerFile(path) &&
        !_isCompositionRoot(path) &&
        _importTargetsLayer(path, uri, 'data')) {
      report(
        'application_depends_on_domain',
        'The application layer must reach the data layer only through domain '
            'interfaces; bind concrete implementations in *_providers.dart '
            '(the composition root).',
      );
    }
  }

  if (_isUiFile(path)) {
    violations.addAll(_directionalLayoutViolations(path, content));
  }

  return violations;
}

bool _isUiFile(String path) =>
    path.contains('/lib/ui/') || path.contains('/packages/ui_kit/lib/');

final RegExp _namedDirectionalAlignment = RegExp(
  r'\bAlignment\.(topLeft|topRight|centerLeft|centerRight|bottomLeft|bottomRight)\b',
);
final RegExp _fromLtrb = RegExp(r'\bEdgeInsets\.fromLTRB\b');
final RegExp _leftRightArg = RegExp(r'\b(left|right)\s*:');

/// RTL-unsafe hardcoded directional layout in UI source (DF⑤): named `Alignment`
/// corners, `EdgeInsets.fromLTRB`, and `left:`/`right:` args on
/// `EdgeInsets.only(...)` / `Positioned(...)`. The `*Directional` (start/end)
/// variants mirror correctly under `Directionality.rtl`.
List<ArchViolation> _directionalLayoutViolations(String path, String content) {
  final violations = <ArchViolation>[];
  void add(int offset, String detail) => violations.add(ArchViolation(
        rule: 'no_hardcoded_directional',
        filePath: path,
        line: _lineNumberAt(content, offset),
        detail: detail,
      ));

  for (final match in _namedDirectionalAlignment.allMatches(content)) {
    add(
      match.start,
      'Alignment.${match.group(1)} is RTL-unsafe — use AlignmentDirectional.* '
          '(start/end).',
    );
  }
  for (final match in _fromLtrb.allMatches(content)) {
    add(
      match.start,
      'EdgeInsets.fromLTRB is RTL-unsafe — use EdgeInsetsDirectional.fromSTEB '
          '(start/end).',
    );
  }
  for (final call in const ['EdgeInsets.only(', 'Positioned(']) {
    var from = 0;
    while (true) {
      final start = content.indexOf(call, from);
      if (start < 0) break;
      final open = start + call.length - 1;
      final close = _matchingParen(content, open);
      final args =
          close < 0 ? content.substring(open) : content.substring(open, close);
      if (_leftRightArg.hasMatch(args)) {
        add(
          start,
          '${call.replaceAll('(', '')} with left:/right: is RTL-unsafe — use the '
              '*Directional variant (start/end).',
        );
      }
      from = start + call.length;
    }
  }
  return violations;
}

int _lineNumberAt(String content, int offset) {
  var line = 1;
  final end = offset < content.length ? offset : content.length;
  for (var i = 0; i < end; i++) {
    if (content.codeUnitAt(i) == 0x0A) line++;
  }
  return line;
}

int _matchingParen(String content, int openIndex) {
  var depth = 0;
  for (var i = openIndex; i < content.length; i++) {
    final unit = content.codeUnitAt(i);
    if (unit == 0x28) {
      depth++;
    } else if (unit == 0x29) {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}

bool _isExcludedFromScan(String path) =>
    path.endsWith('.g.dart') ||
    path.contains('/l10n/generated/') ||
    path.contains('/.dart_tool/') ||
    path.contains('/packages/arch_guard/');

/// Recursively scans the given absolute [libRoots] for boundary violations
/// across every `.dart` source file.
List<ArchViolation> scanDirectories(List<String> libRoots) {
  final violations = <ArchViolation>[];
  for (final root in libRoots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart') || _isExcludedFromScan(path)) continue;
      violations.addAll(
        analyzeSource(filePath: path, content: entity.readAsStringSync()),
      );
    }
  }
  return violations;
}

/// Walks up from [start] to the workspace root (the directory containing
/// `melos.yaml`). Returns null when none is found.
String? findRepoRoot(String start) {
  var dir = Directory(p.absolute(start));
  while (true) {
    if (File(p.join(dir.path, 'melos.yaml')).existsSync()) {
      return dir.path.replaceAll(r'\', '/');
    }
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}

/// The lib/ roots the checker scans: the app's lib/ plus every workspace
/// member's lib/ except arch_guard itself.
List<String> architectureScanRoots(String repoRoot) {
  final roots = <String>[];
  final appLib = Directory(p.join(repoRoot, 'lib'));
  if (appLib.existsSync()) roots.add(appLib.path.replaceAll(r'\', '/'));
  final packagesDir = Directory(p.join(repoRoot, 'packages'));
  if (packagesDir.existsSync()) {
    final members = packagesDir.listSync().whereType<Directory>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final member in members) {
      if (p.basename(member.path) == 'arch_guard') continue;
      final lib = Directory(p.join(member.path, 'lib'));
      if (lib.existsSync()) roots.add(lib.path.replaceAll(r'\', '/'));
    }
  }
  return roots;
}
