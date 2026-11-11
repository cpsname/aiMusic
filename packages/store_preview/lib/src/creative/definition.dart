import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/script.dart';
import '../core/errors.dart';
import '../core/fields.dart';
import 'media_binding.dart';

/// A moment or stretch of a scene in a storefront's take: the footage a
/// creative asset shows. [from] counts from the scene's filmed start, or from
/// its end when negative (`-2.5` = the last 2.5 s); footage always plays in
/// real time.
class FootageRef {
  const FootageRef({required this.script, required this.scene, required this.from});

  final String script;
  final String scene;
  final double from;

  @override
  String toString() => '$script/$scene${from == 0 ? '' : '@$from'}';
}

/// One scene of a creative video: [footage] for [duration] seconds, playing
/// the loop template's [beat].
class CreativeScene {
  const CreativeScene({required this.beat, required this.footage, required this.duration});

  factory CreativeScene.read(Fields f) {
    f.only({'beat', 'script', 'scene', 'from', 'duration'});
    return CreativeScene(
      beat: f.string('beat'),
      footage: FootageRef(script: f.string('script'), scene: f.string('scene'), from: f.optNumber('from', 0)),
      duration: f.number('duration'),
    );
  }

  final String beat;
  final FootageRef footage;
  final double duration;
}

/// One asset of a slot: an image (one frame of footage) or a video (a loop of
/// scenes). Its [id] holds `{storefront}` when it is made per storefront (with
/// the slot's phrase, `locale` = the storefront); without it the asset is
/// universal (`locale` null, no text: one picture for every language).
class CreativeAsset {
  const CreativeAsset({required this.id, required this.type, this.frame, this.template, this.rhythm, this.posterAt, this.scenes = const []});

  factory CreativeAsset.read(Fields f) {
    final type = f.string('type');
    if (type == 'image') {
      f.only({'id', 'type', 'frame'});
      final frame = f.map('frame')..only({'script', 'scene', 'at'});
      return CreativeAsset(
        id: f.string('id'),
        type: type,
        frame: FootageRef(script: frame.string('script'), scene: frame.string('scene'), from: frame.number('at')),
      );
    }
    if (type != 'video') throw ConfigError('${f.where} › type: image or video');
    f.only({'id', 'type', 'template', 'rhythm', 'poster_at', 'scenes'});
    return CreativeAsset(
      id: f.string('id'),
      type: type,
      template: f.string('template'),
      rhythm: f.integer('rhythm'),
      posterAt: f.number('poster_at'),
      scenes: [for (final s in f.maps('scenes', required: true)) CreativeScene.read(s)],
    );
  }

  /// The manifest entry id; `{storefront}` = the storefront id.
  final String id;

  /// `image` or `video`.
  final String type;

  /// image: the frame (`from` = seconds into the scene, negative from its end).
  final FootageRef? frame;

  /// video: the loop template and rhythm, the poster frame, the scenes.
  final String? template;
  final int? rhythm;
  final double? posterAt;
  final List<CreativeScene> scenes;

  bool get perStorefront => id.contains('{storefront}');
  bool get isVideo => type == 'video';

  double get duration => scenes.fold(0, (t, s) => t + s.duration);

  String idFor(String? storefront) => perStorefront ? id.replaceAll('{storefront}', storefront!) : id;

  /// Every footage reference the asset shows.
  Iterable<FootageRef> get footage => isVideo ? scenes.map((s) => s.footage) : [frame!];
}

/// A placement (or several, for a universal spec) with its spec, phrase,
/// backdrop and assets.
class CreativeSlot {
  const CreativeSlot({
    this.device,
    this.displayTarget = 'universal',
    required this.placements,
    required this.spec,
    required this.text,
    required this.backdrop,
    required this.tags,
    required this.assets,
  });

  final String? device;
  final String displayTarget;
  final List<String> placements;
  final String spec;

  /// The phrase (an ARB key with the creative prefix); per-storefront assets
  /// show it, universal ones show none.
  final String? text;
  final MediaRef backdrop;
  final List<String> tags;
  final List<CreativeAsset> assets;
}

/// What a page shows in one of ascpub's slots (`header`, `search_results`),
/// declared by the definition that makes it: [defaultId], a universal asset,
/// for every localization without its own, and [locales], an id with
/// `{storefront}`, for each storefront's localization. The listing's binding
/// is derived from it (template ADR-0015).
class ShelfDeclaration {
  const ShelfDeclaration({required this.defaultId, required this.locales});

  factory ShelfDeclaration.read(Fields f) {
    f.only({'default', 'locales'});
    final declaration = ShelfDeclaration(defaultId: f.optString('default'), locales: f.optString('locales'));
    if (declaration.defaultId == null && declaration.locales == null) {
      throw ConfigError('${f.where}: a shelf names its default (a universal asset), its locales (an id with {storefront}) or both');
    }
    return declaration;
  }

  final String? defaultId;
  final String? locales;
}

/// `store_preview/<app>/creatives/<id>.yaml`: the creative assets for some
/// targets (the default product page, a custom product page, a product page
/// optimization treatment).
class CreativeDefinition {
  const CreativeDefinition({
    required this.id,
    required this.title,
    required this.targets,
    required this.universalFrom,
    required this.slots,
    this.shelf = const {},
    this.mediaShelf = const [],
  });

  final String id;
  final String title;

  /// The contract's placement targets: `app_store_version`,
  /// `custom_product_page:<slug>` (the slug = ascpub's `cpp/<slug>.yaml`),
  /// `ppo:<slug>:<treatment>`.
  final List<String> targets;

  /// The storefront whose take and media a universal asset shows.
  final String? universalFrom;
  final List<CreativeSlot> slots;

  /// ascpub slot → what every target's page shows there; empty = the
  /// listing's bindings for these pages are written by hand.
  final Map<String, ShelfDeclaration> shelf;
  final List<MediaShelfDeclaration> mediaShelf;
}

CreativeDefinition loadCreative(String path) {
  final f = readYamlFile(path);
  f.only({'id', 'title', 'targets', 'universal_from', 'backdrop', 'text', 'tags', 'shelf', 'slots'});
  final id = f.string('id');
  if (id != p.basenameWithoutExtension(path)) throw ConfigError('${f.where} › id: must equal the file name');
  final backdrop = f.has('backdrop') ? MediaRef.read(f.map('backdrop')) : null;
  final text = f.optString('text');
  final tags = f.strings('tags');
  final shelf = f.optMap('shelf');
  final slots = <CreativeSlot>[];
  for (final s in f.maps('slots', required: true)) {
    s.only({'device', 'display_target', 'placements', 'spec', 'text', 'backdrop', 'tags', 'assets'});
    final slotBackdrop = s.has('backdrop') ? MediaRef.read(s.map('backdrop')) : backdrop;
    slots.add(
      CreativeSlot(
        device: s.optString('device'),
        displayTarget: s.optString('display_target') ?? 'universal',
        placements: s.strings('placements'),
        spec: s.string('spec'),
        text: s.optString('text') ?? text,
        backdrop: slotBackdrop ?? (throw ConfigError('${s.where}: no backdrop (set it on the slot or the definition)')),
        tags: [...tags, ...s.strings('tags')],
        assets: [for (final a in s.maps('assets', required: true)) CreativeAsset.read(a)],
      ),
    );
  }
  return CreativeDefinition(
    id: id,
    title: f.string('title'),
    targets: f.strings('targets'),
    universalFrom: f.optString('universal_from'),
    slots: slots,
    mediaShelf: [for (final m in shelf?.maps('media_sets') ?? const <Fields>[]) MediaShelfDeclaration.read(m)],
    shelf: {
      for (final slot in shelf?.raw.keys ?? const <String>[])
        if (slot != 'media_sets') slot: ShelfDeclaration.read(shelf!.map(slot)),
    },
  );
}

/// The app's creative definitions (none when it has no `creatives/`).
Map<String, CreativeDefinition> loadCreatives(String dir) {
  final d = Directory(dir);
  if (!d.existsSync()) return {};
  final files = d.listSync().whereType<File>().where((f) => f.path.endsWith('.yaml')).toList()..sort((a, b) => a.path.compareTo(b.path));
  return {for (final f in files) p.basenameWithoutExtension(f.path): loadCreative(f.path)};
}
