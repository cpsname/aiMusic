import 'dart:io';

import 'package:yaml/yaml.dart';

import 'errors.dart';

/// YAML (or JSON) → plain Dart values: maps with string keys, lists, scalars.
Object? plain(Object? value) => switch (value) {
  YamlMap() => {for (final e in value.entries) '${e.key}': plain(e.value)},
  YamlList() => [for (final e in value) plain(e)],
  Map() => {for (final e in value.entries) '${e.key}': plain(e.value)},
  List() => [for (final e in value) plain(e)],
  _ => value,
};

/// Reads a YAML file as a map.
Fields readYamlFile(String path) {
  final file = File(path);
  if (!file.existsSync()) throw ConfigError('$path: no such file');
  final Object? doc;
  try {
    doc = plain(loadYaml(file.readAsStringSync()));
  } on YamlException catch (e) {
    throw ConfigError('$path: ${e.message}');
  }
  if (doc is! Map<String, Object?>) throw ConfigError('$path: not a map');
  return Fields(doc, path);
}

/// Typed, path-aware access to one map of a config file. Every accessor
/// names the file and key in its error, and [only] rejects unknown keys so a
/// typo fails loudly instead of being ignored.
class Fields {
  Fields(this.raw, this.where);

  final Map<String, Object?> raw;

  /// `file › key › key`, for messages.
  final String where;

  bool has(String key) => raw[key] != null;

  ConfigError _error(String key, String what) => ConfigError('$where › $key: $what');

  /// Fails on any key outside [allowed].
  void only(Set<String> allowed) {
    final unknown = raw.keys.where((k) => !allowed.contains(k)).toList();
    if (unknown.isNotEmpty) {
      throw ConfigError('$where: unknown key(s) ${unknown.join(', ')} (allowed: ${allowed.join(', ')})');
    }
  }

  String string(String key) {
    final v = raw[key];
    if (v is String && v.trim().isNotEmpty) return v;
    if (v is num || v is bool) return '$v';
    throw _error(key, v == null ? 'missing' : 'not a non-empty string');
  }

  String? optString(String key) => raw[key] == null ? null : string(key);

  double number(String key) {
    final v = raw[key];
    if (v is num) return v.toDouble();
    throw _error(key, v == null ? 'missing' : 'not a number');
  }

  double optNumber(String key, double fallback) => raw[key] == null ? fallback : number(key);

  int integer(String key) {
    final v = raw[key];
    if (v is int) return v;
    throw _error(key, v == null ? 'missing' : 'not an integer');
  }

  int optInteger(String key, int fallback) => raw[key] == null ? fallback : integer(key);

  bool boolean(String key, {required bool fallback}) {
    final v = raw[key];
    if (v == null) return fallback;
    if (v is bool) return v;
    throw _error(key, 'not true/false');
  }

  Fields map(String key) {
    final v = raw[key];
    if (v is Map<String, Object?>) return Fields(v, '$where › $key');
    throw _error(key, v == null ? 'missing' : 'not a map');
  }

  Fields? optMap(String key) => raw[key] == null ? null : map(key);

  List<Object?> list(String key) {
    final v = raw[key];
    if (v is List<Object?>) return v;
    throw _error(key, v == null ? 'missing' : 'not a list');
  }

  List<Object?> optList(String key) => raw[key] == null ? const [] : list(key);

  List<Fields> maps(String key, {bool required = false}) {
    if (!required && raw[key] == null) return const [];
    return [
      for (final (i, v) in list(key).indexed)
        if (v is Map<String, Object?>) Fields(v, '$where › $key[$i]') else throw _error('$key[$i]', 'not a map'),
    ];
  }

  List<String> strings(String key, {List<String> fallback = const []}) {
    if (raw[key] == null) return fallback;
    return [
      for (final (i, v) in list(key).indexed)
        if (v is String && v.isNotEmpty) v else if (v is num) '$v' else throw _error('$key[$i]', 'not a string'),
    ];
  }

  Map<String, String> stringMap(String key) {
    if (raw[key] == null) return const {};
    final m = map(key);
    return {for (final e in m.raw.entries) e.key: m.string(e.key)};
  }

  /// A list of steps: maps with a `do` string.
  List<Map<String, Object?>> steps(String key) => [
    for (final s in maps(key))
      if (s.raw['do'] is String) s.raw else throw ConfigError('${s.where}: a step needs "do"'),
  ];
}
