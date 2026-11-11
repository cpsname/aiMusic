import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/app.dart';
import '../config/captions.dart';
import '../config/defaults.dart';
import '../config/manifest.dart';
import '../config/script.dart';
import '../core/errors.dart';
import '../core/probe.dart';
import '../creative/check.dart';
import '../creative/contract.dart';
import '../creative/definition.dart';
import '../creative/listing.dart';
import '../creative/media_binding.dart';
import '../creative/review.dart';
import '../creative/shelf.dart';
import '../creative/specs.dart';
import '../narrative/check.dart';
import '../narrative/template.dart';
import '../post/compose.dart';
import '../publish/assets_manifest.dart' show assetsManifestName;
import '../timeline/edl.dart';
import '../validate/compliance.dart';
import '../validate/narrative_output.dart';
import '../validate/report.dart';
import '../validate/secrets.dart';
import '../validate/spec.dart';

/// One app's previews in one repo: its configuration, the tool's defaults
/// and library, and where things go.
class Project {
  Project._({
    required this.root,
    required this.packageRoot,
    required this.app,
    required this.allScripts,
    required this.scripts,
    required this.templates,
    required this.slots,
    required this.encoding,
    required this.allCreatives,
    required this.creatives,
    required this.creativeDefaults,
  });

  /// Loads `store_preview/<appId>` of the repo at [root]; [only] picks the
  /// scripts to work on (default: every script of the app), [onlyCreatives]
  /// the creative definitions (default: all).
  factory Project.load({required String root, required String appId, required String packageRoot, List<String>? only, List<String>? onlyCreatives}) {
    final slots = loadSlots(packageRoot);
    final app = PreviewApp.load(root: root, id: appId, slots: slots);
    final all = loadScripts(app.scriptsDir);
    final creatives = loadCreatives(app.creativesDir);
    return Project._(
      root: root,
      packageRoot: packageRoot,
      app: app,
      allScripts: all,
      scripts: only == null ? all : {for (final id in only) id: all[id] ?? (throw ConfigError('${app.id} has no script $id (${all.keys.join(', ')})'))},
      templates: loadTemplates(packageRoot, appTemplatesDir: app.templatesDir),
      slots: slots,
      encoding: loadEncoding(packageRoot),
      allCreatives: creatives,
      creatives: onlyCreatives == null
          ? creatives
          : {for (final id in onlyCreatives) id: creatives[id] ?? (throw ConfigError('${app.id} has no creative $id (${creatives.keys.join(', ')})'))},
      creativeDefaults: loadCreativeDefaults(packageRoot).forApp(app.creatives.layouts),
    );
  }

  final String root;
  final String packageRoot;
  final PreviewApp app;

  /// Every script of the app (the manifest is checked against these).
  final Map<String, PreviewScript> allScripts;

  /// The scripts this run works on.
  final Map<String, PreviewScript> scripts;
  final Map<String, NarrativeTemplate> templates;
  final Map<String, DeviceSlot> slots;
  final Encoding encoding;

  /// Every creative definition of the app (the assets manifest lists all of
  /// their assets), and those this run renders.
  final Map<String, CreativeDefinition> allCreatives;
  final Map<String, CreativeDefinition> creatives;
  final CreativeDefaults creativeDefaults;

  bool get hasCreatives => allCreatives.isNotEmpty;

  /// The app's ascpub settings (required once it has creative definitions).
  AscpubConfig get ascpub =>
      app.creatives.ascpub ??
      (throw ConfigError('${app.id}: app.yaml creatives.ascpub {root, schema_sha256} names the ascpub checkout whose contract the assets manifest follows'));

  /// The assets-manifest contract, read from the ascpub checkout (on first
  /// use).
  late final ManifestContract contract = ManifestContract.load(ascpubRoot(root, ascpub), pinnedSha256: ascpub.schemaSha256);

  /// ascpub's listing bundle of the app (creatives.ascpub.listing), or null.
  late final AscpubListing? listing = ascpub.listing == null ? null : AscpubListing.load(p.join(root, ascpub.listing!), bundleId: app.bundleId);

  /// Contract target → the shelf its creative definitions declare
  /// (template ADR-0015), over every localization the app ships media for
  /// (ADR-0017); empty when none declares one.
  late final Map<String, Shelf> shelves = deriveShelves(allCreatives.values, app.ascLocales);

  /// The listing with [shelves] in place (`listing --write`), or null when
  /// nothing is shelved.
  late final Map<String, List<MediaSetBinding>> mediaShelves = deriveMediaShelves(allCreatives.values, app.ascLocales);

  AscpubListing? get shelvedListing {
    if (shelves.isEmpty && mediaShelves.isEmpty) return null;
    return listing ?? (throw ConfigError('${app.id}: creatives declare shelves; app.yaml creatives.ascpub.listing names the listing they go into'));
  }

  ReviewLog review() => ReviewLog.load(app.reviewPath);

  /// The slot creative assets take their footage from: the app's first
  /// (the phone).
  String get creativeSlot => app.devices.first;

  String get buildDir => p.join(root, 'build', 'store_preview', app.id);
  String get distDir => p.join(root, 'dist', app.id);

  /// `dist/<app>/assets-manifest.json`: what ascpub reads.
  String get assetsManifestPath => p.join(distDir, assetsManifestName);
  String takeDir(String storefront, String slot) => p.join(buildDir, 'raw', storefront, slot);

  Manifest manifest() => Manifest.load(app.manifestPath);

  /// The on-screen texts of every storefront, from the app's ARBs.
  Map<String, Map<String, String>> textsFromArb() => {for (final s in app.storefronts) s.id: captionsFromArb(root, app, s)};

  /// The exported texts (`captions/<storefront>.json`).
  Map<String, String> texts(String storefront) => readCaptionFile(app.captionsDir, storefront);

  /// Every check that needs no recording: script structure, narrative
  /// template, compliance thresholds on the timeline, texts in every
  /// storefront, the manifest, the brand's files, the driver entry, and no
  /// credential in the app's configuration.
  Problems checkConfig({required Map<String, Map<String, String>> texts, bool withManifest = true, Prober prober = const FfprobeProber()}) {
    final problems = Problems();
    for (final s in allScripts.values) {
      problems.addAll(checkScriptStructure(s, captionPrefix: app.captions.prefix));
      if (s.isCapture) continue;
      problems
        ..addAll(checkNarrative(s, app, templates, texts: texts))
        ..addAll(checkScriptCompliance(s, app));
    }
    problems.addAll(checkCaptions(texts, app, allScripts.values, creatives: allCreatives.values));
    if (hasCreatives) {
      problems.addAll(
        checkCreatives(
          allCreatives,
          app: app,
          scripts: allScripts,
          templates: templates,
          defaults: creativeDefaults,
          contract: contract,
          listing: listing,
          manifest: withManifest ? manifest() : null,
          manifestPath: assetsManifestPath,
        ),
      );
    }
    for (final id in app.publish.uploadOrder) {
      problems.check(allScripts[id]?.isCapture == false, 'publish.upload_order names $id, which is not a preview script');
    }
    problems
      ..check(File(p.join(root, app.brand.icon)).existsSync(), 'brand.icon ${app.brand.icon} does not exist')
      ..check(app.brand.fontFile == null || File(p.join(root, app.brand.fontFile!)).existsSync(), 'brand.font.file ${app.brand.fontFile} does not exist')
      ..check(File(p.join(root, app.driver.target)).existsSync(), 'driver.target ${app.driver.target} does not exist')
      ..check(
        app.driver.dartDefinesFile == null || File(p.join(root, app.driver.dartDefinesFile!)).existsSync(),
        'driver.dart_defines_file ${app.driver.dartDefinesFile} does not exist',
      );
    if (withManifest) problems.addAll(validateManifest(manifest(), app, allScripts, prober: prober));
    problems.addAll(scanForSecrets([p.join(app.dir, 'app.yaml'), app.scriptsDir, app.captionsDir, app.templatesDir, app.creativesDir, app.reviewPath]));
    return problems;
  }

  /// This run's scripts in upload order: publish.upload_order, else by id.
  List<PreviewScript> get ordered => _inUploadOrder(scripts);

  /// Every script of the app in upload order: what a store listing holds,
  /// whichever scripts a run renders (the checklist, export).
  List<PreviewScript> get orderedAll => _inUploadOrder(allScripts);

  /// The previews among [from] (capture scripts are footage, never a
  /// preview), in upload order.
  List<PreviewScript> _inUploadOrder(Map<String, PreviewScript> from) {
    final previews = {
      for (final e in from.entries)
        if (!e.value.isCapture) e.key: e.value,
    };
    final order = app.publish.uploadOrder.isEmpty ? (previews.keys.toList()..sort()) : app.publish.uploadOrder.where(previews.containsKey).toList();
    return [for (final id in order) previews[id]!];
  }

  /// The three layers on every expected output.
  List<OutputReport> checkOutputs({required List<Storefront> storefronts, required List<DeviceSlot> slots, Prober prober = const FfprobeProber()}) {
    final reports = <OutputReport>[];
    for (final s in storefronts) {
      for (final script in ordered) {
        for (final slot in slots) {
          final files = PreviewFiles(p.join(distDir, s.id), script.id, slot);
          final spec = checkSpec(files, script, slot, prober: prober);
          final compliance = Problems();
          final narrative = Problems();
          var footage = '-';
          var poster = '-';
          if (File(files.edl).existsSync()) {
            final edl = Edl.load(files.edl);
            compliance.addAll(checkCompliance(edl, app));
            narrative.addAll(checkNarrativeOutput(edl, app, hookSeconds: templates[script.template]?.hookSeconds ?? 3));
            footage = '${(edl.footageRatio * 100).toStringAsFixed(1)}%';
            final at = edl.segments.where((x) => edl.posterAt >= x.from && edl.posterAt < x.to).firstOrNull;
            poster = '${edl.posterAt}s ${at?.id ?? '?'}';
          } else {
            compliance.add('no EDL — nothing to check');
          }
          compliance.addAll(scanForSecrets([files.edl, files.captions]));
          reports.add(
            OutputReport(
              storefront: s.id,
              script: script.id,
              slot: slot.id,
              spec: spec,
              compliance: compliance,
              narrative: narrative,
              footage: footage,
              poster: poster,
            ),
          );
        }
      }
    }
    return reports;
  }
}
