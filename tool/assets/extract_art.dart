// Extracts template, occasion and festival art from the design prototypes
// into assets/ (ADR-0014) and writes assets/art_manifest.json (source and
// pixel size of every file). Re-run after the prototypes change:
//
//   dart run tool/assets/extract_art.dart
//
// Replacing art with design-team exports means overwriting the same file
// names; the manifest then records the new sizes on the next run with
// `--manifest-only`.
import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

Future<void> main(List<String> args) async {
  final manifestOnly = args.contains('--manifest-only');
  final spec = jsonDecode(File('tool/assets/art_crops.json').readAsStringSync()) as Map<String, Object?>;
  final quality = spec['quality']! as int;
  final crops = (spec['crops']! as List).cast<Map<String, Object?>>();
  final sources = <String, img.Image>{};
  final manifest = <Map<String, Object?>>[];
  for (final crop in crops) {
    final out = File(crop['out']! as String);
    if (!manifestOnly) {
      final source = sources.putIfAbsent(crop['source']! as String, () {
        final decoded = img.decodeImage(File(crop['source']! as String).readAsBytesSync());
        if (decoded == null) throw StateError('cannot decode ${crop['source']}');
        return decoded;
      });
      final cut = img.copyCrop(
        source,
        x: crop['x']! as int,
        y: crop['y']! as int,
        width: crop['w']! as int,
        height: crop['h']! as int,
      );
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(img.encodeJpg(cut, quality: quality));
    }
    final written = img.decodeJpg(out.readAsBytesSync())!;
    manifest.add({
      'file': out.path,
      'source': crop['source'],
      'width': written.width,
      'height': written.height,
    });
  }
  File('assets/art_manifest.json').writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(manifest)}\n');
  stdout.writeln('wrote ${manifest.length} files');
}
