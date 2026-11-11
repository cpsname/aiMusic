import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/errors.dart';

/// What a credential looks like: key material, cloud and API keys, and a
/// secret-named field holding a long literal.
final List<(String, RegExp)> secretPatterns = [
  ('a private key', RegExp(r'-----BEGIN [A-Z ]*PRIVATE KEY-----')),
  ('an AWS access key', RegExp(r'\bAKIA[0-9A-Z]{16}\b')),
  ('an API key (sk-…)', RegExp(r'\bsk-[A-Za-z0-9_-]{20,}')),
  ('a GitHub token', RegExp(r'\bgh[pousr]_[A-Za-z0-9]{30,}')),
  ('a Slack token', RegExp(r'\bxox[abprs]-[A-Za-z0-9-]{10,}')),
  ('a Google API key', RegExp(r'\bAIza[0-9A-Za-z_-]{35}\b')),
  (
    'a secret-named value',
    RegExp(r'''\b[a-z_]*(secret|password|passwd|api_key|apikey|private_key)[a-z_]*["']?\s*[:=]\s*["'][^"'\s]{12,}["']''', caseSensitive: false),
  ),
];

/// Text files under [paths] (files or directories) that contain a
/// credential. Large binaries (media) are skipped by extension.
Problems scanForSecrets(Iterable<String> paths) {
  final problems = Problems();
  const text = {'.yaml', '.yml', '.json', '.log', '.srt', '.md', '.txt', '.arb', '.dart', '.swift', '.sh'};
  Iterable<File> files(String path) sync* {
    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.file) {
      yield File(path);
    } else if (type == FileSystemEntityType.directory) {
      yield* Directory(path).listSync(recursive: true).whereType<File>();
    }
  }

  for (final path in paths) {
    for (final f in files(path)) {
      if (!text.contains(p.extension(f.path).toLowerCase())) continue;
      final String content;
      try {
        content = f.readAsStringSync();
      } on FileSystemException {
        continue;
      }
      for (final (what, pattern) in secretPatterns) {
        final m = pattern.firstMatch(content);
        if (m != null) {
          final line = '\n'.allMatches(content.substring(0, m.start)).length + 1;
          problems.add('${f.path}:$line holds $what');
        }
      }
    }
  }
  return problems;
}
