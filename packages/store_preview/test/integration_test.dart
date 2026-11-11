import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:store_preview/store_preview.dart';

void main() {
  late Directory dir;
  void write(String path, String text) => (File(p.join(dir.path, path))..parent.createSync(recursive: true)).writeAsStringSync(text);
  setUp(() {
    dir = Directory.systemTemp.createTempSync('aso_integration_');
    write(
      'pubspec.yaml',
      'name: reuse_notes\n# Keep this application comment.\nversion: 4.2.1+7\nenvironment:\n  sdk: ^3.11.0\ndependencies:\n  flutter: {sdk: flutter}\n',
    );
    for (final name in ['store_preview', 'store_preview_driver']) {
      write('packages/$name/pubspec.yaml', 'name: $name\nresolution: workspace\n');
    }
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('integration plans without writing; applies workspace, dev dependencies and make once', () {
    final original = File(p.join(dir.path, 'pubspec.yaml')).readAsStringSync();
    final plan = planIntegration(dir.path);
    expect(plan.changed, containsAll(['pubspec.yaml', 'Makefile']));
    expect(File(p.join(dir.path, 'pubspec.yaml')).readAsStringSync(), original);
    plan.apply();
    final spec = File(p.join(dir.path, 'pubspec.yaml')).readAsStringSync();
    expect(spec, contains('# Keep this application comment.'));
    expect(spec, contains('version: 4.2.1+7'));
    expect(spec, contains('integration_test:'));
    expect(planIntegration(dir.path).changed, isEmpty);
    expect(File(p.join(dir.path, 'Makefile')).readAsStringSync(), contains('dart run store_preview \$(ARGS)'));
  });

  test('a custom make recipe or incompatible dependency leaves the repository unchanged', () {
    final spec = File(p.join(dir.path, 'pubspec.yaml'));
    final before = spec.readAsStringSync();
    write('Makefile', 'store-preview:\n\techo custom\n');
    expect(() => planIntegration(dir.path), throwsA(isA<ConfigError>()));
    expect(spec.readAsStringSync(), before);
    write('Makefile', '# business targets\nrun:\n\techo run\n');
    spec.writeAsStringSync('$before\ndev_dependencies:\n  store_preview_driver: ^9.0.0\n');
    expect(() => planIntegration(dir.path), throwsA(isA<ConfigError>()));
    expect(File(p.join(dir.path, 'Makefile')).readAsStringSync(), contains('echo run'));
  });

  test('workspace wildcard and other package membership are preserved without duplicates', () {
    final spec = File(p.join(dir.path, 'pubspec.yaml'));
    spec.writeAsStringSync('${spec.readAsStringSync()}\nworkspace:\n  - packages/*\n');
    planIntegration(dir.path).apply();
    expect(spec.readAsStringSync(), contains('packages/*'));
    expect(spec.readAsStringSync().split('workspace:').last, isNot(contains('- packages/store_preview')));
    expect(planIntegration(dir.path).changed, isEmpty);
  });

  test('SDK constraints and member roots fail with actionable errors', () {
    final spec = File(p.join(dir.path, 'pubspec.yaml'));
    final before = spec.readAsStringSync();
    spec.writeAsStringSync(before.replaceFirst('^3.11.0', '^3.0.0'));
    expect(() => planIntegration(dir.path), throwsA(isA<ConfigError>().having((e) => e.message, 'message', contains('Dart >=3.6'))));
    spec.writeAsStringSync('$before\nresolution: workspace\n');
    expect(() => planIntegration(dir.path), throwsA(isA<ConfigError>()));
  });

  test('file plan rejects traversal, linked targets and edits made after planning', () {
    final plan = FilePlan(dir.path);
    expect(() => plan.set('../other-app.txt', 'changed'), throwsA(isA<ConfigError>()));
    Link(p.join(dir.path, 'linked')).createSync(p.join(dir.path, 'pubspec.yaml'));
    expect(() => plan.set('linked', 'changed'), throwsA(isA<ConfigError>()));
    plan.set('pubspec.yaml', 'name: changed\n');
    write('pubspec.yaml', 'name: user_edit\n');
    expect(() => plan.apply(), throwsA(isA<ConfigError>()));
    expect(File(p.join(dir.path, 'pubspec.yaml')).readAsStringSync(), 'name: user_edit\n');
  });

  test('two app roots keep independent dependencies and make files', () {
    final other = Directory.systemTemp.createTempSync('aso_other_');
    addTearDown(() => other.deleteSync(recursive: true));
    final marker = File(p.join(other.path, 'pubspec.yaml'))..writeAsStringSync('name: untouched\n');
    planIntegration(dir.path).apply();
    expect(marker.readAsStringSync(), 'name: untouched\n');
    expect(File(p.join(other.path, 'Makefile')).existsSync(), isFalse);
  });
}
