import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late KeyValueStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = KeyValueStore(await SharedPreferences.getInstance());
  });

  test('a fresh install is stamped to the current version', () async {
    final migrator = StorageMigrator(currentVersion: 3);
    expect(migrator.storedVersion(store), 0);

    expect(await migrator.run(store), 3);
    expect(store.getInt(StorageMigrator.defaultVersionKey), 3);
  });

  test('migrates persisted data from an older schema to the current shape',
      () async {
    // Old (v0) shape: a bare string under `greeting`.
    await store.setString('greeting', 'hi');

    final migrator = StorageMigrator(
      currentVersion: 1,
      migrations: [
        StorageMigration(
          version: 1,
          migrate: (s) async {
            final old = s.getString('greeting');
            if (old != null) await s.setJson('greeting', {'text': old, 'v': 1});
          },
        ),
      ],
    );

    expect(await migrator.run(store), 1);
    expect(store.getJson('greeting'), {'text': 'hi', 'v': 1});
    expect(store.getInt(StorageMigrator.defaultVersionKey), 1);
  });

  test('applies steps in ascending version order regardless of list order',
      () async {
    final order = <int>[];
    final migrator = StorageMigrator(
      currentVersion: 3,
      migrations: [
        StorageMigration(version: 3, migrate: (_) async => order.add(3)),
        StorageMigration(version: 1, migrate: (_) async => order.add(1)),
        StorageMigration(version: 2, migrate: (_) async => order.add(2)),
      ],
    );

    await migrator.run(store);
    expect(order, [1, 2, 3]);
  });

  test('does not re-run a migration once the version is stamped', () async {
    var runs = 0;
    StorageMigrator build() => StorageMigrator(
          currentVersion: 1,
          migrations: [
            StorageMigration(version: 1, migrate: (_) async => runs++),
          ],
        );

    await build().run(store); // first cold start
    await build().run(store); // second cold start
    expect(runs, 1);
  });

  test('never downgrades a store stamped by a newer build', () async {
    await store.setInt(StorageMigrator.defaultVersionKey, 5);
    var ran = 0;
    final migrator = StorageMigrator(
      currentVersion: 2,
      migrations: [
        StorageMigration(version: 2, migrate: (_) async => ran++),
      ],
    );

    expect(await migrator.run(store), 5);
    expect(ran, 0);
  });

  test('a migration can reset corrupt data without crashing the cold start',
      () async {
    await store.setString('cache', '{ not valid json');
    final migrator = StorageMigrator(
      currentVersion: 1,
      migrations: [
        StorageMigration(
          version: 1,
          migrate: (s) async {
            // getJson isolates corrupt data (returns null); reset the key.
            if (s.getString('cache') != null && s.getJson('cache') == null) {
              await s.remove('cache');
            }
          },
        ),
      ],
    );

    expect(await migrator.run(store), 1);
    expect(store.getString('cache'), isNull);
  });
}
