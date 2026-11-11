/// A broken input (app.yaml, a script, a template, the manifest, the
/// captions): the pipeline stops before it records or renders anything.
class ConfigError implements Exception {
  ConfigError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A tool the pipeline runs failed (simctl, ffmpeg, flutter …).
class ToolError implements Exception {
  ToolError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Problems found by a check; the check fails when any is recorded.
class Problems {
  final List<String> _items = [];

  void add(String problem) => _items.add(problem);

  void check(bool ok, String problem) {
    if (!ok) add(problem);
  }

  void addAll(Problems other) => _items.addAll(other._items);

  bool get isEmpty => _items.isEmpty;
  List<String> get items => List.unmodifiable(_items);

  /// Throws a [ConfigError] listing every problem, headed by [what].
  void throwIfAny(String what) {
    if (isEmpty) return;
    throw ConfigError('$what: ${_items.length} problem(s)\n$this');
  }

  @override
  String toString() => _items.map((p) => '  ✗ $p').join('\n');
}
