import 'dart:io';

import 'package:arch_guard/arch_guard.dart';

/// Gate 6 — scans the workspace for architecture-boundary violations and exits
/// non-zero (CI red) when any are found.
void main(List<String> args) {
  final start = args.isNotEmpty ? args.first : Directory.current.path;
  final repoRoot = findRepoRoot(start);
  if (repoRoot == null) {
    stderr.writeln(
      'arch_guard: could not locate the workspace root '
      '(no melos.yaml walking up from "$start").',
    );
    exit(2);
  }

  final roots = architectureScanRoots(repoRoot);
  final violations = scanDirectories(roots);

  if (violations.isEmpty) {
    stdout.writeln(
      '✓ arch_guard: 0 architecture-boundary violations '
      '(${roots.length} source roots scanned).',
    );
    return;
  }

  stderr.writeln(
    '✗ arch_guard: ${violations.length} architecture-boundary violation(s):\n',
  );
  for (final violation in violations) {
    stderr.writeln('  $violation');
  }
  stderr.writeln(
    '\nThese boundaries are the template contract (CLAUDE.md / '
    'DEEP_FOUNDATIONS_SPEC.md §3). Fix the imports at the correct layer; '
    'do not weaken the checker.',
  );
  exit(1);
}
