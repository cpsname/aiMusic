import 'dart:io';

import 'package:arch_guard/arch_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('analyzeSource — boundary fixtures', () {
    test('flags a reusable package importing the app', () {
      final v = analyzeSource(
        filePath: '/repo/packages/commerce_kit/lib/src/iap/x.dart',
        content: "import 'package:songlet/main.dart';\n",
      );
      expect(v.map((e) => e.rule), contains('no_reverse_dependency'));
    });

    test('flags business code importing ui_kit', () {
      final v = analyzeSource(
        filePath: '/repo/packages/infra_core/lib/src/x.dart',
        content: "import 'package:ui_kit/ui_kit.dart';\n",
      );
      expect(v.map((e) => e.rule), contains('no_ui_in_business'));
    });

    test('flags domain importing Flutter UI / dio / riverpod / data / app', () {
      const domain = '/repo/packages/commerce_kit/lib/src/iap/domain/x.dart';
      String only(String imp) => '$imp\n';
      for (final imp in [
        "import 'package:flutter/material.dart';",
        "import 'package:dio/dio.dart';",
        "import 'package:flutter_riverpod/flutter_riverpod.dart';",
        "import '../data/foo.dart';",
        "import '../application/foo.dart';",
      ]) {
        expect(
          analyzeSource(filePath: domain, content: only(imp)).map((e) => e.rule),
          contains('domain_purity'),
          reason: 'expected domain_purity for: $imp',
        );
      }
    });

    test('domain may import foundation, meta and sibling domain files', () {
      const domain = '/repo/packages/commerce_kit/lib/src/iap/domain/x.dart';
      final v = analyzeSource(
        filePath: domain,
        content: "import 'package:meta/meta.dart';\n"
            "import 'package:flutter/foundation.dart';\n"
            "import 'order_models.dart';\n",
      );
      expect(v, isEmpty);
    });

    test('flags a non-composition-root application file importing data', () {
      final v = analyzeSource(
        filePath:
            '/repo/packages/commerce_kit/lib/src/iap/application/orchestrator.dart',
        content: "import '../data/pending_order_store.dart';\n",
      );
      expect(v.map((e) => e.rule), contains('application_depends_on_domain'));
    });

    test('ALLOWS the composition root (*_providers.dart) to import data', () {
      final v = analyzeSource(
        filePath:
            '/repo/packages/commerce_kit/lib/src/iap/application/iap_providers.dart',
        content: "import '../data/pending_order_store.dart';\n",
      );
      expect(v, isEmpty);
    });

    test('flags a presentation/ directory', () {
      final v = analyzeSource(
        filePath: '/repo/packages/commerce_kit/lib/src/iap/presentation/x.dart',
        content: 'void main() {}\n',
      );
      expect(v.map((e) => e.rule), contains('no_presentation_dir'));
    });

    test('a clean app UI file has no violations', () {
      final v = analyzeSource(
        filePath: '/repo/lib/ui/paywall/paywall_page.dart',
        content: "import 'package:flutter/material.dart';\n"
            "import 'package:commerce_kit/commerce_kit.dart';\n"
            "import 'package:ui_kit/ui_kit.dart';\n",
      );
      expect(v, isEmpty);
    });
  });

  group('directional layout rule (DF⑤)', () {
    test('flags a named Alignment corner in a UI file', () {
      final v = analyzeSource(
        filePath: '/repo/lib/ui/x.dart',
        content: 'final a = Alignment.topLeft;\n',
      );
      expect(v.map((e) => e.rule), contains('no_hardcoded_directional'));
    });

    test('flags EdgeInsets.fromLTRB in a ui_kit file', () {
      final v = analyzeSource(
        filePath: '/repo/packages/ui_kit/lib/src/x.dart',
        content: 'const p = EdgeInsets.fromLTRB(1, 2, 3, 4);\n',
      );
      expect(v.map((e) => e.rule), contains('no_hardcoded_directional'));
    });

    test('flags EdgeInsets.only(left:/right:) in a UI file', () {
      final v = analyzeSource(
        filePath: '/repo/lib/ui/x.dart',
        content: 'const p = EdgeInsets.only(left: 8, top: 4);\n',
      );
      expect(v.map((e) => e.rule), contains('no_hardcoded_directional'));
    });

    test('allows the *Directional variants and Alignment.center', () {
      final v = analyzeSource(
        filePath: '/repo/lib/ui/x.dart',
        content: 'const a = AlignmentDirectional.topStart;\n'
            'const c = Alignment.center;\n'
            'const p = EdgeInsetsDirectional.only(start: 8);\n'
            'const q = EdgeInsetsDirectional.fromSTEB(1, 2, 3, 4);\n',
      );
      expect(v.where((e) => e.rule == 'no_hardcoded_directional'), isEmpty);
    });

    test('does not apply the directional rule outside UI files', () {
      final v = analyzeSource(
        filePath: '/repo/packages/infra_core/lib/src/x.dart',
        content: 'final a = Alignment.topLeft;\n',
      );
      expect(v.where((e) => e.rule == 'no_hardcoded_directional'), isEmpty);
    });
  });

  test('the real workspace has zero architecture-boundary violations', () {
    final repoRoot = findRepoRoot(Directory.current.path);
    expect(
      repoRoot,
      isNotNull,
      reason: 'melos.yaml not found from ${Directory.current.path}',
    );
    final violations = scanDirectories(architectureScanRoots(repoRoot!));
    expect(
      violations,
      isEmpty,
      reason: violations.map((v) => v.toString()).join('\n'),
    );
  });
}
