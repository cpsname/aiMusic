import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Maintenance status from `GET /app/config`. [resumeAt] is the server's
/// estimated recovery time (UTC); null when unknown.
@immutable
class Maintenance {
  const Maintenance({
    required this.active,
    required this.message,
    this.resumeAt,
  });

  final bool active;
  final String message;
  final DateTime? resumeAt;

  /// The safe default: not under maintenance.
  static const Maintenance inactive = Maintenance(active: false, message: '');

  @override
  bool operator ==(Object other) =>
      other is Maintenance &&
      other.active == active &&
      other.message == message &&
      other.resumeAt == resumeAt;

  @override
  int get hashCode => Object.hash(active, message, resumeAt);
}

/// Runtime app-governance config (the `app/config` bounded context): a
/// maintenance gate, feature kill-switches, and a remote key/value parameter
/// bag. Distinct from the startup `AppInitData` snapshot (products / legal /
/// force-update) — the two contracts never overlap.
@immutable
class AppConfig {
  const AppConfig({
    required this.maintenance,
    required this.killSwitches,
    required this.config,
  });

  final Maintenance maintenance;

  /// Disabled feature codes; the UI hides/disables the matching entries. Unknown
  /// codes are ignored (forward-compatible).
  final List<String> killSwitches;

  /// Remote parameters (arbitrary key/value); a missing key falls back to the
  /// client default via [configValue].
  final Map<String, Object?> config;

  /// Fail-open default — used before the first successful fetch and on any
  /// failure: not under maintenance, nothing killed, no overrides.
  static const AppConfig safeDefault = AppConfig(
    maintenance: Maintenance.inactive,
    killSwitches: <String>[],
    config: <String, Object?>{},
  );

  /// Whether [code] is currently kill-switched.
  bool isKilled(String code) => killSwitches.contains(code);

  /// The remote value for [key] when present and assignable to [T], else
  /// [fallback].
  T configValue<T>(String key, T fallback) {
    final value = config[key];
    return value is T ? value : fallback;
  }

  // Value equality so derived providers (maintenance / promo / kill-switch) only
  // notify on a real change — a no-op refresh/resume must not rebuild the tree.
  @override
  bool operator ==(Object other) =>
      other is AppConfig &&
      other.maintenance == maintenance &&
      _equality.equals(other.killSwitches, killSwitches) &&
      _equality.equals(other.config, config);

  @override
  int get hashCode => Object.hash(
        maintenance,
        _equality.hash(killSwitches),
        _equality.hash(config),
      );
}

const DeepCollectionEquality _equality = DeepCollectionEquality();
