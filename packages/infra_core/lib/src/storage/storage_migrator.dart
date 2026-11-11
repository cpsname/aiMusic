import 'dart:async';

import 'key_value_store.dart';

/// One ordered persisted-storage migration step. [version] is the schema version
/// this step upgrades the store **to**; [migrate] transforms the persisted data
/// in place. It must be **defensive** — reset or skip data it cannot parse rather
/// than throw (corrupt data must never crash a cold start).
class StorageMigration {
  const StorageMigration({
    required this.version,
    required this.migrate,
    this.description = '',
  });

  final int version;
  final FutureOr<void> Function(KeyValueStore store) migrate;
  final String description;
}

/// Runs ordered [StorageMigration]s at startup so persisted shapes (pending
/// orders, the product cache, settings) evolve safely across app upgrades — a
/// class of bug that only bites existing users on update.
///
/// The schema version is stored under [versionKey] (0 before the first run).
/// Migrations whose [StorageMigration.version] is greater than the stored version
/// and at most [currentVersion] run in ascending order; the version is stamped
/// after each (so a partial run resumes next launch) and finally set to
/// [currentVersion]. The migrator never downgrades a store stamped by a newer
/// build than this one.
class StorageMigrator {
  StorageMigrator({
    required this.currentVersion,
    List<StorageMigration> migrations = const [],
    this.versionKey = defaultVersionKey,
  }) : _migrations = [...migrations]
          ..sort((a, b) => a.version.compareTo(b.version));

  static const String defaultVersionKey = 'storage.schema_version';

  final int currentVersion;
  final String versionKey;
  final List<StorageMigration> _migrations;

  /// The schema version currently stamped in [store] (0 before the first run).
  int storedVersion(KeyValueStore store) => store.getInt(versionKey) ?? 0;

  /// Applies every pending migration in ascending order and returns the version
  /// migrated to. Never downgrades.
  Future<int> run(KeyValueStore store) async {
    var version = storedVersion(store);
    for (final migration in _migrations) {
      if (migration.version <= version || migration.version > currentVersion) {
        continue;
      }
      await migration.migrate(store);
      version = migration.version;
      await store.setInt(versionKey, version);
    }
    if (version < currentVersion) {
      version = currentVersion;
      await store.setInt(versionKey, version);
    }
    return version;
  }
}
