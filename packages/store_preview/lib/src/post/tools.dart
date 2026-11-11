import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../core/process.dart';

/// The compiled native helpers (native/*.swift), cached by source hash in
/// the build directory. A build goes to a file of its own and is renamed into
/// place, so builders running at once (parallel test files, two runs) never
/// write the same file.
class NativeTools {
  const NativeTools({required this.cutter, required this.textRenderer});

  final String cutter;
  final String textRenderer;

  static Future<NativeTools> ensure(ProcessRunner runner, {required String packageRoot, required String binDir}) async {
    Directory(binDir).createSync(recursive: true);
    Future<String> build(String name) async {
      final source = p.join(packageRoot, 'native', '$name.swift');
      final hash = sha256.convert(File(source).readAsBytesSync()).toString();
      final binary = p.join(binDir, name);
      final stamp = File('$binary.sha256');
      if (!File(binary).existsSync() || !stamp.existsSync() || stamp.readAsStringSync() != hash) {
        final own = '$binary.$pid.${DateTime.now().microsecondsSinceEpoch}';
        try {
          await runner.run('swiftc', ['-O', source, '-o', own]);
          File(own).renameSync(binary);
          File('$own.sha256')
            ..writeAsStringSync(hash)
            ..renameSync(stamp.path);
        } finally {
          for (final f in [own, '$own.sha256']) {
            if (File(f).existsSync()) File(f).deleteSync();
          }
        }
      }
      return binary;
    }

    return NativeTools(cutter: await build('cut_scenes'), textRenderer: await build('render_text'));
  }
}
