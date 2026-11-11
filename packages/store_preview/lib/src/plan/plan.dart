import 'dart:convert';

import '../config/app.dart';
import '../config/manifest.dart';
import '../config/script.dart';
import '../core/errors.dart';

/// The recording plan of one storefront's take: what the app's
/// integration test runs (`STORE_PREVIEW_PLAN`), the system-UI helper's
/// picker sessions and whether it answers a notification prompt.
class RecordingPlan {
  RecordingPlan(this.json, this.picks, {required this.allowNotifications});

  final Map<String, Object?> json;

  /// Picker sessions in order, `<count>@<offset>`.
  final List<String> picks;
  final bool allowNotifications;

  /// The take needs the system-UI helper.
  bool get needsHelper => picks.isNotEmpty || allowNotifications;

  /// `--dart-define=STORE_PREVIEW_PLAN=…`.
  String get encoded => base64.encode(utf8.encode(jsonEncode(json)));
}

/// A `{name}` in a step's strings.
final RegExp _variable = RegExp(r'\{([a-z0-9_.]+)\}');

/// Compiles [scripts] for [storefront].
///
/// Steps pass through as written, except:
/// * `{do: use, role, script?, locale?, index?}` selects a manifest entry —
///   the variables of later steps read it — and expands to app.yaml's
///   `on_use` steps (`{use.script}`, `{use.locale}`, `{use.role}`,
///   `{use.id}` filled in);
/// * `{do: pickPhotos, count, offset?}` gets its session number for the
///   system-UI helper;
/// * `{name}` in strings is filled from the selected entry's `vars`, then the
///   entry's storefront `vars`, then this storefront's `vars`, then
///   `storefront` (its id) and `script` (the running script's id). A string
///   that is exactly one integer-valued variable becomes the integer.
///
/// Scripts run in the given order, those that end on system UI last; scenes
/// in filming order.
RecordingPlan compilePlan({
  required PreviewApp app,
  required Storefront storefront,
  required Iterable<PreviewScript> scripts,
  required Manifest manifest,
  required String syncDir,
}) {
  final picks = <String>[];
  MediaEntry? used;
  late String scriptId;

  String? lookup(String name) {
    if (name == 'storefront') return storefront.id;
    if (name == 'script') return scriptId;
    final entry = used;
    final fromEntry = entry?.vars[name];
    if (fromEntry != null) return fromEntry;
    if (entry != null) {
      final owner = app.storefronts.where((s) => s.id == entry.locale).firstOrNull;
      final fromOwner = owner?.vars[name];
      if (fromOwner != null) return fromOwner;
    }
    return storefront.vars[name];
  }

  Object? fill(Object? v, {Map<String, String> extra = const {}}) {
    switch (v) {
      case String():
        final whole = _variable.matchAsPrefix(v);
        String value(Match m) {
          final name = m.group(1)!;
          return extra[name] ??
              lookup(name) ??
              (throw ConfigError('${storefront.id}/$scriptId: no value for {$name}'
                  '${used == null ? ' (no "use" step has selected media yet)' : ' in ${used!.id} or the storefront'}'));
        }

        if (whole != null && whole.end == v.length) {
          final text = value(whole);
          return int.tryParse(text) ?? text;
        }
        return v.replaceAllMapped(_variable, value);
      case Map():
        return {for (final e in v.entries) '${e.key}': fill(e.value, extra: extra)};
      case List():
        return [for (final e in v) fill(e, extra: extra)];
      default:
        return v;
    }
  }

  List<Map<String, Object?>> steps(List<Map<String, Object?>> raw) => [
    for (final step in raw)
      ...switch (step['do']) {
        'use' => () {
          final ref = MediaRef(
            role: '${step['role'] ?? (throw ConfigError('$scriptId: a use step needs role'))}',
            script: step['script'] as String?,
            locale: step['locale'] as String?,
            index: (step['index'] as int?) ?? 0,
          );
          final entry = manifest.resolve(ref, script: scriptId, storefront: storefront.id);
          used = entry;
          final extra = {'use.script': entry.script, 'use.locale': entry.locale, 'use.role': entry.role, 'use.id': entry.id};
          return [for (final s in app.onUse) fill(s, extra: extra)! as Map<String, Object?>];
        }(),
        'pickPhotos' => () {
          final count = step['count'];
          final offset = step['offset'] ?? 0;
          if (count is! int || offset is! int) throw ConfigError('$scriptId: pickPhotos needs integer count (and offset)');
          picks.add('$count@$offset');
          return [
            {...step, 'session': picks.length - 1},
          ];
        }(),
        _ => [fill(step)! as Map<String, Object?>],
      },
  ];

  final ordered = [...scripts.where((s) => !s.endsOnSystemUi), ...scripts.where((s) => s.endsOnSystemUi)];
  final runs = <Map<String, Object?>>[];
  for (final script in ordered) {
    scriptId = script.id;
    used = null;
    final setup = steps(script.setup);
    final scenes = <Map<String, Object?>>[
      for (final scene in script.shootingOrder)
        {
          'id': scene.id,
          'duration': scene.duration,
          'locked': !scene.retime,
          'follow': scene.follow,
          'before': steps(scene.before),
          'steps': steps(scene.steps),
        },
    ];
    runs.add({'script': script.id, 'setup': setup, 'scenes': scenes});
  }
  scriptId = 'prelude';
  used = null;
  final prelude = steps(app.prelude);
  final allowNotifications = jsonEncode(runs).contains('"name":"alert.done"');
  return RecordingPlan(
    {
      'storefront': storefront.id,
      'admin': app.backend?.admin == null ? null : app.backend!.fill(app.backend!.admin!, manifest: manifest.path),
      'sync': syncDir,
      'ready': app.driver.ready,
      'prelude': prelude,
      // After the "ready" mark the recorder starts the system-UI helper;
      // nothing is filmed before it has handed the foreground back.
      'afterReady': [
        if (picks.isNotEmpty || allowNotifications) {'do': 'waitHelper'},
      ],
      'runs': runs,
    },
    picks,
    allowNotifications: allowNotifications,
  );
}
