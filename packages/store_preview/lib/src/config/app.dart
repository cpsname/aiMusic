import 'package:path/path.dart' as p;

import '../core/errors.dart';
import '../core/fields.dart';
import 'defaults.dart';

/// One App Store storefront localization the app ships previews for.
class Storefront {
  const Storefront({
    required this.id,
    required this.uiLocale,
    required this.simLanguage,
    required this.simLocale,
    required this.asoName,
    required this.asoSubtitle,
    required this.vars,
    this.serves = const [],
  });

  factory Storefront.read(Fields f) {
    f.only({'id', 'ui_locale', 'sim_language', 'sim_locale', 'aso_name', 'aso_subtitle', 'vars', 'serves'});
    final serves = f.strings('serves');
    final id = f.string('id');
    if (serves.toSet().length != serves.length) throw ConfigError('${f.where} › serves: duplicate locale');
    if (serves.contains(id)) throw ConfigError('${f.where} › serves: $id is the storefront itself');
    return Storefront(
      id: id,
      uiLocale: f.string('ui_locale'),
      simLanguage: f.string('sim_language'),
      simLocale: f.string('sim_locale'),
      asoName: f.string('aso_name'),
      asoSubtitle: f.string('aso_subtitle'),
      vars: f.stringMap('vars'),
      serves: serves,
    );
  }

  /// App Store Connect localization, e.g. `pt-BR`; `dist/<app>/<id>/`.
  final String id;

  /// Other App Store Connect localizations of the same language that show
  /// this storefront's previews and creative assets (template ADR-0017),
  /// e.g. `en-US` serving `en-GB`, `en-AU`, `en-CA`. They have no take of
  /// their own: nothing is recorded or rendered for them; the export and the
  /// assets manifest name this storefront's files under their locale.
  final List<String> serves;

  /// [id], then the localizations it [serves].
  List<String> get locales => [id, ...serves];

  /// The app language shown (its ARB's locale), e.g. `pt-BR`, `zh-Hans`.
  final String uiLocale;

  /// Simulator AppleLanguages / AppleLocale.
  final String simLanguage;
  final String simLocale;

  /// The localization's App Store name and subtitle (quoted by the upload
  /// checklist).
  final String asoName;
  final String asoSubtitle;

  /// Values scripts read as `{name}` (e.g. a region preset).
  final Map<String, String> vars;

  /// Han, kana and hangul: half the caption character budget.
  bool get isCjk => const {'ja', 'ko', 'zh'}.contains(uiLocale.split(RegExp('[-_]')).first);
}

/// The caption rules and look (app.yaml `captions`).
class CaptionRules {
  const CaptionRules({
    required this.arbDir,
    required this.arbFile,
    required this.prefix,
    required this.maxChars,
    required this.maxCharsCjk,
    required this.maxDisclosureChars,
    required this.maxDisclosureCharsCjk,
    required this.bannedWords,
    required this.minSeconds,
    required this.maxCps,
    required this.maxCpsCjk,
    required this.plateOpacityMin,
    required this.plateOpacityMax,
    required this.radius,
    this.creativePrefix = 'storeCreative',
    this.creativeMaxChars = 40,
    this.creativeMaxCharsCjk = 20,
  });

  factory CaptionRules.read(Fields f) {
    f.only({
      'arb_dir', 'arb_file', 'prefix', 'max_chars', 'max_chars_cjk', 'max_disclosure_chars', //
      'max_disclosure_chars_cjk', 'banned_words', 'min_seconds', 'max_cps', 'max_cps_cjk', 'plate_opacity', 'radius',
      'creative_prefix', 'creative_max_chars', 'creative_max_chars_cjk',
    });
    final opacity = f.optMap('plate_opacity');
    opacity?.only({'min', 'max'});
    return CaptionRules(
      arbDir: f.string('arb_dir'),
      arbFile: f.optString('arb_file') ?? 'app_{locale}.arb',
      prefix: f.optString('prefix') ?? 'storePreview',
      maxChars: f.optInteger('max_chars', 28),
      maxCharsCjk: f.optInteger('max_chars_cjk', 14),
      maxDisclosureChars: f.optInteger('max_disclosure_chars', 60),
      maxDisclosureCharsCjk: f.optInteger('max_disclosure_chars_cjk', 30),
      bannedWords: f.strings('banned_words'),
      minSeconds: f.optNumber('min_seconds', 1.5),
      maxCps: f.optNumber('max_cps', 17),
      maxCpsCjk: f.optNumber('max_cps_cjk', 9),
      plateOpacityMin: opacity?.optNumber('min', 0.45) ?? 0.45,
      plateOpacityMax: opacity?.optNumber('max', 0.78) ?? 0.78,
      radius: f.optNumber('radius', 0.5),
      creativePrefix: f.optString('creative_prefix') ?? 'storeCreative',
      creativeMaxChars: f.optInteger('creative_max_chars', 40),
      creativeMaxCharsCjk: f.optInteger('creative_max_chars_cjk', 20),
    );
  }

  final String arbDir;

  /// The ARB file of a UI locale: `{locale}` → the locale with `_`
  /// (`app_pt_BR.arb`).
  final String arbFile;
  final String prefix;
  final int maxChars;
  final int maxCharsCjk;
  final int maxDisclosureChars;
  final int maxDisclosureCharsCjk;

  /// Added to the built-in list (the word "free" in many languages).
  final List<String> bannedWords;

  /// On screen at least this long, and read at most this fast
  /// (characters per second).
  final double minSeconds;
  final double maxCps;
  final double maxCpsCjk;

  /// The plate behind a caption darkens with the footage under it.
  final double plateOpacityMin;
  final double plateOpacityMax;

  /// Plate corner radius, as a fraction of the type size.
  final double radius;

  /// The creative assets' phrases (product page header, search results):
  /// their key prefix and length limits (one short phrase; the renderer
  /// also holds it to the layout's line limit).
  final String creativePrefix;
  final int creativeMaxChars;
  final int creativeMaxCharsCjk;

  String arbName(String uiLocale) => arbFile.replaceAll('{locale}', uiLocale.replaceAll('-', '_'));
}

/// The brand on the cards (app.yaml `brand`).
class Brand {
  const Brand({
    required this.name,
    required this.icon,
    required this.primary,
    required this.onPrimary,
    required this.scrim,
    required this.fontFamily,
    required this.fontWeight,
    required this.fontFile,
    required this.ctaKey,
    required this.disclosureKey,
  });

  factory Brand.read(Fields f) {
    f.only({'name', 'icon', 'palette', 'font', 'cta_key', 'disclosure_key'});
    final palette = f.map('palette');
    palette.only({'primary', 'on_primary', 'scrim'});
    final font = f.optMap('font');
    font?.only({'family', 'weight', 'file'});
    String color(String key) {
      final v = palette.string(key);
      if (!RegExp(r'^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$').hasMatch(v)) {
        throw ConfigError('${palette.where} › $key: "$v" is not #RRGGBB or #RRGGBBAA');
      }
      return v.toUpperCase();
    }

    final weight = font?.optString('weight') ?? 'semibold';
    if (!const {'regular', 'medium', 'semibold', 'bold', 'heavy'}.contains(weight)) {
      throw ConfigError('${f.where} › font › weight: "$weight" (regular | medium | semibold | bold | heavy)');
    }
    return Brand(
      name: f.string('name'),
      icon: f.string('icon'),
      primary: color('primary'),
      onPrimary: color('on_primary'),
      scrim: color('scrim'),
      fontFamily: font?.optString('family') ?? 'system',
      fontWeight: weight,
      fontFile: font?.optString('file'),
      ctaKey: f.string('cta_key'),
      disclosureKey: f.optString('disclosure_key'),
    );
  }

  /// The product name, as it appears on the App Store (not localized).
  final String name;

  /// A square PNG of the app icon (repo-relative).
  final String icon;
  final String primary;
  final String onPrimary;
  final String scrim;

  /// `system` (SF Pro and the system's cascade) or a family name; [fontFile]
  /// registers a bundled font first.
  final String fontFamily;
  final String fontWeight;
  final String? fontFile;

  /// The call to action on the end card (an ARB key).
  final String ctaKey;

  /// The purchase disclosure on the end card (an ARB key); required while
  /// the app sells in-app purchases.
  final String? disclosureKey;
}

/// How the app is driven while the simulator films it (app.yaml `driver`).
class DriverConfig {
  const DriverConfig({
    required this.type,
    required this.target,
    required this.dartDefinesFile,
    required this.ready,
    required this.helper,
    required this.timeoutSeconds,
  });

  factory DriverConfig.read(Fields f) {
    f.only({'type', 'target', 'dart_defines_file', 'ready', 'helper', 'timeout_seconds'});
    final type = f.string('type');
    if (type != 'flutter_integration_test') {
      throw ConfigError('${f.where} › type: "$type" (supported: flutter_integration_test)');
    }
    final helper = f.optMap('helper');
    helper?.only({'workspace', 'scheme', 'test'});
    return DriverConfig(
      type: type,
      target: f.string('target'),
      dartDefinesFile: f.optString('dart_defines_file'),
      ready: f.map('ready').raw,
      helper: helper == null
          ? null
          : SystemUiHelper(
              workspace: helper.optString('workspace') ?? 'ios/Runner.xcworkspace',
              scheme: helper.optString('scheme') ?? 'Runner',
              test: helper.optString('test') ?? 'RunnerUITests/StorePreviewHelper/testServe',
            ),
      timeoutSeconds: f.optInteger('timeout_seconds', 1500),
    );
  }

  final String type;

  /// The integration test that runs the plan (repo-relative).
  final String target;

  /// `--dart-define-from-file` for the recording build (repo-relative).
  final String? dartDefinesFile;

  /// A finder (`key`, `widget`, `label`) whose appearance means the app is up.
  final Map<String, Object?> ready;

  /// The XCUITest helper that serves system UI (the photo picker, permission
  /// prompts); `null` when the scripts touch no system UI.
  final SystemUiHelper? helper;

  /// A take that runs longer than this is stopped.
  final int timeoutSeconds;
}

/// The XCUITest helper target (native/ios/StorePreviewHelper.swift).
class SystemUiHelper {
  const SystemUiHelper({required this.workspace, required this.scheme, required this.test});

  final String workspace;
  final String scheme;

  /// `-only-testing:` identifier.
  final String test;
}

/// A call the recorder makes to the app's backend before every take.
class HttpCall {
  const HttpCall({required this.method, required this.path, required this.body});

  factory HttpCall.read(Fields f) {
    f.only({'post', 'get', 'body'});
    final post = f.optString('post');
    final get = f.optString('get');
    if ((post == null) == (get == null)) throw ConfigError('${f.where}: one of post / get');
    return HttpCall(method: post != null ? 'POST' : 'GET', path: post ?? get!, body: f.optMap('body')?.raw);
  }

  final String method;
  final String path;
  final Map<String, Object?>? body;
}

/// A local backend the recordings run against (app.yaml `backend`).
class BackendConfig {
  const BackendConfig({
    required this.start,
    required this.health,
    required this.admin,
    required this.port,
    required this.beforeTake,
  });

  factory BackendConfig.read(Fields f) {
    f.only({'start', 'health', 'admin', 'port', 'before_take'});
    return BackendConfig(
      start: f.string('start'),
      health: f.string('health'),
      admin: f.optString('admin'),
      port: f.integer('port'),
      beforeTake: [for (final c in f.maps('before_take')) HttpCall.read(c)],
    );
  }

  /// Shell command (run from the repo root); `{port}` and `{manifest}` are
  /// filled in.
  final String start;

  /// A URL that answers 200 once the backend is up (`{port}`).
  final String health;

  /// Base URL the plan's `admin` steps post to (`{port}`).
  final String? admin;
  final int port;

  /// Calls made before each take, relative to [admin] (`{manifest}`).
  final List<HttpCall> beforeTake;

  String fill(String text, {required String manifest}) =>
      text.replaceAll('{port}', '$port').replaceAll('{manifest}', manifest);
}

/// The simulator before each take (app.yaml `simulator`).
class SimulatorSetup {
  const SimulatorSetup({
    required this.libraryRole,
    required this.libraryScript,
    required this.keyboardTipsSeen,
    required this.appearance,
    required this.time,
  });

  factory SimulatorSetup.read(Fields? f) {
    f?.only({'library', 'keyboard_tips_seen', 'appearance', 'time'});
    final library = f?.optMap('library');
    library?.only({'role', 'script'});
    final appearance = f?.optString('appearance') ?? 'light';
    if (appearance != 'light' && appearance != 'dark') {
      throw ConfigError('${f!.where} › appearance: light or dark');
    }
    return SimulatorSetup(
      libraryRole: library?.string('role'),
      libraryScript: library?.optString('script'),
      keyboardTipsSeen: f?.boolean('keyboard_tips_seen', fallback: true) ?? true,
      appearance: appearance,
      time: f?.optString('time') ?? '9:41',
    );
  }

  /// Manifest images of this role (and script) for the storefront go into the
  /// photo library — nothing else does (the simulator's samples are removed).
  final String? libraryRole;
  final String? libraryScript;

  /// The one-time keyboard tips ("slide to type", multilingual) marked seen.
  final bool keyboardTipsSeen;
  final String appearance;

  /// The status bar clock.
  final String time;
}

/// Where finished previews go (app.yaml `publish`).
class PublishConfig {
  const PublishConfig({
    required this.listingsDir,
    required this.deviceDirs,
    required this.sharedPosterAt,
    required this.uploadOrder,
    required this.checklistDoc,
  });

  factory PublishConfig.read(Fields? f) {
    f?.only({'listings_dir', 'device_dirs', 'shared_poster_at', 'upload_order', 'checklist_doc'});
    return PublishConfig(
      listingsDir: f?.optString('listings_dir'),
      deviceDirs: f?.stringMap('device_dirs') ?? const {},
      sharedPosterAt: f?.has('shared_poster_at') ?? false ? f!.number('shared_poster_at') : null,
      uploadOrder: f?.strings('upload_order') ?? const [],
      checklistDoc: f?.optString('checklist_doc'),
    );
  }

  /// A store-listing tree (`<dir>/<storefront>/<device dir>/<script>.mp4`),
  /// repo-relative; `export` copies there.
  final String? listingsDir;

  /// slot id → the listing's device directory (`iphone: iphone-6.9`).
  final Map<String, String> deviceDirs;

  /// One poster frame time code for every preview (upload tools that set a
  /// single still frame): it must fall in a finished scene of every script.
  final double? sharedPosterAt;

  /// Script ids in upload order (the first autoplays); default: by id.
  final List<String> uploadOrder;

  /// A repo-relative copy of the upload checklist.
  final String? checklistDoc;
}

/// The narrative and compliance thresholds (app.yaml `rules`).
class Rules {
  const Rules({
    required this.minFootageRatio,
    required this.maxCardSeconds,
    required this.maxCardsTotal,
    required this.requireImageTransition,
  });

  factory Rules.read(Fields? f) {
    f?.only({'min_footage_ratio', 'max_card_seconds', 'max_cards_total', 'require_image_transition'});
    final rules = Rules(
      minFootageRatio: f?.optNumber('min_footage_ratio', defaults.minFootageRatio) ?? defaults.minFootageRatio,
      maxCardSeconds: f?.optNumber('max_card_seconds', defaults.maxCardSeconds) ?? defaults.maxCardSeconds,
      maxCardsTotal: f?.optNumber('max_cards_total', defaults.maxCardsTotal) ?? defaults.maxCardsTotal,
      requireImageTransition: f?.boolean('require_image_transition', fallback: true) ?? true,
    );
    // An app may tighten the thresholds (docs/store/apple-preview-rules.md),
    // never loosen them.
    final where = f?.where ?? 'rules';
    if (rules.minFootageRatio < defaults.minFootageRatio || rules.minFootageRatio > 1) {
      throw ConfigError('$where › min_footage_ratio: ${defaults.minFootageRatio}–1 (it may only be raised)');
    }
    if (rules.maxCardSeconds > defaults.maxCardSeconds || rules.maxCardSeconds <= 0) {
      throw ConfigError('$where › max_card_seconds: at most ${defaults.maxCardSeconds}');
    }
    if (rules.maxCardsTotal > defaults.maxCardsTotal || rules.maxCardsTotal <= 0) {
      throw ConfigError('$where › max_cards_total: at most ${defaults.maxCardsTotal}');
    }
    return rules;
  }

  /// The loosest thresholds the tool accepts.
  static const Rules defaults = Rules(
    minFootageRatio: 0.85,
    maxCardSeconds: 2.0,
    maxCardsTotal: 4.0,
    requireImageTransition: true,
  );

  /// Share of the preview that is full-frame app footage (cards and bridges
  /// are not).
  final double minFootageRatio;
  final double maxCardSeconds;
  final double maxCardsTotal;

  /// At least one bridge or image-backed card per preview.
  final bool requireImageTransition;
}

/// Where the ascpub repository is and which version of its assets-manifest
/// contract this app follows (app.yaml `creatives.ascpub`, template
/// ADR-0010). The contract is read from that checkout, never copied.
class AscpubConfig {
  const AscpubConfig({required this.root, required this.schemaSha256, this.listing});

  factory AscpubConfig.read(Fields f) {
    f.only({'root', 'schema_sha256', 'listing'});
    final sha = f.string('schema_sha256');
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(sha)) throw ConfigError('${f.where} › schema_sha256: 64 lower-case hex digits');
    return AscpubConfig(root: f.string('root'), schemaSha256: sha, listing: f.optString('listing'));
  }

  /// The ascpub checkout, relative to the app repo (the environment variable
  /// `ASCPUB_ROOT` overrides it).
  final String root;

  /// The SHA-256 of the `assets-manifest.schema.json` this app was built
  /// against: a changed contract stops the tool until someone reads the
  /// change and moves the pin.
  final String schemaSha256;

  /// ascpub's listing bundle of the app (`listings/<bundle id>`, relative to
  /// the app repo): `assets.yaml` and `cpp/<slug>.yaml`, the pages the
  /// creative targets name. Needed once a definition targets a custom
  /// product page.
  final String? listing;
}

/// The creative assets' settings (app.yaml `creatives`).
class CreativeConfig {
  const CreativeConfig({required this.authorization, this.ascpub, this.layouts = const {}});

  factory CreativeConfig.read(Fields? f) {
    f?.only({'authorization', 'ascpub', 'layouts'});
    final layouts = f?.optMap('layouts');
    return CreativeConfig(
      authorization: f?.stringMap('authorization') ?? const {},
      ascpub: f?.optMap('ascpub') == null ? null : AscpubConfig.read(f!.map('ascpub')),
      layouts: {for (final a in layouts?.raw.keys ?? const <String>[]) a: layouts!.map(a)},
    );
  }

  /// The ascpub checkout and the contract version (required once the app has
  /// creative definitions).
  final AscpubConfig? ascpub;

  /// Aspect → the app's tightening of that layout (defaults/creative.yaml
  /// `layouts`; only tighter).
  final Map<String, Fields> layouts;

  /// Media role → the assets-manifest `authorization` field its license id
  /// fills (`song: interaction_id`, `lyric_video: mv_id`, `photo:
  /// generation_id`): what the app's generated media are, in the contract's
  /// terms.
  final Map<String, String> authorization;
}

/// `store_preview/<app>/app.yaml`: everything about one app the tool needs.
class PreviewApp {
  const PreviewApp({
    required this.id,
    required this.dir,
    required this.bundleId,
    required this.brand,
    required this.requiresPurchase,
    required this.captions,
    required this.devices,
    required this.slots,
    required this.driver,
    required this.backend,
    required this.prelude,
    required this.onUse,
    required this.simulator,
    required this.storefronts,
    required this.publish,
    required this.rules,
    this.creatives = const CreativeConfig(authorization: {}),
  });

  /// Reads `<root>/store_preview/<id>/app.yaml`.
  factory PreviewApp.load({required String root, required String id, required Map<String, DeviceSlot> slots}) {
    if (!RegExp(r'^[a-z][a-z0-9_-]*$').hasMatch(id)) throw ConfigError('app id must contain lowercase letters, digits, _ or -, and start with a letter');
    final dir = p.join(root, 'store_preview', id);
    final f = readYamlFile(p.join(dir, 'app.yaml'));
    f.only({
      'app', 'bundle_id', 'brand', 'requires_purchase', 'captions', 'devices', 'slots', 'driver', 'backend', //
      'prelude', 'on_use', 'simulator', 'storefronts', 'publish', 'rules', 'creatives',
    });
    if (f.string('app') != id) throw ConfigError('${f.where} › app: must be "$id" (the directory name)');
    final devices = f.strings('devices', fallback: const ['iphone']);
    final slotOverrides = f.optMap('slots');
    final chosen = <String, DeviceSlot>{};
    for (final d in devices) {
      final slot = slots[d] ?? (throw ConfigError('${f.where} › devices: unknown slot "$d" (${slots.keys.join(', ')})'));
      final o = slotOverrides?.optMap(d);
      chosen[d] = o == null ? slot : slot.merged(o);
    }
    final storefronts = [for (final s in f.maps('storefronts', required: true)) Storefront.read(s)];
    if (storefronts.isEmpty) throw ConfigError('${f.where} › storefronts: at least one');
    final ids = storefronts.map((s) => s.id).toSet();
    if (ids.length != storefronts.length) throw ConfigError('${f.where} › storefronts: duplicate id');
    final servedBy = <String, String>{};
    for (final s in storefronts) {
      for (final l in s.serves) {
        if (ids.contains(l)) throw ConfigError('${f.where} › storefronts › ${s.id} › serves: $l is a storefront of its own');
        final other = servedBy[l];
        if (other != null) throw ConfigError('${f.where} › storefronts › ${s.id} › serves: $l is already served by $other');
        servedBy[l] = s.id;
      }
    }
    final requiresPurchase = f.boolean('requires_purchase', fallback: true);
    final brand = Brand.read(f.map('brand'));
    if (requiresPurchase && brand.disclosureKey == null) {
      throw ConfigError('${f.where} › brand › disclosure_key: required while requires_purchase is true '
          '(Apple: features that need an in-app purchase must be disclosed)');
    }
    return PreviewApp(
      id: id,
      dir: dir,
      bundleId: f.string('bundle_id'),
      brand: brand,
      requiresPurchase: requiresPurchase,
      captions: CaptionRules.read(f.map('captions')),
      devices: devices,
      slots: chosen,
      driver: DriverConfig.read(f.map('driver')),
      backend: f.has('backend') ? BackendConfig.read(f.map('backend')) : null,
      prelude: f.steps('prelude'),
      onUse: f.steps('on_use'),
      simulator: SimulatorSetup.read(f.optMap('simulator')),
      storefronts: storefronts,
      publish: PublishConfig.read(f.optMap('publish')),
      rules: Rules.read(f.optMap('rules')),
      creatives: CreativeConfig.read(f.optMap('creatives')),
    );
  }

  final String id;

  /// `<root>/store_preview/<id>` (absolute).
  final String dir;
  final String bundleId;
  final Brand brand;

  /// The app sells in-app purchases or subscriptions: the end card carries
  /// the disclosure.
  final bool requiresPurchase;
  final CaptionRules captions;

  /// Slot ids recorded by default.
  final List<String> devices;
  final Map<String, DeviceSlot> slots;
  final DriverConfig driver;
  final BackendConfig? backend;

  /// Off-camera steps once per take, after the app is up.
  final List<Map<String, Object?>> prelude;

  /// Steps a script's `use` step expands to (`{use.script}`, `{use.locale}`,
  /// `{use.role}`, `{use.id}`): how the app's backend is told which media the
  /// next action produces.
  final List<Map<String, Object?>> onUse;
  final SimulatorSetup simulator;
  final List<Storefront> storefronts;
  final PublishConfig publish;
  final Rules rules;
  final CreativeConfig creatives;

  String get scriptsDir => p.join(dir, 'scripts');
  String get templatesDir => p.join(dir, 'templates');
  String get mediaDir => p.join(dir, 'media');
  String get manifestPath => p.join(mediaDir, 'manifest.json');
  String get captionsDir => p.join(dir, 'captions');
  String get creativesDir => p.join(dir, 'creatives');

  /// The human review of what creative assets show (template ADR-0011).
  String get reviewPath => p.join(dir, 'creative_review.yaml');

  Storefront storefront(String id) =>
      storefronts.firstWhere((s) => s.id == id, orElse: () => throw ConfigError('$id is not a storefront of $this'));

  /// Every App Store Connect localization the app ships media for: each
  /// storefront, then the localizations it serves ([Storefront.serves]).
  List<String> get ascLocales => [for (final s in storefronts) ...s.locales];

  @override
  String toString() => id;
}
