import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Where the library lives: the app's Application Support directory. (The App
/// Group container was dropped with the App Groups capability on 2026-10-04;
/// extensions that need a shared library would bring it back.)
class LibraryLocation {
  Future<Directory>? _root;

  Future<Directory> root() => _root ??= _resolve();

  Future<String> databasePath() async => p.join((await root()).path, 'songlet.db');

  Future<Directory> audioDirectory() => _sub('audio');

  Future<Directory> scratchDirectory() async {
    final dir = Directory(p.join((await getTemporaryDirectory()).path, 'songlet'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _sub(String name) async {
    final dir = Directory(p.join((await root()).path, name));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _resolve() async {
    final base = (await getApplicationSupportDirectory()).path;
    final dir = Directory(p.join(base, 'Library', 'Songlet'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }
}
