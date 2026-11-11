import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../core/errors.dart';
import '../core/file_plan.dart';
import '../driver/flutter_driver.dart';

/// UI locale (ARB) → App Store Connect localization, simulator language and
/// locale. Locales not listed map to themselves (`xx` → `xx`, `xx_XX`).
const Map<String, (String, String, String)> _locales = {
  'en': ('en-US', 'en', 'en_US'),
  'en_US': ('en-US', 'en', 'en_US'),
  'en_GB': ('en-GB', 'en-GB', 'en_GB'), //
  'zh': ('zh-Hans', 'zh-Hans', 'zh_CN'),
  'zh_Hans': ('zh-Hans', 'zh-Hans', 'zh_CN'),
  'zh_Hant': ('zh-Hant', 'zh-Hant', 'zh_TW'),
  'ja': ('ja', 'ja', 'ja_JP'),
  'ko': ('ko', 'ko', 'ko_KR'),
  'de': ('de-DE', 'de', 'de_DE'),
  'fr': ('fr-FR', 'fr', 'fr_FR'),
  'es': ('es-ES', 'es', 'es_ES'),
  'es_MX': ('es-MX', 'es-MX', 'es_MX'),
  'pt': ('pt-PT', 'pt-PT', 'pt_PT'),
  'pt_BR': ('pt-BR', 'pt-BR', 'pt_BR'),
  'it': ('it', 'it', 'it_IT'),
  'ru': ('ru', 'ru', 'ru_RU'),
  'ar': ('ar-SA', 'ar', 'ar_SA'),
  'hi': ('hi', 'hi', 'hi_IN'),
  'id': ('id', 'id', 'id_ID'),
  'vi': ('vi', 'vi', 'vi_VN'),
  'tr': ('tr', 'tr', 'tr_TR'),
  'th': ('th', 'th', 'th_TH'),
  'nl': ('nl-NL', 'nl', 'nl_NL'),
  'sv': ('sv', 'sv', 'sv_SE'),
  'pl': ('pl', 'pl', 'pl_PL'),
  'nb': ('no', 'nb', 'nb_NO'), 'no': ('no', 'nb', 'nb_NO'),
  'da': ('da', 'da', 'da_DK'), 'ms': ('ms', 'ms', 'ms_MY'),
};

/// The caption keys the scaffold script shows, with their English copy.
const Map<String, String> scaffoldTexts = {
  'storePreviewAIntro': 'Everything in one app',
  'storePreviewAHook': 'Start right here',
  'storePreviewAFeature2': 'Then go further',
  'storePreviewAFeature3': 'And make it yours',
  'storePreviewCta': 'Try it today',
  'storePreviewDisclosure': 'Some features require a subscription',
};

/// The same copy where English would break the CJK caption budget (half the
/// characters); other languages start from the English and are listed for
/// translation.
const Map<String, Map<String, String>> scaffoldTranslations = {
  'zh': {
    'storePreviewAIntro': '一个应用全搞定',
    'storePreviewAHook': '从这里开始',
    'storePreviewAFeature2': '再进一步', //
    'storePreviewAFeature3': '做成你的风格',
    'storePreviewCta': '今天就试试',
    'storePreviewDisclosure': '部分功能需要订阅',
  },
  'zh_Hant': {
    'storePreviewAIntro': '一個應用全搞定',
    'storePreviewAHook': '從這裡開始',
    'storePreviewAFeature2': '再進一步', //
    'storePreviewAFeature3': '做成你的風格',
    'storePreviewCta': '今天就試試',
    'storePreviewDisclosure': '部分功能需要訂閱',
  },
  'ja': {
    'storePreviewAIntro': 'これひとつで全部',
    'storePreviewAHook': 'ここから始めよう',
    'storePreviewAFeature2': 'さらにその先へ', //
    'storePreviewAFeature3': '自分らしく仕上げる',
    'storePreviewCta': '今すぐ試そう',
    'storePreviewDisclosure': '一部の機能はサブスクリプションが必要です',
  },
  'ko': {
    'storePreviewAIntro': '하나의 앱으로 모두',
    'storePreviewAHook': '여기서 시작하세요',
    'storePreviewAFeature2': '한 걸음 더', //
    'storePreviewAFeature3': '나만의 스타일로',
    'storePreviewCta': '지금 사용해 보세요',
    'storePreviewDisclosure': '일부 기능은 구독이 필요합니다',
  },
};

/// The scaffold copy for an ARB locale (`zh`, `zh_Hans`, `ja`, `en`, …).
Map<String, String> scaffoldTextsFor(String locale) => scaffoldTranslations[locale] ?? scaffoldTranslations[locale.split('_').first] ?? scaffoldTexts;

/// The facts `new-app` reads from the repo.
class RepoFacts {
  const RepoFacts({
    required this.package,
    required this.displayName,
    required this.bundleId,
    required this.families,
    required this.icon,
    required this.arbDir,
    required this.arbPattern,
    required this.uiLocales,
    required this.definesFile,
  });

  final String package;
  final String displayName;
  final String bundleId;
  final Set<int> families;
  final String icon;
  final String arbDir;

  /// `app_{locale}.arb`.
  final String arbPattern;

  /// ARB locales (`en`, `pt_BR`).
  final List<String> uiLocales;
  final String? definesFile;
}

/// Reads [root]: pubspec name, iOS bundle id, device families, display
/// name, app icon, the l10n setup and its ARBs.
RepoFacts readRepo(String root, {String? bundleId}) {
  String read(String path) {
    final f = File(p.join(root, path));
    if (!f.existsSync()) throw ConfigError('new-app: $path not found — run it from a Flutter app repo on the template');
    return f.readAsStringSync();
  }

  final pubspec = loadYaml(read('pubspec.yaml')) as YamlMap;
  final pbxproj = read('ios/Runner.xcodeproj/project.pbxproj');
  final bundles = {
    for (final m in RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = "?([^";]+)"?;').allMatches(pbxproj))
      if (!m.group(1)!.contains('Tests')) m.group(1)!,
  };
  if (bundles.isEmpty) throw ConfigError('new-app: no app bundle identifier in ios/Runner.xcodeproj');
  if (bundleId == null && bundles.length != 1) {
    throw ConfigError('new-app: multiple app bundle identifiers (${bundles.join(', ')}); select the intended target with --bundle-id');
  }
  final selectedBundle = bundleId ?? bundles.single;
  if (!bundles.contains(selectedBundle) || !RegExp(r'^[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$').hasMatch(selectedBundle)) {
    throw ConfigError('new-app: --bundle-id must select a concrete identifier declared in ios/Runner.xcodeproj');
  }
  final plist = read('ios/Runner/Info.plist');
  final display =
      RegExp(r'<key>CFBundleDisplayName</key>\s*<string>([^<]+)</string>').firstMatch(plist)?.group(1) ??
      RegExp(r'<key>CFBundleName</key>\s*<string>([^<]+)</string>').firstMatch(plist)?.group(1) ??
      '${pubspec['name']}';
  const iconDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  final icons = Directory(p.join(root, iconDir)).existsSync()
      ? (Directory(p.join(root, iconDir)).listSync().whereType<File>().where((f) => f.path.endsWith('.png')).toList()
          ..sort((a, b) => b.lengthSync().compareTo(a.lengthSync())))
      : <File>[];
  if (icons.isEmpty) throw ConfigError('new-app: no app icon PNG in $iconDir');
  final l10nFile = File(p.join(root, 'l10n.yaml'));
  final l10n = l10nFile.existsSync() ? loadYaml(l10nFile.readAsStringSync()) as YamlMap? : null;
  final arbDir = '${l10n?['arb-dir'] ?? 'lib/l10n'}';
  final template = '${l10n?['template-arb-file'] ?? 'app_en.arb'}';
  final templateLocale =
      RegExp(r'_([a-zA-Z]{2,3}(?:_[a-zA-Z]+)?)\.arb$').firstMatch(template)?.group(1) ?? (throw ConfigError('new-app: cannot read the locale of $template'));
  final pattern = template.replaceFirst('_$templateLocale.arb', '_{locale}.arb');
  final prefix = pattern.substring(0, pattern.indexOf('{locale}'));
  final arbs = Directory(
    p.join(root, arbDir),
  ).listSync().whereType<File>().map((f) => p.basename(f.path)).where((n) => n.startsWith(prefix) && n.endsWith('.arb'));
  final locales = [for (final n in arbs) n.substring(prefix.length, n.length - 4)]
    ..sort(
      (a, b) => a == templateLocale
          ? -1
          : b == templateLocale
          ? 1
          : a.compareTo(b),
    );
  final defines = ['config/dev.json', 'config/mock.json'].where((f) => File(p.join(root, f)).existsSync()).firstOrNull;
  return RepoFacts(
    package: '${pubspec['name']}',
    displayName: display,
    bundleId: selectedBundle,
    families: declaredDeviceFamilies(pbxproj),
    icon: p.relative(icons.first.path, from: root),
    arbDir: arbDir,
    arbPattern: pattern,
    uiLocales: locales,
    definesFile: defines,
  );
}

String _q(String v) => jsonEncode(v);

/// Several UI ARBs may describe the same ASC localization. Prefer the more
/// specific locale (zh_Hans/en_US) and modern Norwegian Bokmål (nb) rather
/// than generating duplicate storefronts or overwriting exported captions.
List<String> scaffoldUiLocales(RepoFacts facts) {
  final chosen = <String, String>{};
  int rank(String locale) => locale == 'nb'
      ? 2
      : locale.contains('_')
      ? 1
      : 0;
  for (final locale in facts.uiLocales) {
    final asc = _locales[locale]?.$1 ?? locale.replaceAll('_', '-');
    final old = chosen[asc];
    if (old == null || rank(locale) > rank(old)) chosen[asc] = locale;
  }
  return chosen.values.toList();
}

/// [entries] appended to the ARB [text] before its closing brace, leaving
/// every existing line as it was written (an ARB is hand-formatted; a
/// re-encode would reflow it).
String appendArbEntries(String text, Map<String, Object?> entries) {
  final end = text.lastIndexOf('}');
  if (end < 0) throw ConfigError('an ARB is not a JSON object');
  final body = text.substring(0, end).trimRight();
  final lines = [for (final e in entries.entries) '  ${jsonEncode(e.key)}: ${const JsonEncoder.withIndent('  ').convert(e.value).replaceAll('\n', '\n  ')}'];
  final joiner = body.endsWith('{') ? '\n' : ',\n';
  final out = '$body$joiner${lines.join(',\n')}\n}\n';
  jsonDecode(out);
  return out;
}

String appYaml(String name, RepoFacts f) {
  final storefronts = StringBuffer();
  for (final l in scaffoldUiLocales(f)) {
    final (asc, language, locale) = _locales[l] ?? (l.replaceAll('_', '-'), l.replaceAll('_', '-'), l.contains('_') ? l : '${l}_${l.toUpperCase()}');
    storefronts.writeln(
      '  - {id: $asc, ui_locale: ${l.replaceAll('_', '-')}, sim_language: $language, sim_locale: $locale, '
      'aso_name: ${_q(f.displayName)}, aso_subtitle: ${_q(f.displayName)}}',
    );
  }
  return '''
# App Store previews of ${f.displayName} (packages/store_preview/README.md).
# Generated by `store-preview new-app $name`; edit freely — `store-preview
# validate --app $name --config-only` checks every field.
app: $name
bundle_id: ${f.bundleId}

# The cards: icon and name, the palette (#RRGGBB), the call to action and the
# purchase disclosure (ARB keys). `font: {family, weight, file}` sets a
# bundled font; the default is the system font.
brand:
  name: ${_q(f.displayName)}
  icon: ${f.icon}
  palette: {primary: "#1F6FEB", on_primary: "#FFFFFF", scrim: "#000000"}
  cta_key: storePreviewCta
  disclosure_key: storePreviewDisclosure

# The app sells in-app purchases or subscriptions: the end card discloses it.
requires_purchase: true

# On-screen text comes from these ARBs (keys starting with the prefix).
captions:
  arb_dir: ${f.arbDir}
  arb_file: ${f.arbPattern}
  banned_words: []

# Slots recorded: iphone (886x1920).${f.families.contains(2) ? ' The app ships for iPad too: add ipad (1200x1600) once its scripts are rehearsed there.' : ''}
devices: [iphone]

driver:
  type: flutter_integration_test
  target: integration_test/store_preview_test.dart${f.definesFile == null ? '' : '\n  dart_defines_file: ${f.definesFile}'}
  # A widget that appears once the app is up: replace it with the key of the
  # app's first screen (a ValueKey<String>), e.g. {key: home}.
  ready: {widget: Scaffold}
  # Scripts that use the photo picker or answer a notification prompt need the
  # XCUITest helper (README › System UI): helper: {}

# The previews show only app footage plus the cards; turn the image
# transition rule on once media/manifest.json holds a licensed image.
rules:
  require_image_transition: false

# One entry per App Store localization: its name and subtitle as they read on
# the App Store (the upload checklist quotes them), the simulator language and
# locale, and `vars` the scripts read as {name}.
storefronts:
${storefronts.toString().trimRight()}
''';
}

const String scriptA = '''
# Script A — three features in 15 s (feature_triptych, packages/store_preview/
# templates). Replace each scene's steps with what a user does on that screen
# (README › Steps) and its caption with what it shows.
id: A
title: Everything in one app
template: feature_triptych
rhythm: 15
poster_at: 3
soundtrack: none
segments:
  - card: intro
    duration: 0.8
    text: storePreviewAIntro
  - scene: first
    beat: feature1
    duration: 4.2
    finished: true
    steps:
      - {do: pause, ms: 4200}
  - scene: second
    beat: feature2
    duration: 4.2
    steps:
      - {do: pause, ms: 4200}
  - scene: third
    beat: feature3
    duration: 4.4
    steps:
      - {do: pause, ms: 4400}
  - card: outro
    duration: 1.4
captions:
  - {key: storePreviewAHook, from: 0.8, to: 5.0}
  - {key: storePreviewAFeature2, from: 5.0, to: 9.2}
  - {key: storePreviewAFeature3, from: 9.2, to: 13.6}
''';

String driverEntry(String package, String name) {
  // Sorted, as the lints' directives_ordering wants them.
  final imports = ["import 'package:$package/main.dart' as app;", "import 'package:store_preview_driver/store_preview_driver.dart';"]..sort();
  return '''
${imports.join('\n')}

/// App Store preview recordings (store_preview/$name/): `store-preview render
/// --app $name` hands this test its plan. Register this app's own steps and
/// playback readers in the registry (packages/store_preview/README.md › Steps).
void main() => storePreviewTest(appMain: app.main, registry: StepRegistry());
''';
}

/// Scaffolds `store_preview/<name>/` in the app repo at [root]: app.yaml from
/// the repo's facts, a 15 s feature-triptych script, an empty manifest, the
/// caption keys in every ARB (English copy where a key is missing), the
/// exported captions and the driver entry. Returns the lines to print.
List<String> scaffoldApp({required String root, required String name, required String packageRoot, String? bundleId}) {
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) throw ConfigError('new-app: "$name" — lower case letters, digits and _');
  final dir = Directory(p.join(root, 'store_preview', name));
  if (dir.existsSync()) throw ConfigError('new-app: ${dir.path} exists');
  final facts = readRepo(root, bundleId: bundleId);
  final plan = FilePlan(root);
  final selectedLocales = scaffoldUiLocales(facts).toSet();
  final lines = <String>[];
  void write(String relative, String content) {
    plan.set(relative, content);
    lines.add('  + $relative');
  }

  write('store_preview/$name/app.yaml', appYaml(name, facts));
  write('store_preview/$name/scripts/A.yaml', scriptA);
  write('store_preview/$name/media/manifest.json', '${const JsonEncoder.withIndent('  ').convert({'schema': 2, 'entries': <Object>[]})}\n');

  final untranslated = <String>[];
  final exported = <String, Map<String, String>>{};
  for (final locale in facts.uiLocales) {
    final arbName = facts.arbPattern.replaceAll('{locale}', locale);
    final file = File(p.join(root, facts.arbDir, arbName));
    final arb = (jsonDecode(file.readAsStringSync()) as Map).cast<String, Object?>();
    final added = <String>[];
    final copy = scaffoldTextsFor(locale);
    for (final e in copy.entries) {
      if (arb.containsKey(e.key)) continue;
      arb[e.key] = e.value;
      if (locale == facts.uiLocales.first) arb['@${e.key}'] = {'description': 'App Store preview text (store_preview/$name).'};
      added.add(e.key);
    }
    if (added.isNotEmpty) {
      plan.set(
        p.relative(file.path, from: root),
        appendArbEntries(file.readAsStringSync(), {
          for (final k in added) ...{k: arb[k], if (arb.containsKey('@$k')) '@$k': arb['@$k']},
        }),
      );
      lines.add('  ~ ${facts.arbDir}/$arbName: ${added.length} key(s)');
      if (locale != facts.uiLocales.first && identical(copy, scaffoldTexts)) untranslated.add('$arbName (${added.length})');
    }
    final (asc, _, _) = _locales[locale] ?? (locale.replaceAll('_', '-'), '', '');
    if (selectedLocales.contains(locale)) {
      exported[asc] = {
        for (final e in arb.entries)
          if (e.key.startsWith('storePreview') && e.value is String) e.key: e.value! as String,
      };
    }
  }
  for (final e in exported.entries) {
    final sorted = Map.fromEntries(e.value.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    write('store_preview/$name/captions/${e.key}.json', '${const JsonEncoder.withIndent('  ').convert(sorted)}\n');
  }
  const entry = 'integration_test/store_preview_test.dart';
  if (File(p.join(root, entry)).existsSync()) {
    lines.add('  = $entry exists (kept)');
  } else {
    write(entry, driverEntry(facts.package, name));
  }
  lines
    ..insert(0, '✓ store_preview/$name for ${facts.displayName} (${facts.bundleId}), storefronts ${facts.uiLocales.join(', ')}')
    ..addAll([
      '',
      'Next (README › New app):',
      '  1. verify workspace and development wiring: dart run store_preview integrate --check',
      '  2. driver.ready: the key of the app\'s first screen; the scenes\' steps; the captions\' copy',
      if (untranslated.isNotEmpty) '  3. translate the English copy added to ${untranslated.join(', ')}',
      '  ${untranslated.isEmpty ? 3 : 4}. dart run store_preview validate --app $name --config-only',
      '  ${untranslated.isEmpty ? 4 : 5}. dart run store_preview render --app $name --scripts A --locales ${_locales[facts.uiLocales.first]?.$1 ?? facts.uiLocales.first}',
    ]);
  plan.apply();
  return lines;
}
