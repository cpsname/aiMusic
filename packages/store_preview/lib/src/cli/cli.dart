import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/captions.dart';
import '../config/defaults.dart';
import '../core/errors.dart';
import '../core/process.dart';
import '../creative/composer.dart';
import '../creative/contract.dart' show ascpubRootVariable;
import '../creative/review.dart';
import '../creative/shelf.dart';
import '../driver/fixture_media_server.dart';
import '../publish/export.dart';
import '../publish/vendor.dart';
import '../scaffold/integrate.dart';
import '../scaffold/new_app.dart';
import '../scaffold/new_creatives.dart';
import 'pipeline.dart';
import 'project.dart';

const String usage = '''
store-preview — App Store previews and creative assets (packages/store_preview/README.md)

Usage: dart run store_preview <command> [options]

  render     check the configuration, record every take, compose the previews and render the
             creative assets, validate, write the checklist and the assets manifest
  record     check the configuration and record the takes only
  serve-media  --port <port>: serve licensed media read-only on 127.0.0.1 for offline recordings
  compose    the same from the recorded takes (no recording)
  creatives  render, validate and list the creative assets only, from the recorded takes
  manifest   write dist/<app>/assets-manifest.json (every creative asset, the ascpub contract)
  review     --asset <id> --real-ui true|false --reviewer <name> [--note …]: record a person's
             review of what an asset shows (the manifest's real_ui); without --asset: the status
  listing    the shelves the creatives declare (each page's header and search results, by locale)
             against ascpub's listing; --write puts them in (those blocks and assets.yaml's manifest)
  contract   the assets-manifest contract the app follows: read from ascpub (creatives.ascpub),
             its pin, ascpub's listing pages, ascpub's example against the schema
  validate   the configuration, then every rendered preview and creative asset (spec · compliance ·
             narrative) and the assets manifest
  captions   export the app's caption strings from its ARBs to store_preview/<app>/captions/
  checklist  write dist/<app>/upload-checklist.md (and publish.checklist_doc)
  export     copy the previews into publish.listings_dir, removing retired ones
  new-app    <name>: scaffold store_preview/<name>/ and the driver entry for this repo's app
  integrate  plan this app's pub workspace, dev dependencies and Makefile wiring; --write applies,
             --check fails on missing wiring; existing app configuration and recipes are preserved
  new-creatives  --app <app> [--ascpub <dir>] [--cpp a,b] [--ppo slug:Treatment,…]: scaffold the
             creative assets — the shelf, a counter per custom product page, a variant per treatment
  vendor     --from <template repo>: copy the tool into this repo and stamp it; --check: verify the stamp
  doctor     check the tools and summarize the app's configuration

Options:
  --app <id>              store_preview/<id>/ (required except for new-app, vendor and integrate)
  --scripts A,B           scripts to work on (default: all of the app's)
  --creatives a,b         creative definitions to render (default: all of the app's)
  --only previews|creatives  render/compose/validate: one of the two (default: both)
  --locales all|a,b       storefronts (default: all)
  --devices iphone[,ipad] slots (default: app.yaml devices)
  --root <dir>            the app repo (default: the current directory)
  --config-only           validate: skip the rendered previews
  --from <dir>            vendor: the template checkout
  --bundle-id <id>        new-app: select an identifier when the iOS project declares several
  --ascpub <dir>          new-creatives: the ascpub checkout (default: \$ASCPUB_ROOT)
  --cpp a,b / --ppo s:T   new-creatives: custom product page slugs / optimization treatments
  --listing <dir>         new-creatives: ascpub's listing bundle, repo-relative (default: listings/<bundle id>)
  --check                 vendor: verify the stamp; integrate: require complete workspace/Makefile wiring
  --write                 listing: write the shelves; integrate: apply the integration plan
  --dir                   listing: print the listing's directory (repo-relative) and nothing else

Simulators: each slot records on "Store Preview <bundle>/<app> (<device>)",
created on first use and ERASED by every take; STORE_PREVIEW_SIM_<SLOT> (e.g.
STORE_PREVIEW_SIM_IPHONE=<udid>) picks another one.
''';

class _Args {
  _Args(List<String> args) {
    for (var i = 0; i < args.length; i++) {
      final a = args[i];
      if (!a.startsWith('--')) {
        positional.add(a);
        continue;
      }
      final key = a.substring(2);
      if (const {'config-only', 'check', 'skip-record', 'write', 'dir'}.contains(key)) {
        flags.add(key);
      } else if (i + 1 < args.length) {
        options[key] = args[++i];
      } else {
        throw ConfigError('$a needs a value');
      }
    }
  }

  final List<String> positional = [];
  final Map<String, String> options = {};
  final Set<String> flags = {};

  List<String>? list(String key) => options[key]?.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
}

/// Runs a command; the exit code.
Future<int> runCli(List<String> argv, {required String packageRoot, ProcessRunner runner = const SystemProcessRunner()}) async {
  if (argv.isEmpty || argv.first == '-h' || argv.first == '--help' || argv.first == 'help') {
    stdout.write(usage);
    return 0;
  }
  void say(String line) => stdout.writeln(line);
  try {
    final command = argv.first;
    final args = _Args(argv.sublist(1));
    final root = p.absolute(args.options['root'] ?? Directory.current.path);
    switch (command) {
      case 'integrate':
        final plan = planIntegration(root);
        for (final file in plan.changed) {
          say('  ~ $file');
        }
        if (args.flags.contains('write')) plan.apply();
        if (args.flags.contains('check') && plan.changed.isNotEmpty) {
          throw ConfigError('integration is incomplete: run integrate --write, then flutter pub get');
        }
        say(
          plan.changed.isEmpty
              ? '✓ workspace and Makefile integration is complete'
              : args.flags.contains('write')
              ? '✓ integration written; run flutter pub get, then new-app <name>'
              : 'Integration plan only; integrate --write applies these edits',
        );
        return 0;
      case 'vendor':
        if (args.flags.contains('check')) {
          final drift = vendorDrift(root);
          if (drift != null) throw ConfigError(drift);
          say('✓ the vendored copy matches its stamp');
          return 0;
        }
        final from = args.options['from'] ?? (throw ConfigError('vendor needs --from <template repo>'));
        final stamp = await vendor(from: p.absolute(from), to: root);
        say(
          '✓ vendored ${stamp['files']} files from template ${stamp['template_commit']}${stamp['template_dirty'] == true ? ' (with uncommitted changes)' : ''}',
        );
        return 0;
      case 'new-app':
        final name = args.positional.isEmpty ? throw ConfigError('new-app needs a name') : args.positional.first;
        for (final line in scaffoldApp(root: root, name: name, packageRoot: packageRoot, bundleId: args.options['bundle-id'])) {
          say(line);
        }
        return 0;
      case 'new-creatives':
        final ascpub = args.options['ascpub'] ?? Platform.environment[ascpubRootVariable];
        if (ascpub == null || ascpub.trim().isEmpty) throw ConfigError('new-creatives needs --ascpub <the ascpub checkout> (or \$$ascpubRootVariable)');
        for (final line in scaffoldCreatives(
          root: root,
          appId: args.options['app'] ?? (throw ConfigError('new-creatives needs --app <id>')),
          packageRoot: packageRoot,
          ascpubRoot: p.absolute(ascpub.trim()),
          cpp: args.list('cpp') ?? const [],
          ppo: [for (final t in args.list('ppo') ?? const <String>[]) parseTreatment(t)],
          listing: args.options['listing'],
        )) {
          say(line);
        }
        return 0;
    }

    final appId = args.options['app'] ?? (throw ConfigError('--app <id> is required (store_preview/<id>/)'));
    final project = Project.load(root: root, appId: appId, packageRoot: packageRoot, only: args.list('scripts'), onlyCreatives: args.list('creatives'));
    final only = args.options['only'];
    if (only != null && only != 'previews' && only != 'creatives') throw ConfigError('--only previews or --only creatives');
    final previews = only != 'creatives';
    final creatives = only != 'previews' && project.hasCreatives;
    final app = project.app;
    final locales = args.list('locales');
    final storefronts = locales == null || (locales.length == 1 && locales.single == 'all') ? app.storefronts : [for (final l in locales) app.storefront(l)];
    final devices = args.list('devices') ?? app.devices;
    final slots = <DeviceSlot>[
      for (final d in devices) app.slots[d] ?? (throw ConfigError('${app.id} does not record the $d slot (app.yaml devices: ${app.devices.join(', ')})')),
    ];
    final pipeline = Pipeline(project: project, storefronts: storefronts, slots: slots, say: say, runner: runner);

    switch (command) {
      case 'serve-media':
        pipeline.checkConfiguration();
        final port = int.tryParse(args.options['port'] ?? '');
        if (port == null || port < 1 || port > 65535) {
          throw ConfigError('serve-media needs --port <1..65535>');
        }
        final server = await FixtureMediaServer.start(project.manifest(), port: port);
        final stopped = Completer<void>();
        void stop(ProcessSignal _) {
          if (!stopped.isCompleted) {
            stopped.complete();
          }
        }
        final interrupt = ProcessSignal.sigint.watch().listen(stop);
        final terminate = ProcessSignal.sigterm.watch().listen(stop);
        try {
          say('✓ licensed media at ${server.origin} (read-only; no generator or credentials)');
          await stopped.future;
        } finally {
          await interrupt.cancel();
          await terminate.cancel();
          await server.close();
        }
      case 'contract':
        // The contract this app's assets manifest follows, read from ascpub.
        final contract = project.contract;
        say('✓ ${contract.describe()} at ${p.relative(contract.root, from: root)} — the pin creatives.ascpub.schema_sha256 matches');
        final listing = project.listing;
        if (listing != null) say('  listing ${p.relative(listing.dir, from: root)}: ${listing.pages.keys.join(', ')}');
        final example = contract.violations(contract.example());
        if (example.isNotEmpty) throw ConfigError('ascpub\'s own example breaks its schema:\n${example.join('\n')}');
        say('  ascpub\'s example passes the schema');
      case 'listing':
        if (args.flags.contains('dir')) {
          // For scripts that run ascpub on the app's listing (scripts/asset_library_check.sh).
          final dir = project.listing?.dir ?? (throw ConfigError('${app.id}: app.yaml creatives.ascpub.listing names no listing'));
          say(p.relative(dir, from: root));
          return 0;
        }
        final listing = project.shelvedListing;
        if (listing == null) {
          say('${app.id}: no creative definition declares a shelf (creatives/<id>.yaml › shelf) — the listing\'s bindings are written by hand');
          return 0;
        }
        for (final MapEntry(key: target, value: shelf) in project.shelves.entries) {
          for (final MapEntry(key: slot, value: declared) in shelf.entries) {
            final b = declared.within(listing.pages[target]?.localizations);
            final locales = b.locales.isEmpty ? '' : ' · ${b.locales.length} localization(s): ${b.locales.values.first} …';
            say('  ${target.padRight(34)} ${slot.padRight(15)} default ${b.defaultId ?? '(none)'}$locales');
          }
        }
        for (final entry in project.mediaShelves.entries) {
          for (final set in entry.value) {
            final b = set.within(listing.pages[entry.key]?.localizations);
            say('  ${entry.key} ${set.key} - ${b.locales.length} localizations, ordered');
          }
        }
        final declarations = checkShelfDeclarations(project.allCreatives.values);
        if (declarations.isNotEmpty) throw ConfigError('the shelves: ${declarations.length} problem(s)\n  ${declarations.join('\n  ')}');
        if (args.flags.contains('write')) {
          final changed = writeShelves(listing, project.shelves, mediaShelves: project.mediaShelves, manifestPath: project.assetsManifestPath);
          say(
            changed.isEmpty
                ? '✓ ${p.relative(listing.dir, from: root)} already holds the shelves'
                : '✓ wrote the shelves into ${[for (final f in changed) p.relative(f, from: root)].join(', ')}',
          );
          return 0;
        }
        final drift = shelfDrift(
          listing,
          project.shelves,
          mediaShelves: project.mediaShelves,
          manifestPath: project.assetsManifestPath,
          fix: 'run `listing --app ${app.id} --write`',
        );
        if (drift.isNotEmpty) throw ConfigError('ascpub\'s listing differs from the shelves: ${drift.length} place(s)\n  ${drift.join('\n  ')}');
        say('✓ ${p.relative(listing.dir, from: root)} holds the shelves');
      case 'captions':
        final texts = project.textsFromArb();
        checkCaptions(texts, app, project.allScripts.values).throwIfAny('${app.id}: captions');
        writeCaptionFiles(app.captionsDir, texts);
        say('✓ captions: ${texts.length} storefronts → ${p.relative(app.captionsDir, from: root)}');
      case 'validate':
        final texts = pipeline.checkConfiguration();
        if (args.flags.contains('config-only')) return 0;
        await pipeline.prerequisites(recording: false);
        var ok = true;
        if (previews) {
          ok = pipeline.validate() && ok;
          if (ok) pipeline.checklist(texts);
        }
        if (creatives) {
          if (!pipeline.checkManifest()) return 1;
          ok = await pipeline.validateCreatives() && ok;
        }
        if (!ok) return 1;
      case 'render':
      case 'record':
      case 'compose':
      case 'creatives':
        final texts = pipeline.checkConfiguration();
        await pipeline.prerequisites(recording: command == 'render' || command == 'record');
        if (command == 'render' || command == 'record') await pipeline.record();
        if (command == 'record') return 0;
        var ok = true;
        if (previews && command != 'creatives') {
          say('▶ compose → ${p.relative(project.distDir, from: root)}');
          await pipeline.compose();
          say('▶ validate');
          ok = pipeline.validate();
          if (ok) pipeline.checklist(texts);
        }
        if (creatives || command == 'creatives') {
          if (!project.hasCreatives) throw ConfigError('${app.id} has no creative assets (store_preview/${app.id}/creatives/)');
          say('▶ creative assets → ${p.relative(p.join(project.distDir, 'creative'), from: root)}');
          if (ok) ok = await pipeline.produceCreatives();
        }
        if (!ok) return 1;
      case 'manifest':
        await pipeline.prerequisites(recording: false);
        if (!await pipeline.writeAssetsManifest()) return 1;
      case 'review':
        final log = project.review();
        final reviewJobs = creativeJobs(project.allCreatives, app, storefronts: app.storefronts);
        final asset = args.options['asset'];
        if (asset == null) {
          for (final d in project.allCreatives.values) {
            for (final slot in d.slots) {
              for (final a in slot.assets) {
                final r = log.of(a.id);
                final status = r == null
                    ? 'not reviewed'
                    : reviewJobs.where((j) => j.asset.id == a.id).any((j) => log.realUi(slot, a, files: pipeline.creativeFiles(j)) == null)
                    ? 'STALE (reviewed ${r.date} by ${r.reviewer}; what it shows changed)'
                    : 'real_ui ${r.realUi} (${r.date}, ${r.reviewer})';
                say('  ${a.id.padRight(34)} $status');
              }
            }
          }
          say('Sheets to review: ${p.relative(p.join(project.distDir, 'creative', 'sheets'), from: root)}/');
          return 0;
        }
        final found = [
          for (final d in project.allCreatives.values)
            for (final slot in d.slots)
              for (final a in slot.assets)
                if (a.id == asset) (slot: slot, asset: a),
        ];
        if (found.isEmpty) throw ConfigError('no creative asset "$asset" (an id as written in creatives/*.yaml)');
        final realUi = switch (args.options['real-ui']) {
          'true' => true,
          'false' => false,
          _ => throw ConfigError('review needs --real-ui true|false'),
        };
        final reviewer = args.options['reviewer'] ?? (throw ConfigError('review needs --reviewer <your name>: a review is a person\'s'));
        if (reviewer.trim().isEmpty) throw ConfigError('review needs a nonempty --reviewer');
        final artifacts = {for (final j in reviewJobs.where((j) => j.asset.id == asset)) j.id: renderedReviewBasis(pipeline.creativeFiles(j))};
        final today = DateTime.now();
        String two(int v) => v.toString().padLeft(2, '0');
        log.record(
          CreativeReview(
            asset: asset,
            realUi: realUi,
            reviewer: reviewer,
            date: '${today.year}-${two(today.month)}-${two(today.day)}',
            basis: reviewBasis(found.first.slot, found.first.asset),
            artifacts: artifacts,
            note: args.options['note'],
          ),
        );
        say('✓ ${p.relative(app.reviewPath, from: root)}: $asset real_ui $realUi ($reviewer); `manifest` carries it into the assets manifest');
      case 'checklist':
        pipeline.checklist(project.textsFromArb());
      case 'export':
        for (final line in exportPreviews(project, storefronts: storefronts)) {
          say(line);
        }
      case 'doctor':
        await _doctor(pipeline, project, say);
      default:
        stderr.write('unknown command "$command"\n\n$usage');
        return 64;
    }
    return 0;
  } on ConfigError catch (e) {
    stderr.writeln('✗ $e');
    return 1;
  } on ToolError catch (e) {
    stderr.writeln('✗ $e');
    return 1;
  } on FormatException catch (e) {
    stderr.writeln('✗ malformed configuration: ${e.message}');
    return 1;
  } on FileSystemException catch (e) {
    stderr.writeln('✗ ${e.message}: ${e.path ?? "filesystem operation"}');
    return 1;
  }
}

Future<void> _doctor(Pipeline pipeline, Project project, void Function(String) say) async {
  final app = project.app;
  await pipeline.prerequisites(recording: true);
  say('✓ tools: ffmpeg (aac_at), ffprobe, swiftc, xcrun, flutter, plutil');
  say('  app        ${app.id} (${app.bundleId}), ${app.requiresPurchase ? 'sells in-app purchases (end card discloses)' : 'no purchases'}');
  say(
    '  scripts    ${[for (final s in project.scripts.values) s.isCapture ? '${s.id} capture (${s.scenes.length} scene(s))' : '${s.id} ${s.template}@${s.rhythm}s'].join(' · ')}',
  );
  say('  storefronts ${app.storefronts.map((s) => s.id).join(', ')}');
  say('  slots      ${[for (final d in app.devices) '${app.slots[d]!.id} ${app.slots[d]!.width}×${app.slots[d]!.height}'].join(', ')}');
  say('  driver     ${app.driver.type} ${app.driver.target}${app.driver.helper == null ? '' : ' + ${app.driver.helper!.test}'}');
  say('  backend    ${app.backend == null ? 'none' : app.backend!.start}');
  say('  rules      footage ≥ ${(app.rules.minFootageRatio * 100).round()} %, cards ≤ ${app.rules.maxCardSeconds} s each / ${app.rules.maxCardsTotal} s total');
  if (project.hasCreatives) {
    final contract = project.contract;
    say('  creatives  ${project.allCreatives.keys.join(', ')} (contract: ${contract.describe()})');
  }
}
