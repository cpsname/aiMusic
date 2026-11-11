import '../config/app.dart';
import '../config/manifest.dart';
import '../config/script.dart';
import '../core/errors.dart';
import '../narrative/check.dart' show frameTolerance;
import '../narrative/template.dart';
import 'contract.dart';
import 'definition.dart';
import 'listing.dart';
import 'shelf.dart';
import 'specs.dart';

/// Every creative definition against everything that needs no recording:
/// targets, ids and tags in the contract's own patterns, the pages ascpub's
/// [listing] declares and the ids they bind, placements and specs, each
/// storefront and each localization it serves an App Store Connect locale,
/// the footage each asset shows, a video's loop template and rhythm, the
/// spec's length window, the poster frame, the muted opening, the phrase, the
/// backdrop and every shown item in the manifest, how each shown item's
/// license reaches the manifest, and the shelves: each declaration against
/// what its definition makes, and the listing holding them with `manifest`
/// naming [manifestPath] (template ADR-0015).
Problems checkCreatives(
  Map<String, CreativeDefinition> definitions, {
  required PreviewApp app,
  required Map<String, PreviewScript> scripts,
  required Map<String, NarrativeTemplate> templates,
  required CreativeDefaults defaults,
  required ManifestContract contract,
  AscpubListing? listing,
  Manifest? manifest,
  String? manifestPath,
}) {
  final problems = Problems();
  final storefronts = [for (final s in app.storefronts) s.id];
  final ids = <String, String>{};
  final fields = contract.authorizationFields;
  final made = <String, ({Set<String> targets, Set<String> placements})>{};
  final targets = {for (final d in definitions.values) ...d.targets};
  for (final d in definitions.values) {
    final where = 'creatives/${d.id}';
    problems.check(d.targets.isNotEmpty, '$where: no targets');
    for (final t in d.targets) {
      problems.check(
        contract.targetPattern.hasMatch(t),
        '$where: target "$t" is not a contract target (app_store_version, custom_product_page:<slug>, ppo:<slug>:<treatment>)',
      );
    }
    final universalFrom = d.universalFrom;
    problems.check(universalFrom == null || storefronts.contains(universalFrom), '$where: universal_from $universalFrom is not a storefront');
    for (final (si, slot) in d.slots.indexed) {
      final at = '$where slot ${si + 1}';
      for (final tag in slot.tags) {
        problems.check(contract.tagPattern.hasMatch(tag), '$at: tag "$tag" does not match the contract (${contract.tagPattern.pattern})');
      }
      final spec = defaults.specs[slot.spec];
      if (spec == null) {
        problems.add('$at: spec ${slot.spec} is not in defaults/creative.yaml (${defaults.specs.keys.join(', ')})');
        continue;
      }
      problems.check(slot.placements.isNotEmpty, '$at: no placements');
      for (final pl in slot.placements) {
        problems.check(contract.placements.contains(pl) && defaults.placements.containsKey(pl), '$at: placement $pl is unknown');
        problems.check(spec.placements.contains(pl), '$at: spec ${spec.id} does not serve $pl (it serves ${spec.placements.join(', ')})');
      }
      problems.check(slot.device == null || app.devices.contains(slot.device), '$at: device ${slot.device} is not an app recording device');
      if (slot.placements.contains('app_screenshot') || slot.placements.contains('app_preview')) {
        problems.check(slot.device != null, '$at: device-specific media must name its recording device');
        problems.check(RegExp(r'^[A-Z][A-Z0-9_]+$').hasMatch(slot.displayTarget), '$at: device-specific media must name its ASC display_target');
      }
      final text = slot.text;
      problems.check(text == null || text.startsWith(app.captions.creativePrefix), '$at: text $text lacks the ${app.captions.creativePrefix} prefix');
      final backdropScript = slot.backdrop.script;
      if (backdropScript == null) {
        problems.add('$at: the backdrop names its script (backdrop: {role, script, index})');
      } else if (manifest != null) {
        for (final s in storefronts) {
          final found = manifest.select(role: slot.backdrop.role, script: backdropScript, locale: slot.backdrop.localeFor(s));
          problems.check(found.length > slot.backdrop.index, '$at: the backdrop ${slot.backdrop} is missing for $s');
        }
      }
      for (final a in slot.assets) {
        final aw = '$where/${a.id}';
        final rule = spec.rule(a.type);
        problems.check(rule != null, '$aw: spec ${spec.id} has no ${a.type}');
        final type = defaults.placements[slot.placements.firstOrNull]?.typeFor(a.type);
        problems.check(contract.types.contains(type), '$aw: type $type is not a contract type');
        for (final s in a.perStorefront ? storefronts : const ['']) {
          final id = a.idFor(s);
          problems.check(contract.idPattern.hasMatch(id), '$aw: id "$id" does not match the contract (${contract.idPattern.pattern})');
          final previous = ids[id];
          problems.check(previous == null, '$aw: id "$id" is also made by $previous');
          ids[id] = aw;
          made[id] = (targets: {...d.targets}, placements: {...slot.placements});
          if (a.perStorefront) {
            problems.check(
              defaults.ascLocales.contains(s),
              '$aw: storefront $s is not an App Store Connect locale — its asset cannot be bound to a localization',
            );
            // The localizations the storefront serves name its asset under
            // their own id (template ADR-0017).
            for (final l in app.storefront(s).serves) {
              final alias = a.idFor(l);
              problems.check(contract.idPattern.hasMatch(alias), '$aw: id "$alias" does not match the contract (${contract.idPattern.pattern})');
              final other = ids[alias];
              problems.check(other == null, '$aw: id "$alias" (served by $s) is also made by $other');
              ids[alias] = '$aw for $l';
              made[alias] = (targets: {...d.targets}, placements: {...slot.placements});
              problems.check(
                defaults.ascLocales.contains(l),
                '$aw: $s serves $l, which is not an App Store Connect locale — its asset cannot be bound to a localization',
              );
            }
          }
        }
        problems.check(!a.perStorefront || text != null, '$aw: made per storefront but its slot has no text (the phrase)');
        final roles = <String>{slot.backdrop.role};
        for (final ref in a.footage) {
          final script = scripts[ref.script];
          final scene = script?.scenes.where((s) => s.id == ref.scene).firstOrNull;
          if (scene == null) {
            problems.add('$aw: footage ${ref.script}/${ref.scene} is not a scene of a script');
            continue;
          }
          for (final shown in [?scene.audio, ...scene.shows]) {
            roles.add(shown.role);
            if (manifest == null) continue;
            for (final s in a.perStorefront ? storefronts : [universalFrom ?? storefronts.first]) {
              final found = manifest.select(role: shown.role, script: shown.scriptFor(script!.id), locale: shown.localeFor(s));
              problems.check(found.length > shown.index, '$aw: ${ref.script}/${ref.scene} shows $shown, missing from the media manifest for $s');
            }
          }
        }
        // Several items may share a field (two songs, four photos): the
        // manifest names the primary scene's first, the EDL every one
        // (template ADR-0014). Each role still needs its field.
        for (final role in roles) {
          final field = app.creatives.authorization[role];
          if (field == null) {
            problems.add('$aw: shows $role media; app.yaml creatives.authorization maps no $role to a manifest field (${fields.join(', ')})');
            continue;
          }
          problems.check(fields.contains(field), 'app.yaml creatives.authorization: $role → $field is not an authorization field (${fields.join(', ')})');
        }
        if (a.isVideo) problems.addAll(_checkLoop(a, aw, slot: slot, rule: rule, scripts: scripts, templates: templates));
      }
    }
  }
  checkShelfDeclarations(definitions.values).forEach(problems.add);
  final shelves = deriveShelves(definitions.values, app.ascLocales);
  final mediaShelves = deriveMediaShelves(definitions.values, app.ascLocales);
  if (listing != null) {
    checkListing(listing, made, targets: targets).forEach(problems.add);
    if (manifestPath != null) {
      shelfDrift(
        listing,
        shelves,
        mediaShelves: mediaShelves,
        manifestPath: manifestPath,
        fix: '`store-preview listing --app ${app.id} --write` writes the shelves',
      ).forEach(problems.add);
    }
  } else {
    const where = 'app.yaml creatives.ascpub.listing names ascpub\'s listing bundle';
    final pages = targets.where((t) => t != 'app_store_version').toList();
    if (pages.isNotEmpty) problems.add('creatives target ${pages.join(', ')}: $where, whose pages these targets address');
    if (shelves.isNotEmpty || mediaShelves.isNotEmpty) {
      problems.add('creatives declare shelves for ${shelves.keys.join(', ')}: $where, which they are written into');
    }
  }
  return problems;
}

Problems _checkLoop(
  CreativeAsset a,
  String aw, {
  required CreativeSlot slot,
  required MediaRule? rule,
  required Map<String, PreviewScript> scripts,
  required Map<String, NarrativeTemplate> templates,
}) {
  final problems = Problems();
  final template = templates[a.template];
  if (template == null || template.format != 'loop') {
    problems.add('$aw: template ${a.template} is not a loop template (${templates.values.where((t) => t.format == 'loop').map((t) => t.id).join(', ')})');
    return problems;
  }
  final rhythm = template.rhythms[a.rhythm];
  if (rhythm == null) {
    problems.add('$aw: ${template.id} has no ${a.rhythm} s rhythm (${template.rhythms.keys.join(' / ')})');
    return problems;
  }
  problems.check(a.scenes.isNotEmpty, '$aw: no scenes');
  problems.check((a.duration - a.rhythm!).abs() < 1e-6, '$aw: the scenes last ${a.duration}s, the ${a.rhythm} s rhythm needs ${a.rhythm}s');
  if (rule?.minSeconds != null) {
    problems.check(
      a.duration >= rule!.minSeconds! - 1e-6 && a.duration <= rule.maxSeconds! + 1e-6,
      '$aw: ${a.duration}s is outside the spec\'s ${rule.minSeconds}–${rule.maxSeconds} s',
    );
  }
  var last = -1;
  final perBeat = <String, double>{};
  var t = 0.0;
  var posterOnFinished = false;
  for (final s in a.scenes) {
    problems.check(s.duration > 0, '$aw: scene ${s.footage} has no duration');
    final beat = template.beat(s.beat);
    if (beat == null) {
      problems.add('$aw: beat "${s.beat}" is not in ${template.id} (${template.beats.map((b) => b.id).join(', ')})');
      continue;
    }
    final index = template.beats.indexOf(beat);
    problems.check(index >= last, '$aw: beat ${beat.id} comes after ${template.beats[last < 0 ? 0 : last].id} in ${template.id}');
    last = index > last ? index : last;
    perBeat[beat.id] = (perBeat[beat.id] ?? 0) + s.duration;
    final scene = scripts[s.footage.script]?.scenes.where((x) => x.id == s.footage.scene).firstOrNull;
    if (beat.finished) {
      problems.check(scene?.finished ?? false, '$aw: beat ${beat.id} shows the finished product; ${s.footage} is not a finished scene');
    }
    final poster = a.posterAt!;
    if (poster >= t - 1e-9 && poster < t + s.duration - 1e-9 && beat.finished && (scene?.finished ?? false)) posterOnFinished = true;
    t += s.duration;
  }
  for (final b in template.beats.where((b) => !b.optional)) {
    problems.check(perBeat.containsKey(b.id), '$aw: the required beat ${b.id} of ${template.id} is missing');
  }
  for (final MapEntry(key: beat, value: seconds) in perBeat.entries) {
    final nominal = rhythm[beat];
    if (nominal == null) {
      problems.add('$aw: beat $beat is not played in the ${a.rhythm} s rhythm of ${template.id}');
      continue;
    }
    problems.check(
      (seconds - nominal).abs() <= template.flex + 1e-6,
      '$aw: beat $beat lasts ${seconds}s, the ${a.rhythm} s rhythm allows $nominal ± ${template.flex}s',
    );
  }
  problems.check(posterOnFinished, '$aw: poster_at ${a.posterAt}s is not inside a finished scene');
  // Muted, the opening must read without a cut: the first scene holds
  // through hook.seconds ("Avoid quick cuts").
  problems.check(
    a.scenes.isEmpty || a.scenes.first.duration >= template.hookSeconds - frameTolerance,
    '$aw: the first scene lasts ${a.scenes.isEmpty ? 0 : a.scenes.first.duration}s; muted, the opening holds one scene for ${template.hookSeconds}s',
  );
  // The muted hook: the phrase from the first frame through hook.seconds —
  // only a per-storefront asset carries one.
  problems.check(
    a.perStorefront && slot.text != null && a.duration >= template.hookSeconds - frameTolerance,
    '$aw: a video explains itself muted from its first frame: it needs its phrase (an id per {storefront} and the slot\'s text)',
  );
  return problems;
}
