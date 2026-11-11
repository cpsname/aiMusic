import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:store_preview/store_preview.dart';

/// `store-preview <command>` (packages/store_preview/README.md).
Future<void> main(List<String> args) async {
  final lib = await Isolate.resolvePackageUri(Uri.parse('package:store_preview/store_preview.dart'));
  final packageRoot = p.dirname(p.dirname(lib!.toFilePath()));
  exit(await runCli(args, packageRoot: packageRoot));
}
