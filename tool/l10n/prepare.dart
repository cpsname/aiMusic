import 'dart:convert';
import 'dart:io';

/// gen-l10n requires base-language bundles alongside script/region variants.
/// Keep the 13 reviewed ARBs authoritative; stage internal fallbacks in cache.
void main() {
  final source = Directory('lib/l10n/arb');
  final output = Directory('.dart_tool/songlet_l10n/arb');
  output.createSync(recursive: true);
  final expected = <String>{};
  for (final file in source.listSync().whereType<File>()) {
    if (!file.path.endsWith('.arb')) continue;
    final name = file.uri.pathSegments.last;
    expected.add(name);
    File('${output.path}/$name').writeAsStringSync(file.readAsStringSync());
  }
  for (final entry in {'zh': 'zh_Hans', 'pt': 'pt_BR'}.entries) {
    final resource = jsonDecode(File('${source.path}/app_${entry.value}.arb').readAsStringSync()) as Map<String, dynamic>;
    resource['@@locale'] = entry.key;
    final name = 'app_${entry.key}.arb';
    expected.add(name);
    File('${output.path}/$name').writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(resource)}\n');
  }
  for (final file in output.listSync().whereType<File>()) {
    if (file.path.endsWith('.arb') && !expected.contains(file.uri.pathSegments.last)) file.deleteSync();
  }
}
