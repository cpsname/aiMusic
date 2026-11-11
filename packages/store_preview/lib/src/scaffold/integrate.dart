import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../core/errors.dart';
import '../core/file_plan.dart';

/// Adds only the development wiring owned by store-preview. Existing targets,
/// dependencies and workspace entries are preserved; conflicting wiring fails
/// before any file is written. The caller chooses preview, check or apply.
FilePlan planIntegration(String root) {
  final plan = FilePlan(root);
  final source = plan.read('pubspec.yaml');
  if (source == null) throw ConfigError('integrate: no pubspec.yaml in $root');
  final spec = loadYaml(source);
  if (spec is! YamlMap || spec['name'] is! String) throw ConfigError('integrate: pubspec.yaml needs an app name');
  if (spec['resolution'] == 'workspace') throw ConfigError('integrate: run at the pub workspace root, not a member');
  final environment = spec['environment'];
  final constraint = environment is Map ? environment['sdk'] : null;
  if (constraint is! String) throw ConfigError('integrate: environment.sdk is required (workspace requires Dart >=3.6)');
  final sdk = VersionConstraint.parse(constraint);
  if (sdk is! VersionRange || sdk.min == null || sdk.min! < Version(3, 6, 0)) {
    throw ConfigError('integrate: environment.sdk must require Dart >=3.6 for pub workspace; review the app SDK constraint first');
  }
  final editor = YamlEditor(source);
  final workspace = spec['workspace'];
  if (workspace != null && (workspace is! YamlList || workspace.any((e) => e is! String))) {
    throw ConfigError('integrate: workspace must be a list of package paths');
  }
  final members = workspace == null ? <String>[] : (workspace as YamlList).cast<String>().toList();
  // Pub accepts wildcard members. Match a path component without silently
  // appending the same package beneath an existing wildcard.
  bool covers(String pattern, String member) {
    final expression = RegExp.escape(p.normalize(pattern)).replaceAll(r'\*', '[^/]*');
    return RegExp('^$expression\$').hasMatch(member);
  }

  for (final name in ['store_preview', 'store_preview_driver']) {
    final member = 'packages/$name';
    final file = File(p.join(root, member, 'pubspec.yaml'));
    if (!file.existsSync()) throw ConfigError('integrate: $member is missing; run vendor from the template first');
    final package = loadYaml(file.readAsStringSync());
    if (package is! Map || package['name'] != name || package['resolution'] != 'workspace') {
      throw ConfigError('integrate: $member is not the expected workspace package; re-vendor');
    }
    if (!members.any((m) => covers(m, member))) members.add(member);
  }
  if (workspace == null || members.length != workspace.length) editor.update(['workspace'], members);
  final dev = spec['dev_dependencies'];
  final deps = spec['dependencies'];
  if ((dev != null && dev is! Map) || (deps != null && deps is! Map)) {
    throw ConfigError('integrate: dependencies and dev_dependencies must be mappings');
  }
  final additions = <String, Object>{};
  for (final e in <String, Map<String, String>>{
    'integration_test': {'sdk': 'flutter'},
    'store_preview_driver': {'path': 'packages/store_preview_driver'},
  }.entries) {
    final existing = (dev as Map?)?[e.key] ?? (deps as Map?)?[e.key];
    if (existing == null) {
      additions[e.key] = e.value;
    } else if (existing is! Map || existing.length != 1 || existing[e.value.keys.single] != e.value.values.single) {
      throw ConfigError('integrate: ${e.key} conflicts with ${e.value}; existing dependency kept');
    }
  }
  if (dev == null && additions.isNotEmpty) {
    editor.update(['dev_dependencies'], additions);
  } else {
    for (final e in additions.entries) {
      editor.update(['dev_dependencies', e.key], e.value);
    }
  }
  plan.set('pubspec.yaml', editor.toString());

  final originalMake = plan.read('Makefile') ?? '';
  var make = originalMake;
  final recipes = {'store-preview': 'dart run store_preview \$(ARGS)', 'asset-library': 'bash scripts/asset_library_check.sh \$(APP)'};
  for (final e in recipes.entries) {
    final match = RegExp('^${e.key}\\s*:[^\\n]*\\n((?:\\t[^\\n]*\\n|\\n)*)', multiLine: true).firstMatch(make);
    if (match != null) {
      if (!match.group(1)!.contains(e.value)) throw ConfigError('integrate: Makefile ${e.key} has a custom recipe; kept for manual integration');
      continue;
    }
    // A grouped/double-colon target has its own semantics; do not add a
    // second recipe and let make unexpectedly replace the user's behavior.
    if (RegExp('^[^#\\n:]*\\b${e.key}\\s*(?:[^\\n:]*):', multiLine: true).hasMatch(make)) {
      throw ConfigError('integrate: Makefile ${e.key} is grouped or nonstandard; kept for manual integration');
    }
    make = '${make.trimRight()}\n\n.PHONY: ${e.key}\n${e.key}:\n\t${e.value}\n';
  }
  plan.set('Makefile', make);
  return plan;
}
