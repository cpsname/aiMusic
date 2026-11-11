import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../cli/project.dart';
import '../config/script.dart';
import '../core/errors.dart';
import '../core/file_plan.dart';
import '../creative/contract.dart';
import 'new_app.dart' show appendArbEntries;

/// The phrases the scaffold's shelf shows, with their English copy.
const Map<String, String> creativeScaffoldTexts = {'Header': 'All of it, in one app', 'Search': 'See it in action'};

/// The same where English would break the CJK budget; other languages start
/// from the English and are listed for translation.
const Map<String, Map<String, String>> creativeScaffoldTranslations = {
  'zh': {'Header': '一个应用全搞定', 'Search': '看它怎么用'},
  'zh_Hant': {'Header': '一個應用全搞定', 'Search': '看它怎麼用'},
  'ja': {'Header': 'これひとつで全部', 'Search': '使い方を見る'},
  'ko': {'Header': '하나의 앱으로 모두', 'Search': '사용 모습 보기'},
};

/// A custom product page's slug as an ARB key part (`photo-to-song` →
/// `PhotoToSong`; the phrase is `<prefix>Cpp<PhotoToSong>`).
String pascal(String slug) => slug.split(RegExp('[-_]')).where((w) => w.isNotEmpty).map((w) => w[0].toUpperCase() + w.substring(1)).join();

/// A product page optimization treatment as `<slug>:<treatment name>`.
typedef TreatmentRef = ({String slug, String name});

TreatmentRef parseTreatment(String value) {
  final i = value.indexOf(':');
  final slug = i < 0 ? '' : value.substring(0, i);
  final name = i < 0 ? '' : value.substring(i + 1);
  if (!RegExp(r'^[a-z0-9][a-z0-9-]*$').hasMatch(slug) || !RegExp(r'^[A-Za-z0-9][A-Za-z0-9 _-]*$').hasMatch(name)) {
    throw ConfigError('--ppo $value: <slug>:<treatment> (slug in lower case, digits and -; the treatment as ascpub names it, e.g. header-motion:Video)');
  }
  return (slug: slug, name: name);
}

/// Scaffolds the creative assets of an app made by `new-app` (template
/// ADR-0015): the warehouse (every asset into the assets manifest), the
/// shelf (the default product page's header and search results, by
/// storefront), a counter per custom product page in [cpp] and a shelf
/// variant per product page optimization treatment in [ppo]. It writes
/// `app.yaml` › `creatives` (the ascpub checkout at [ascpubRoot], its
/// contract's SHA-256, the listing — [listing], repo-relative, by default
/// ascpub's `listings/<bundle id>`), a definition per page with its shelf,
/// and the phrases in every ARB. Pages, deep links, keywords and experiments
/// stay ascpub's (`ascpub assets init`). Images only: a video needs footage as
/// long as its loop. Nothing is written when an input is wrong. Returns the
/// lines to print.
List<String> scaffoldCreatives({
  required String root,
  required String appId,
  required String packageRoot,
  required String ascpubRoot,
  List<String> cpp = const [],
  List<TreatmentRef> ppo = const [],
  String? listing,
}) {
  final project = Project.load(root: root, appId: appId, packageRoot: packageRoot);
  final app = project.app;
  final appYaml = File(p.join(app.dir, 'app.yaml'));
  if (RegExp(r'^creatives:', multiLine: true).hasMatch(appYaml.readAsStringSync()) || Directory(app.creativesDir).existsSync()) {
    throw ConfigError('new-creatives: ${app.id} already has creative assets (app.yaml creatives, creatives/) — edit them');
  }
  for (final slug in cpp) {
    if (!RegExp(r'^[a-z0-9][a-z0-9-]*$').hasMatch(slug)) throw ConfigError('--cpp $slug: lower case letters, digits and -');
  }
  if (cpp.toSet().length != cpp.length) throw ConfigError('--cpp ${cpp.join(',')}: a custom product page is named once');
  final treatments = <String, TreatmentRef>{};
  for (final t in ppo) {
    parseTreatment('${t.slug}:${t.name}');
    final other = treatments['${t.slug}:${_fileKey(t.name)}'];
    if (other != null) throw ConfigError('--ppo ${t.slug}:${t.name}: the same treatment as ${other.slug}:${other.name} (one definition file each)');
    treatments['${t.slug}:${_fileKey(t.name)}'] = t;
  }
  final schema = File(p.join(ascpubRoot, contractSourceDir, contractSchemaFile));
  if (!schema.existsSync()) {
    throw ConfigError('new-creatives: no ascpub checkout at $ascpubRoot (--ascpub <dir> or \$$ascpubRootVariable): its $contractSourceDir holds the contract');
  }
  final sha = sha256.convert(schema.readAsBytesSync()).toString();
  final fields = ManifestContract.load(ascpubRoot, pinnedSha256: sha).authorizationFields;

  final storefronts = [for (final s in app.storefronts) s.id];
  final manifest = project.manifest();
  final backdrop = [
    for (final e in manifest.entries)
      if (e.type == 'image') (role: e.role, script: e.script),
  ].where((r) => storefronts.every((s) => manifest.select(role: r.role, script: r.script, locale: s).isNotEmpty)).firstOrNull;
  if (backdrop == null) {
    throw ConfigError(
      'new-creatives: ${p.relative(app.manifestPath, from: root)} holds no licensed image for every storefront '
      '(${storefronts.join(', ')}): each asset stands on one (README › Media) — add it, then run new-creatives again',
    );
  }
  final script =
      project.allScripts.values.where((s) => !s.isCapture).firstOrNull ??
      (throw ConfigError('new-creatives: ${app.id} has no preview script to take footage from'));
  final scenes = script.scenes.toList();
  final hero = scenes.where((s) => s.finished).firstOrNull ?? scenes.first;
  final other = scenes.where((s) => s != hero).firstOrNull ?? hero;
  // Licensed media the chosen scenes show besides the backdrop: each role
  // needs its authorization field, which only the app knows.
  final shownRoles = {
    for (final s in {hero, other}) ...[?s.audio?.role, ...s.shows.map((m) => m.role)],
  }..remove(backdrop.role);
  String frame(SceneSegment s) => '{script: ${script.id}, scene: ${s.id}, at: ${(s.duration / 2).toStringAsFixed(1)}}';

  final prefix = app.captions.creativePrefix;
  final lines = <String>[];
  final plan = FilePlan(root);
  void write(String path, String content) {
    plan.set(p.relative(path, from: root), content);
    lines.add('  + ${p.relative(path, from: root)}');
  }

  String definition({
    required String id,
    required String comment,
    required String title,
    required String target,
    required List<String> tags,
    required String header,
    required String headerText,
    required SceneSegment headerScene,
    String? search,
    String? searchText,
  }) =>
      '''
# $comment
id: $id
title: ${jsonEncode(title)}
targets: [${jsonEncode(target)}]
backdrop: {role: ${backdrop.role}, script: ${backdrop.script}, index: 0}
tags: [${tags.map(jsonEncode).join(', ')}]

# What the page shows in each of ascpub's slots, by storefront; `store-preview
# listing --app ${app.id} --write` puts it into the listing (template ADR-0015).
shelf:
  header: {locales: "$header.{storefront}"}${search == null ? '' : '\n  search_results: {locales: "$search.{storefront}"}'}

slots:
  - placements: [product_page_header]
    spec: header_21x9
    text: $headerText
    assets:
      - {id: "$header.{storefront}", type: image, frame: ${frame(headerScene)}}
${search == null ? '' : '''
  - placements: [app_store_search_results]
    spec: search_3x2
    text: $searchText
    assets:
      - {id: "$search.{storefront}", type: image, frame: ${frame(hero)}}
'''}''';

  final texts = <String, String>{'${prefix}Header': 'Header', '${prefix}Search': 'Search'};
  write(
    p.join(app.creativesDir, 'store-page.yaml'),
    definition(
      id: 'store-page',
      comment: 'The shelf: the default product page\'s header and search results, per storefront.',
      title: 'Default product page — header and search results',
      target: 'app_store_version',
      tags: ['page:default'],
      header: 'header',
      headerText: '${prefix}Header',
      headerScene: hero,
      search: 'search',
      searchText: '${prefix}Search',
    ),
  );
  for (final slug in cpp) {
    texts['${prefix}Cpp${pascal(slug)}'] = slug;
    write(
      p.join(app.creativesDir, 'cpp-$slug.yaml'),
      definition(
        id: 'cpp-$slug',
        comment: 'A counter: the custom product page cpp/$slug.yaml in ascpub\'s listing (its name, deep link and keywords live there).',
        title: 'Custom product page "$slug"',
        target: 'custom_product_page:$slug',
        tags: ['cpp:$slug'],
        header: 'cpp.$slug.header',
        headerText: '${prefix}Cpp${pascal(slug)}',
        headerScene: hero,
        search: 'cpp.$slug.search',
        searchText: '${prefix}Cpp${pascal(slug)}',
      ),
    );
  }
  for (final t in ppo) {
    final key = _fileKey(t.name);
    write(
      p.join(app.creativesDir, 'ppo-${t.slug}-$key.yaml'),
      definition(
        id: 'ppo-${t.slug}-$key',
        comment:
            'A shelf variant: treatment "${t.name}" of the product page optimization ppo/${t.slug}.yaml in ascpub\'s listing '
            '(its hypothesis, traffic and variable live there). It changes the header only; the original is the shelf.',
        title: 'Product page optimization ${t.slug} — ${t.name}',
        target: 'ppo:${t.slug}:${t.name}',
        tags: ['ppo:${t.slug}'],
        header: 'ppo.${t.slug}.$key.header',
        headerText: '${prefix}Header',
        headerScene: other,
      ),
    );
  }

  final listingDir = listing ?? 'listings/${app.bundleId}';
  final block =
      '''

# Creative assets (packages/store_preview README › Creative assets; template
# ADR-0009–0015). ascpub owns the assets-manifest contract (read from its
# checkout, \$$ascpubRootVariable overrides root, pinned by SHA-256) and the
# listing's pages; the shelves in creatives/ are written into the listing.
creatives:
  ascpub:
    root: ${jsonEncode(p.relative(ascpubRoot, from: root))}
    schema_sha256: $sha
    listing: ${jsonEncode(listingDir)}
  # A generated image's license id is its generation id.
  authorization: {${backdrop.role}: generation_id}
''';
  plan.set(p.relative(appYaml.path, from: root), '${appYaml.readAsStringSync().trimRight()}\n$block');
  lines.add('  ~ ${p.relative(appYaml.path, from: root)}: creatives');

  final untranslated = <String>[];
  for (final s in app.storefronts) {
    final file = File(p.join(root, app.captions.arbDir, app.captions.arbName(s.uiLocale)));
    final relative = p.relative(file.path, from: root);
    final arbText = plan.read(relative)!;
    final arb = (jsonDecode(arbText) as Map).cast<String, Object?>();
    final locale = s.uiLocale.replaceAll('-', '_');
    final copy = creativeScaffoldTranslations[locale] ?? creativeScaffoldTranslations[locale.split('_').first];
    final english = <String>[];
    final added = <String, Object?>{};
    for (final MapEntry(:key, :value) in texts.entries) {
      if (arb.containsKey(key)) continue;
      final translated = copy?[value];
      if (translated == null) english.add(key);
      added[key] = translated ?? creativeScaffoldTexts[value] ?? 'Made for ${value.replaceAll('-', ' ')}';
      if (s == app.storefronts.first) added['@$key'] = {'description': 'App Store creative asset phrase (store_preview/${app.id}/creatives).'};
    }
    if (added.isEmpty) continue;
    plan.set(relative, appendArbEntries(arbText, added));
    lines.add('  ~ ${p.relative(file.path, from: root)}: ${added.keys.where((k) => !k.startsWith('@')).length} key(s)');
    if (s != app.storefronts.first && english.isNotEmpty) untranslated.add('${p.basename(file.path)} (${english.join(', ')})');
  }

  final listingsRoot = p.dirname(listingDir);
  final asc =
      'ascpub assets init${listingsRoot == 'listings' ? '' : ' -l $listingsRoot'} -b ${p.basename(listingDir)}'
      '${[
        for (final s in cpp) ' --cpp $s',
        for (final t in {...ppo.map((t) => t.slug)}) ' --ppo $t',
      ].join()}';
  final steps = [
    'in ascpub\'s listing (run from this repo): $asc',
    if (cpp.isNotEmpty) '   fill each cpp/<slug>.yaml: name, locales (the localizations the page has; keywords from the approved version), deep link',
    if (ppo.isNotEmpty) '   fill each ppo/<slug>.yaml: name, hypothesis, locales, and treatments named ${ppo.map((t) => '"${t.name}"').join(', ')}',
    if (shownRoles.isNotEmpty) 'map ${shownRoles.join(', ')} in app.yaml creatives.authorization (${fields.join(' / ')}): the chosen scenes show them',
    'dart run store_preview listing --app ${app.id} --write',
    if (untranslated.isNotEmpty) 'translate the English phrases added to ${untranslated.join('; ')}',
    'dart run store_preview captions --app ${app.id}; dart run store_preview validate --app ${app.id} --config-only',
    'dart run store_preview render --app ${app.id} (or creatives on recorded takes), then review, manifest',
    'make asset-library APP=${app.id}',
  ];
  var n = 0;
  plan.apply();
  return [
    '✓ creative assets for ${app.id}: the shelf (store-page), ${cpp.length} counter(s), ${ppo.length} treatment(s); '
        'backdrop ${backdrop.role} from ${backdrop.script}, footage from ${script.id}',
    ...lines,
    '',
    'Next (docs/store/asset-library-playbook.zh-CN.md):',
    for (final step in steps) step.startsWith('   ') ? '   $step' : '  ${++n}. $step',
  ];
}

/// A treatment name as a file and id part (`Video B` → `video-b`).
String _fileKey(String name) => name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-');
