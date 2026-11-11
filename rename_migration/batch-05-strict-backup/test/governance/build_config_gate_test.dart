// Governance: the build-time config gate.
//
// Every other config guard lives in the Makefile, which the Xcode Run/Archive
// button bypasses entirely — Xcode reads DART_DEFINES out of the Flutter-
// generated xcconfig, and that file holds whatever the *last* flutter command
// wrote. An Archive taken after a bare `flutter run` therefore ships with no
// base URL, no distribution code and no signing secret; the app then fails
// every `/v1/*` call with `40304`. These tests keep the gate that catches it —
// both the script's behaviour and its wiring into the Xcode projects.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

File _xcconfig(Directory dir, Map<String, String>? defines) {
  final file = File('${dir.path}/Generated.xcconfig');
  final buffer = StringBuffer('FLUTTER_ROOT=/tmp/flutter\n');
  if (defines != null) {
    buffer.writeln(
      'DART_DEFINES=${defines.entries.map((e) => base64.encode(utf8.encode('${e.key}=${e.value}'))).join(',')}',
    );
  }
  file.writeAsStringSync(buffer.toString());
  return file;
}

const _prodDefines = {
  'ENV': 'prod',
  'BASE_URL': 'https://api.example.test/v1',
  'DISTRIBUTION_CODE': 'com.example.studio',
  'DISTRIBUTION_SECRET': 'secret',
  'APP_CODE': 'studio_app',
  'BUNDLE_ID': 'com.example.studio',
  'IAP_CHANNEL': 'appstore',
};

/// The key list the Makefile enforces, read from the Makefile itself so the
/// test cannot drift from the single source of truth.
List<String> _makefileKeys(String variable) {
  final line = File(
    'Makefile',
  ).readAsLinesSync().firstWhere((l) => l.startsWith(variable));
  return line.split('=').last.trim().split(RegExp(r'\s+'));
}

List<String> _requiredKeys() => _makefileKeys('REQUIRED_KEYS');

/// Store-build-only keys (GUARD_SHIP): the compile-time legal-link fallbacks.
List<String> _shipKeys() => _makefileKeys('SHIP_KEYS');

/// The Songlet identity / address rules (SONGLET_RULES) exactly as make expands
/// them — taken from a dry run of the Xcode gate target, so the tests exercise
/// the rules the build really applies rather than a copy of them.
List<String> _songletRules() {
  final dry = Process.runSync('make', [
    '-n',
    '-s',
    'verify-xcode-config',
    'XCCONFIG=x',
  ]);
  final line = (dry.stdout as String)
      .split('\n')
      .firstWhere((l) => l.contains('verify_xcode_config.sh'));
  // Shell words, honouring the single quotes around the regex.
  final words = RegExp(
    r"'([^']*)'|(\S+)",
  ).allMatches(line).map((m) => m.group(1) ?? m.group(2)!).toList();
  final start = words.indexWhere(
    (w) => w == '--expect' || w == '--match' || w == '--forbid-host',
  );
  expect(
    start,
    isNonNegative,
    reason: 'SONGLET_RULES missing from the Xcode gate: $line',
  );
  return words.sublist(start);
}

/// A dev config that satisfies every rule: the tracked example with its
/// placeholder secret filled.
Map<String, String> _songletDev() {
  final example =
      (jsonDecode(File('config/dev.example.json').readAsStringSync())
              as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, '$v'));
  return {...example, 'DISTRIBUTION_SECRET': 'a' * 64};
}

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('xcode_config_gate'));
  tearDown(() => tmp.deleteSync(recursive: true));

  ProcessResult run(
    File xcconfig, {
    bool requireProd = false,
    String? configDir,
  }) => Process.runSync('bash', [
    'scripts/verify_xcode_config.sh',
    xcconfig.path,
    for (final key in _requiredKeys()) ...['--require', key],
    '--config-dir',
    configDir ?? '${tmp.path}/no-config',
    if (requireProd) '--require-prod',
  ]);

  group('verify_xcode_config.sh', () {
    test('a fully injected prod config passes a release build', () {
      final result = run(_xcconfig(tmp, _prodDefines), requireProd: true);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(result.stdout, contains('ENV=prod'));
    });

    test('no DART_DEFINES at all — the shape that shipped — is rejected', () {
      final result = run(_xcconfig(tmp, null));
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('DISTRIBUTION_SECRET'));
      expect(result.stderr, contains('40304'));
    });

    test('one empty key is enough to fail', () {
      final result = run(
        _xcconfig(tmp, {..._prodDefines, 'DISTRIBUTION_SECRET': ''}),
      );
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('DISTRIBUTION_SECRET'));
    });

    test('dev config passes a debug build but fails a release build', () {
      final dev = _xcconfig(tmp, {..._prodDefines, 'ENV': 'dev'});
      expect(run(dev).exitCode, 0);

      // The "archived right after `make run`" case.
      final release = run(dev, requireProd: true);
      expect(release.exitCode, isNot(0));
      expect(release.stderr, contains('ENV=dev'));
    });

    test('a stale xcconfig is caught against the config file it claims', () {
      final configDir = Directory('${tmp.path}/config')..createSync();
      File('${configDir.path}/prod.json').writeAsStringSync(
        jsonEncode({..._prodDefines, 'BASE_URL': 'https://moved.example/v1'}),
      );

      final result = run(
        _xcconfig(tmp, _prodDefines),
        requireProd: true,
        configDir: configDir.path,
      );

      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('BASE_URL'));
    });

    test('a missing xcconfig is reported, not ignored', () {
      final result = Process.runSync('bash', [
        'scripts/verify_xcode_config.sh',
        '${tmp.path}/absent.xcconfig',
        '--require',
        'BASE_URL',
      ]);
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('make xcconfig'));
    });
  });

  group('wiring', () {
    test('both Xcode projects run the gate as a build phase', () {
      for (final project in [
        'ios/Runner.xcodeproj/project.pbxproj',
        'macos/Runner.xcodeproj/project.pbxproj',
      ]) {
        final text = File(project).readAsStringSync();
        expect(text, contains('Verify Build Config'), reason: project);
        expect(text, contains('make -s verify-xcode-config'), reason: project);
      }
    });

    test('the Makefile key lists cover every key in dev.example.json', () {
      final example =
          jsonDecode(File('config/dev.example.json').readAsStringSync())
              as Map<String, dynamic>;

      // Every example key is enforced somewhere: dev-and-up (REQUIRED_KEYS) or
      // store-build-only (SHIP_KEYS).
      expect([..._requiredKeys(), ..._shipKeys()], containsAll(example.keys));
    });
  });

  group('check_config.sh (store-build guard)', () {
    ProcessResult check(Map<String, String> config) {
      final file = File('${tmp.path}/prod.json')
        ..writeAsStringSync(jsonEncode(config));
      return Process.runSync('bash', [
        'scripts/check_config.sh',
        file.path,
        for (final key in [..._requiredKeys(), ..._shipKeys()]) ...[
          '--require',
          key,
        ],
        '--no-placeholder',
        '--expect-env',
        'prod',
        '--https',
        '--no-localhost',
      ]);
    }

    test(
      'a store build cannot be produced without the legal fallback URLs',
      () {
        // The App Review 3.1.2 closure: TERMS_URL / PRIVACY_URL are optional in
        // dev but hard-required by GUARD_SHIP, so a shipped binary always has
        // functional Terms/Privacy links even when `/app/init` omits them.
        final result = check({
          ..._prodDefines,
          'TERMS_URL': 'https://t',
          'PRIVACY_URL': '',
        });
        expect(result.exitCode, isNot(0));
        expect(result.stderr, contains('PRIVACY_URL'));
      },
    );

    test('a store build with both legal URLs filled passes', () {
      final result = check({
        ..._prodDefines,
        'TERMS_URL': 'https://example.com/terms',
        'PRIVACY_URL': 'https://example.com/privacy',
      });
      expect(result.exitCode, 0, reason: '${result.stderr}');
    });
  });

  // Debug configurations can target a different app/backend; production and
  // store builds retain the Songlet identity/address contract.
  group('Songlet identity / address rules', () {
    ProcessResult checkDev(Map<String, String> config) {
      final file = File('${tmp.path}/dev.json')
        ..writeAsStringSync(jsonEncode(config));
      return Process.runSync('bash', [
        'scripts/check_config.sh',
        file.path,
        for (final key in _requiredKeys()) ...['--require', key],
        '--no-placeholder',
        '--expect-env',
        'dev',
        ..._songletRules(),
      ]);
    }

    test('the tracked dev example satisfies the rules', () {
      final result = checkDev(_songletDev());
      expect(result.exitCode, 0, reason: '${result.stderr}');
    });

    test('a local BFF (product-api :9910) is accepted', () {
      final result = checkDev({
        ..._songletDev(),
        'BASE_URL': 'http://localhost:9910/v1',
      });
      expect(result.exitCode, 0, reason: '${result.stderr}');
    });

    for (final (name, patch, needle) in [
      (
        'platform domain',
        {'BASE_URL': 'https://genaistudio.showsapp.org/v1'},
        'genaistudio.showsapp.org',
      ),
      (
        'local platform port',
        {'BASE_URL': 'http://localhost:9999/v1'},
        'localhost:9999',
      ),
      (
        'undotted distribution (40304 at the BFF)',
        {'DISTRIBUTION_CODE': 'songlet_ios'},
        'DISTRIBUTION_CODE',
      ),
      ('another app\'s identity', {'APP_CODE': 'GenAI'}, 'APP_CODE'),
    ]) {
      test('rejects $name', () {
        final result = checkDev({..._songletDev(), ...patch});
        expect(result.exitCode, isNot(0));
        expect(result.stderr, contains(needle));
      });
    }

    test('the Xcode gate applies the rules to production defines', () {
      final result = Process.runSync('bash', [
        'scripts/verify_xcode_config.sh',
        _xcconfig(tmp, {
          ..._songletDev(),
          'ENV': 'prod',
          'BASE_URL': 'https://genaistudio.showsapp.org/v1',
        }).path,
        for (final key in _requiredKeys()) ...['--require', key],
        '--config-dir',
        '${tmp.path}/no-config',
        ..._songletRules(),
      ]);
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('genaistudio.showsapp.org'));
    });

    test('the Xcode gate passes a valid Songlet build', () {
      final result = Process.runSync('bash', [
        'scripts/verify_xcode_config.sh',
        _xcconfig(tmp, _songletDev()).path,
        for (final key in _requiredKeys()) ...['--require', key],
        '--config-dir',
        '${tmp.path}/no-config',
        ..._songletRules(),
      ]);
      expect(result.exitCode, 0, reason: '${result.stderr}');
    });

    for (final env in ['dev', 'staging']) {
      test('the Xcode gate allows custom $env debug identity and backend', () {
        final result = Process.runSync('bash', [
          'scripts/verify_xcode_config.sh',
          _xcconfig(tmp, {
            ..._songletDev(),
            'ENV': env,
            'APP_CODE': 'GenAI',
            'BASE_URL': 'https://genaistudio.showsapp.org/v1',
            'DISTRIBUTION_CODE': 'debug_app',
          }).path,
          for (final key in _requiredKeys()) ...['--require', key],
          '--config-dir',
          '${tmp.path}/no-config',
          ..._songletRules(),
        ]);
        expect(result.exitCode, 0, reason: '${result.stderr}');
      });
    }

    test('a mock build is exempt (the mock speaks its own contract copy)', () {
      final result = Process.runSync('bash', [
        'scripts/verify_xcode_config.sh',
        _xcconfig(tmp, {
          ..._songletDev(),
          'ENV': 'mock',
          'BASE_URL': 'http://localhost:8787/v1',
          'DISTRIBUTION_CODE': 'songlet_ios',
        }).path,
        for (final key in _requiredKeys()) ...['--require', key],
        '--config-dir',
        '${tmp.path}/no-config',
        ..._songletRules(),
      ]);
      expect(result.exitCode, 0, reason: '${result.stderr}');
    });
  });

  group('make config guards', () {
    ProcessResult check(
      String env, {
      String target = 'run',
      Map<String, String> patch = const {},
    }) {
      final file = File('${tmp.path}/$env.json')
        ..writeAsStringSync(
          jsonEncode({
            ..._songletDev(),
            'ENV': env,
            'APP_CODE': 'GenAI',
            'BASE_URL': 'https://genaistudio.showsapp.org/v1',
            'DISTRIBUTION_CODE': 'debug_app',
            'PRIVACY_URL': 'https://example.test/privacy',
            ...patch,
          }),
        );
      final dry = Process.runSync('make', [
        '-n',
        '-s',
        target,
        'ENV=$env',
        'CONFIG=${file.path}',
      ]);
      expect(dry.exitCode, 0, reason: '${dry.stderr}');
      // Execute only the real make-expanded guard; never launch Flutter or
      // create a build while testing configuration admission.
      final guard = (dry.stdout as String)
          .split('\n')
          .firstWhere((line) => line.contains('bash scripts/check_config.sh'));
      return Process.runSync('bash', ['-c', guard]);
    }

    for (final env in ['dev', 'staging']) {
      test('make run permits a custom $env identity and platform backend', () {
        final result = check(env);
        expect(result.exitCode, 0, reason: '${result.stderr}');
      });
    }
    test('make run still requires a nonempty signing secret', () {
      final result = check('dev', patch: {'DISTRIBUTION_SECRET': ''});
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('DISTRIBUTION_SECRET'));
    });
    test('production still rejects another identity and platform backend', () {
      final result = check('prod');
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('APP_CODE'));
      expect(result.stderr, contains('genaistudio.showsapp.org'));
    });
    test('store builds enforce identity even with ENV overridden to dev', () {
      final result = check('dev', target: 'apk');
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('APP_CODE'));
    });
  });
}
