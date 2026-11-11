import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml_edit/yaml_edit.dart';

import '../core/errors.dart';
import '../core/fields.dart' show plain;
import 'definition.dart';
import 'listing.dart';
import 'media_binding.dart';

/// A page's shelf: ascpub slot (`header`, `search_results`) → the binding its
/// listing must hold.
typedef Shelf = Map<String, SlotBinding>;

/// Contract target → its shelf, from every definition that declares one
/// (template ADR-0015): per slot, the declaration's default and its locales
/// expanded over [storefronts] — the app's App Store Connect localizations,
/// the ones its storefronts serve included (`PreviewApp.ascLocales`);
/// the listing then keeps the localizations each page has
/// ([SlotBinding.within]).
Map<String, Shelf> deriveShelves(Iterable<CreativeDefinition> definitions, List<String> storefronts) {
  final shelves = <String, Shelf>{};
  for (final d in definitions) {
    for (final target in d.targets) {
      for (final MapEntry(key: slot, value: declaration) in d.shelf.entries) {
        final locales = declaration.locales;
        (shelves[target] ??= {})[slot] = SlotBinding(
          defaultId: declaration.defaultId,
          locales: {
            if (locales != null)
              for (final s in storefronts) s: locales.replaceAll('{storefront}', s),
          },
        );
      }
    }
  }
  // The default product page first, then the pages by target.
  final targets = shelves.keys.toList()
    ..sort(
      (a, b) => a == 'app_store_version'
          ? -1
          : b == 'app_store_version'
          ? 1
          : a.compareTo(b),
    );
  return {for (final t in targets) t: shelves[t]!};
}

/// Every shelf declaration against what its definition makes: a known slot,
/// one declaring definition per page and slot, the default a universal asset
/// and the locales an asset made per storefront, both made for the slot's
/// placement.
List<String> checkShelfDeclarations(Iterable<CreativeDefinition> definitions) {
  final problems = <String>[];
  final owners = <String, String>{};
  for (final d in definitions) {
    for (final media in d.mediaShelf) {
      final where = 'creatives/${d.id} shelf.media_sets ${media.key}';
      if (!{'app_screenshot', 'app_preview'}.contains(media.placement)) problems.add('$where: unsupported ordered placement');
      if (media.ids.isEmpty || media.ids.toSet().length != media.ids.length) problems.add('$where: sequence must be nonempty and unique');
      for (final target in d.targets) {
        if (!target.startsWith('custom_product_page:')) problems.add('$where: ordered shelves currently require a CPP target');
        final key = '$target media ${media.key}';
        if (owners.containsKey(key)) problems.add('$where: also declared by ${owners[key]}');
        owners[key] = d.id;
      }
      for (final id in media.ids) {
        final matches = [
          for (final slot in d.slots)
            for (final a in slot.assets)
              if (a.id == id) (slot, a),
        ];
        if (matches.length != 1 ||
            !matches.single.$2.perStorefront ||
            !matches.single.$1.placements.contains(media.placement) ||
            matches.single.$1.displayTarget != media.displayTarget) {
          problems.add('$where: $id must be made for this device, placement and each storefront');
        }
      }
    }
    final made = {
      for (final slot in d.slots)
        for (final a in slot.assets) a.id: (asset: a, placements: slot.placements),
    };
    for (final MapEntry(key: slot, value: declaration) in d.shelf.entries) {
      final where = 'creatives/${d.id} › shelf.$slot';
      final placement = ascpubSlotPlacements[slot];
      if (placement == null) {
        problems.add('$where: not an ascpub slot (${ascpubSlotPlacements.keys.join(', ')})');
        continue;
      }
      for (final target in d.targets) {
        final owner = owners['$target › $slot'];
        if (owner != null) problems.add('$where: $target\'s $slot is also declared by creatives/$owner — one definition stocks a shelf');
        owners['$target › $slot'] = d.id;
      }
      for (final (field, id, perStorefront) in [('default', declaration.defaultId, false), ('locales', declaration.locales, true)]) {
        if (id == null) continue;
        final asset = made[id];
        if (asset == null) {
          problems.add('$where.$field: $id is not an asset of creatives/${d.id} (${made.keys.join(', ')})');
          continue;
        }
        if (asset.asset.perStorefront != perStorefront) {
          problems.add(
            perStorefront
                ? '$where.locales: $id is universal; the locales take an asset made per {storefront}'
                : '$where.default: $id is made per {storefront}; the default shows in every localization, so it is a universal asset',
          );
        }
        if (!asset.placements.contains(placement)) {
          problems.add('$where.$field: $id is made for ${asset.placements.join(', ')}, not $placement');
        }
      }
    }
  }
  return problems;
}

/// Where the listing disagrees with the [shelves]: a page whose binding is
/// not its shelf (on the localizations the page has), and `assets.yaml` ›
/// `manifest` not naming [manifestPath] (the file this checkout writes).
/// Empty when they agree.
List<String> shelfDrift(
  AscpubListing listing,
  Map<String, Shelf> shelves, {
  required String manifestPath,
  required String fix,
  Map<String, List<MediaSetBinding>> mediaShelves = const {},
}) {
  if (shelves.isEmpty && mediaShelves.isEmpty) return const [];
  final problems = <String>[];
  final manifest = listing.manifest;
  final assets = p.join(listing.dir, 'assets.yaml');
  if (manifest == null) {
    problems.add('$assets › manifest: not set; ascpub reads the assets manifest from there — $fix');
  } else if (p.normalize(p.absolute(listing.dir, manifest)) != p.normalize(p.absolute(manifestPath))) {
    problems.add('$assets › manifest: $manifest is not this checkout\'s ${p.relative(manifestPath, from: listing.dir)} — $fix');
  }
  for (final entry in mediaShelves.entries) {
    final page = listing.pages[entry.key];
    if (page == null) continue;
    for (final wanted in entry.value.map((m) => m.within(page.localizations))) {
      final actual = page.mediaSets.where((m) => m.key == wanted.key).firstOrNull;
      if (actual == null || !actual.sameAs(wanted)) problems.add('${page.where} media_sets ${wanted.key}: ordered shelf differs - $fix');
    }
  }
  for (final MapEntry(key: target, value: shelf) in shelves.entries) {
    final page = listing.pages[target];
    if (page == null) continue;
    for (final MapEntry(key: slot, value: declared) in shelf.entries) {
      final wanted = declared.within(page.localizations);
      final actual = page.slots[slot]!;
      if (!actual.sameAs(wanted)) problems.add('${page.where} › $slot: ${actual.differenceFrom(wanted)} — $fix');
    }
  }
  return problems;
}

/// Writes the [shelves] into the listing: each shelved page's slot blocks
/// (its locales limited to the localizations the page has — ascpub places
/// nothing on another, yet would upload what it binds) and `assets.yaml` ›
/// `manifest` ([manifestPath], relative to the listing).
/// Every other field, key order and comment outside those blocks stays as it
/// is; a page the listing lacks is ascpub's to create
/// (`ascpub assets init --cpp <slug> --ppo <slug>`). Returns the files it
/// changed.
List<String> writeShelves(
  AscpubListing listing,
  Map<String, Shelf> shelves, {
  required String manifestPath,
  Map<String, List<MediaSetBinding>> mediaShelves = const {},
}) {
  if (shelves.isEmpty && mediaShelves.isEmpty) return const [];
  final missing = {...shelves.keys, ...mediaShelves.keys}.where((t) => !listing.pages.containsKey(t)).toList();
  if (missing.isNotEmpty) {
    throw ConfigError(
      'ascpub\'s listing (${listing.dir}) declares no page for ${missing.join(', ')} — '
      'the page is ascpub\'s to create: `ascpub assets init --cpp <slug> --ppo <slug>`, then name each treatment',
    );
  }
  final originals = <String, String>{};
  final editors = <String, YamlEditor>{};
  YamlEditor editor(String file) => editors[file] ??= YamlEditor(originals[file] = File(file).readAsStringSync());
  _set(editor(p.join(listing.dir, 'assets.yaml')), ['manifest'], p.relative(manifestPath, from: listing.dir));
  for (final MapEntry(key: target, value: shelf) in shelves.entries) {
    final page = listing.pages[target]!;
    for (final MapEntry(key: slot, value: binding) in shelf.entries) {
      _set(editor(page.file), [...page.node, slot], binding.within(page.localizations).toYaml());
    }
  }
  for (final entry in mediaShelves.entries) {
    final page = listing.pages[entry.key]!;
    // Keep groups this definition does not manage. Never wipe another shelf.
    final managed = entry.value.map((m) => m.key).toSet();
    final sets = [...page.mediaSets.where((m) => !managed.contains(m.key)), ...entry.value.map((m) => m.within(page.localizations))];
    _set(editor(page.file), [...page.node, 'media_sets'], [for (final m in sets) m.toYaml()]);
  }
  final changed = <String>[];
  for (final MapEntry(key: file, value: e) in editors.entries) {
    final text = e.toString();
    if (text == originals[file]) continue;
    File(file).writeAsStringSync(text);
    changed.add(file);
  }
  return changed;
}

/// Sets [value] at [path], creating the maps on the way that are missing. A
/// key added to a map inside a list (a PPO treatment) rewrites that map whole:
/// yaml_edit cannot insert a key into a block map that is a list item.
void _set(YamlEditor editor, List<Object> path, Object value) {
  for (var i = 1; i <= path.length; i++) {
    final at = path.sublist(0, i);
    if (editor.parseAt(at, orElse: () => wrapAsYamlNode(null)).value != null) continue;
    var nested = value;
    for (final key in path.sublist(i).reversed) {
      nested = {key: nested};
    }
    final parent = path.sublist(0, i - 1);
    if (parent.any((k) => k is int)) {
      final map = plain(editor.parseAt(parent).value)! as Map<String, Object?>;
      editor.update(parent, {...map, '${path[i - 1]}': nested});
    } else {
      editor.update(at, nested);
    }
    return;
  }
  editor.update(path, value);
}

Map<String, List<MediaSetBinding>> deriveMediaShelves(Iterable<CreativeDefinition> definitions, List<String> storefronts) {
  final out = <String, List<MediaSetBinding>>{};
  for (final d in definitions) {
    for (final target in d.targets) {
      if (d.mediaShelf.isNotEmpty) (out[target] ??= []).addAll(d.mediaShelf.map((m) => m.expand(storefronts)));
    }
  }
  return out;
}
