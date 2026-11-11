import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:json_schema/json_schema.dart';
import 'package:path/path.dart' as p;

import '../config/app.dart';
import '../core/errors.dart';

/// The assets-manifest contract (template ADR-0010). ascpub owns it
/// (`docs/contracts/` of its repository); this package reads it from the
/// ascpub checkout the app names and validates what it writes against it —
/// it keeps no copy and no definition of its own. The app pins the schema's
/// SHA-256, so a changed contract stops the tool until someone has read the
/// change and moved the pin.
const String contractSourceDir = 'docs/contracts';
const String contractSchemaFile = 'assets-manifest.schema.json';
const String contractExampleFile = 'assets-manifest.example.json';

/// The environment variable that overrides app.yaml `creatives.ascpub.root`
/// (a CI checkout, another machine's layout).
const String ascpubRootVariable = 'ASCPUB_ROOT';

/// The ascpub checkout for the app repo at [repoRoot]: `$ASCPUB_ROOT`, else
/// [config]'s `root` relative to the repo.
String ascpubRoot(String repoRoot, AscpubConfig config, {Map<String, String>? environment}) {
  final env = (environment ?? Platform.environment)[ascpubRootVariable];
  if (env != null && env.trim().isNotEmpty) return p.normalize(p.absolute(env.trim()));
  return p.normalize(p.join(repoRoot, config.root));
}

String _sha256(String path) => sha256.convert(File(path).readAsBytesSync()).toString();

/// The assets-manifest JSON Schema of an ascpub checkout, compiled.
class ManifestContract {
  ManifestContract._({
    required this.schema,
    required this.raw,
    required this.version,
    required this.root,
    required this.sha256,
    required this.commit,
    required this.dirty,
  });

  /// Reads the contract from the ascpub checkout at [root] and holds it to
  /// [pinnedSha256] (app.yaml `creatives.ascpub.schema_sha256`).
  factory ManifestContract.load(String root, {required String pinnedSha256}) {
    final path = p.join(root, contractSourceDir, contractSchemaFile);
    if (!File(path).existsSync()) {
      throw ConfigError('no ascpub contract at $path — set app.yaml creatives.ascpub.root or \$$ascpubRootVariable to the ascpub checkout');
    }
    final actual = _sha256(path);
    if (actual != pinnedSha256) {
      throw ConfigError('ascpub\'s $contractSchemaFile is $actual, the app follows $pinnedSha256: the contract changed — '
          'read the change in $root ($contractSourceDir), adapt the tool if the version moved, then set creatives.ascpub.schema_sha256');
    }
    final raw = jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
    final version = ((raw['properties'] as Map?)?['schema'] as Map?)?['const'];
    if (version is! int) throw ConfigError('$path: properties.schema.const is not an integer');
    final head = Process.runSync('git', ['-C', root, 'rev-parse', 'HEAD']);
    final status = Process.runSync('git', ['-C', root, 'status', '--porcelain', '--', contractSourceDir]);
    return ManifestContract._(
      schema: JsonSchema.create(raw),
      raw: raw,
      version: version,
      root: root,
      sha256: actual,
      commit: head.exitCode == 0 ? '${head.stdout}'.trim() : 'unknown',
      dirty: status.exitCode == 0 && '${status.stdout}'.trim().isNotEmpty,
    );
  }

  final JsonSchema schema;

  /// The schema document.
  final Map<String, Object?> raw;

  /// The manifest version the contract pins (`"schema": <version>`).
  final int version;

  /// The ascpub checkout it was read from.
  final String root;

  /// The schema file's SHA-256 (= the app's pin).
  final String sha256;

  /// The ascpub commit, and whether the contract has uncommitted changes there.
  final String commit;
  final bool dirty;

  /// ascpub's own valid example (`assets-manifest.example.json`).
  Object? example() => jsonDecode(File(p.join(root, contractSourceDir, contractExampleFile)).readAsStringSync());

  Object? _at(List<String> path) {
    Object? node = raw;
    for (final key in path) {
      node = node is Map ? node[key] : null;
    }
    return node;
  }

  Map<String, Object?> get _entry => (_at(['\$defs', 'entry', 'properties']) as Map?)?.cast<String, Object?>() ?? const {};

  RegExp _pattern(Object? node, String what) {
    final pattern = node is Map ? node['pattern'] : null;
    if (pattern is! String) throw ConfigError('the contract has no pattern for $what');
    return RegExp(pattern, unicode: true);
  }

  /// What an entry id, a placement target and an experiment tag must look
  /// like — read from the contract, never restated here.
  RegExp get idPattern => _pattern(_entry['id'], 'entry ids');
  RegExp get targetPattern => _pattern(((_entry['placement_intents'] as Map?)?['items'] as Map?)?['properties']?['target'], 'placement targets');
  RegExp get tagPattern => _pattern((_entry['experiment_tags'] as Map?)?['items'], 'experiment tags');

  /// The license-id fields of `authorization` (`interaction_id`, `mv_id`,
  /// `generation_id`).
  List<String> get authorizationFields => [for (final f in ((_entry['authorization'] as Map?)?['required'] as List? ?? const [])) '$f'];

  /// The placement intents the contract knows.
  List<String> get placements =>
      [for (final v in (((((_entry['placement_intents'] as Map?)?['items'] as Map?)?['properties'] as Map?)?['placement'] as Map?)?['enum'] as List? ?? const [])) '$v'];

  /// The entry types the contract knows.
  List<String> get types => [for (final v in ((_entry['type'] as Map?)?['enum'] as List? ?? const [])) '$v'];

  /// `ascpub <commit> (schema <version>, <sha>)`, for messages and reports.
  String describe() => 'ascpub ${commit.length >= 7 ? commit.substring(0, 7) : commit}${dirty ? '+changes' : ''} '
      '(schema $version, ${sha256.substring(0, 12)}…)';

  /// Every contract violation of [manifest], `<instance path>: <message>`.
  List<String> violations(Object? manifest) => [
    for (final e in schema.validate(manifest).errors) '${e.instancePath.isEmpty ? '/' : e.instancePath}: ${_short(e.message)} (${e.schemaPath})',
  ];
}

/// A validator message without the instance it may quote in full.
String _short(String message) {
  final cut = message.indexOf(' {');
  return cut > 0 ? message.substring(0, cut) : message;
}
