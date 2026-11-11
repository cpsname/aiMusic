import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/errors.dart';
import '../core/fields.dart';
import 'media_binding.dart';

/// ascpub's binding slots (`header`, `search_results`) → the contract's
/// placement intent each one binds.
const Map<String, String> ascpubSlotPlacements = {'header': 'product_page_header', 'search_results': 'app_store_search_results'};

/// The asset ids a page binds to one slot: its `default` and its
/// per-localization `locales`.
class SlotBinding {
  const SlotBinding({required this.defaultId, required this.locales});

  /// An empty id binds nothing, as ascpub reads it (`default: ""`,
  /// `locales: {ja: ""}`: the slot is not managed there).
  factory SlotBinding.read(Fields? f) {
    if (f == null) return const SlotBinding(defaultId: null, locales: {});
    String? id(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;
    final locales = f.optMap('locales');
    return SlotBinding(
      defaultId: id(f.raw['default']),
      locales: {for (final MapEntry(:key, :value) in locales?.raw.entries ?? const <MapEntry<String, Object?>>[]) key: ?id(value)},
    );
  }

  /// The binding on a page that has only [localizations] (null: every one):
  /// ascpub places a locale's id only on a localization the page has.
  SlotBinding within(Set<String>? localizations) => localizations == null
      ? this
      : SlotBinding(
          defaultId: defaultId,
          locales: {
            for (final e in locales.entries)
              if (localizations.contains(e.key)) e.key: e.value,
          },
        );

  final String? defaultId;
  final Map<String, String> locales;

  /// The same ids in the same places (the order of `locales` aside).
  bool sameAs(SlotBinding other) =>
      defaultId == other.defaultId && locales.length == other.locales.length && locales.entries.every((e) => other.locales[e.key] == e.value);

  /// The first place where [wanted] differs from this binding, for messages.
  String differenceFrom(SlotBinding wanted) {
    if (defaultId != wanted.defaultId) return 'default is ${defaultId ?? '(empty)'}, the shelf says ${wanted.defaultId ?? '(empty)'}';
    for (final MapEntry(key: locale, value: id) in wanted.locales.entries) {
      if (locales[locale] != id) return 'locales.$locale is ${locales[locale] ?? '(unbound)'}, the shelf says $id';
    }
    final extra = locales.keys.firstWhere((l) => !wanted.locales.containsKey(l));
    return 'locales.$extra binds ${locales[extra]}, the shelf binds nothing there';
  }

  /// The binding as ascpub's listing writes it.
  Map<String, Object> toYaml() => {'default': defaultId ?? '', 'locales': locales};

  /// Every id the slot binds (`where` → id).
  Map<String, String> get ids => {'default': ?defaultId, for (final e in locales.entries) 'locales.${e.key}': e.value};
}

/// One page of ascpub's listing: the default product page (`assets.yaml`
/// `store_page`), a custom product page (`cpp/<slug>.yaml`) or a product page
/// optimization treatment (`ppo/<slug>.yaml` › treatments[name]) — the
/// asset ids it binds per slot.
class ListingPage {
  const ListingPage({
    required this.target,
    required this.file,
    this.node = const [],
    this.label,
    this.localizations,
    required this.slots,
    this.mediaSets = const [],
  });

  /// The contract target that addresses this page.
  final String target;

  /// The YAML file it is written in.
  final String file;

  /// The path to the page's map inside [file] (its slots are keys of it):
  /// `[store_page]`, `[]` for a custom product page, `[treatments, i]`.
  final List<Object> node;

  /// What names it inside [file] (a treatment's name), for messages.
  final String? label;

  /// Where it is written, for messages.
  String get where => label == null ? file : '$file › $label';

  /// The localizations the page has: a custom product page's `locales`, an
  /// optimization's `locales`; null for the default product page (every
  /// localization of the version). Read for the page's shape only — what a
  /// localization says (keywords, promotional text) stays unread.
  final Set<String>? localizations;

  /// ascpub slot (`header`, `search_results`) → its binding.
  final Map<String, SlotBinding> slots;
  final List<MediaSetBinding> mediaSets;
}

/// ascpub's listing bundle of an app, read only for what the creative assets
/// must agree with: which pages exist, the localizations each has, the asset
/// ids they bind and where ascpub reads the manifest. Page names, deep links,
/// keywords and every other field are ascpub's — this tool reads none of them
/// and invents none (template ADR-0009, 0015).
class AscpubListing {
  AscpubListing._(this.dir, this.manifest, this.pages);

  factory AscpubListing.load(String dir, {String? bundleId}) {
    if (bundleId != null) {
      final base = File(p.join(dir, 'base.yaml'));
      final declared = base.existsSync() ? readYamlFile(base.path).optString('bundle_id') : null;
      final folder = p.basename(p.normalize(dir));
      if ((declared != null && declared != bundleId) ||
          (RegExp(r'^[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$').hasMatch(folder) && folder != bundleId)) {
        throw ConfigError('listing bundle mismatch: $dir belongs to ${declared ?? folder}, expected $bundleId; no listing was changed');
      }
    }
    final assets = p.join(dir, 'assets.yaml');
    if (!File(assets).existsSync()) {
      throw ConfigError('$assets: no such file — ascpub\'s listing bundle (`ascpub assets init`) is what the creative targets address');
    }
    Map<String, SlotBinding> slots(Fields f) => {for (final s in ascpubSlotPlacements.keys) s: SlotBinding.read(f.optMap(s))};
    final pages = <String, ListingPage>{};
    final config = readYamlFile(assets);
    final storePage = config.optMap('store_page');
    pages['app_store_version'] = ListingPage(
      target: 'app_store_version',
      file: assets,
      node: const ['store_page'],
      slots: storePage == null ? {for (final s in ascpubSlotPlacements.keys) s: SlotBinding.read(null)} : slots(storePage),
    );
    for (final file in _yamlFiles(p.join(dir, 'cpp'))) {
      final slug = p.basenameWithoutExtension(file);
      final page = readYamlFile(file);
      pages['custom_product_page:$slug'] = ListingPage(
        target: 'custom_product_page:$slug',
        file: file,
        localizations: {...?page.optMap('locales')?.raw.keys},
        slots: slots(page),
        mediaSets: [for (final m in page.maps('media_sets')) MediaSetBinding.read(m)],
      );
    }
    for (final file in _yamlFiles(p.join(dir, 'ppo'))) {
      final slug = p.basenameWithoutExtension(file);
      final test = readYamlFile(file);
      final localizations = test.strings('locales').toSet();
      for (final (i, t) in test.maps('treatments').indexed) {
        final name = t.string('name');
        pages['ppo:$slug:$name'] = ListingPage(
          target: 'ppo:$slug:$name',
          file: file,
          node: ['treatments', i],
          label: name,
          localizations: localizations,
          slots: slots(t),
        );
      }
    }
    final manifest = config.raw['manifest'];
    return AscpubListing._(dir, manifest is String && manifest.trim().isNotEmpty ? manifest.trim() : null, pages);
  }

  final String dir;

  /// `assets.yaml` › `manifest`: where ascpub reads the assets manifest,
  /// relative to [dir] (or absolute); null when it is not set.
  final String? manifest;

  /// Contract target → page.
  final Map<String, ListingPage> pages;

  static List<String> _yamlFiles(String dir) {
    final d = Directory(dir);
    if (!d.existsSync()) return const [];
    return [
      for (final f in d.listSync().whereType<File>())
        if (f.path.endsWith('.yaml')) f.path,
    ]..sort();
  }
}

/// What the creative definitions make, as the listing needs it: an asset id
/// → the targets and placements it is made for.
typedef MadeAssets = Map<String, ({Set<String> targets, Set<String> placements})>;

/// The creative targets against ascpub's listing: every target addresses a
/// page ascpub declares, and every id a page binds is made, for that page
/// and that slot's placement.
List<String> checkListing(AscpubListing listing, MadeAssets made, {required Set<String> targets}) {
  final problems = <String>[];
  for (final t in targets) {
    if (!listing.pages.containsKey(t)) {
      problems.add(
        'target $t: ascpub\'s listing (${listing.dir}) declares no such page '
        '(${listing.pages.keys.join(', ')}) — the page is ascpub\'s to create, not this tool\'s',
      );
    }
  }
  for (final page in listing.pages.values.where((pg) => targets.contains(pg.target))) {
    for (final set in page.mediaSets) {
      for (final ids in set.locales.values) {
        for (final id in ids) {
          final asset = made[id];
          if (asset == null || !asset.targets.contains(page.target) || !asset.placements.contains(set.placement)) {
            problems.add('${page.where} media_sets ${set.key}: $id is not made for this page and placement');
          }
        }
      }
    }
    for (final MapEntry(key: slot, value: binding) in page.slots.entries) {
      final placement = ascpubSlotPlacements[slot]!;
      for (final MapEntry(key: where, value: id) in binding.ids.entries) {
        final asset = made[id];
        if (asset == null) {
          problems.add('${page.where} › $slot.$where binds $id, which no creative definition makes');
        } else if (!asset.targets.contains(page.target) || !asset.placements.contains(placement)) {
          problems.add(
            '${page.where} › $slot.$where binds $id, which is made for ${asset.targets.join(', ')} '
            '(${asset.placements.join(', ')}), not ${page.target} ($placement)',
          );
        }
      }
    }
  }
  return problems;
}
