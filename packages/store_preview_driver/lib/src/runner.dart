import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'finder.dart';

/// An app step: what `{do: <name>, …}` means in this app.
typedef StepHandler = Future<void> Function(StepContext context, Map<String, dynamic> step);

/// The playback position (seconds) at [at] of what a scene follows
/// (`follow: <name>`).
typedef PositionReader = Future<double> Function(StepContext context, DateTime at);

/// Where marks go (the recorder reads them from the test log).
typedef MarkSink = void Function(Map<String, Object?> mark);

/// The line prefix of a mark (the tool's `markTag`).
const String markTag = 'STORE_PREVIEW_MARK ';

void printMark(Map<String, Object?> mark) {
  // The recorder reads these lines from the test log.
  // ignore: avoid_print
  print('$markTag${jsonEncode(mark)}');
}

/// The built-in steps (any app, any plan).
const Set<String> builtInSteps = {
  'pause', 'waitFor', 'waitGone', 'tap', 'type', 'submit', 'dismissKeyboard', 'scrollTo', 'fling', 'pop', //
  'admin', 'pickPhotos', 'waitSync', 'waitHelper', 'screenshot',
};

/// The app's own steps and playback readers.
class StepRegistry {
  final Map<String, StepHandler> _steps = {};
  final Map<String, PositionReader> _positions = {};

  /// Registers `{do: name}`. A built-in step cannot be redefined: a plan
  /// means the same thing in every app.
  void step(String name, StepHandler handler) {
    if (builtInSteps.contains(name)) throw ArgumentError('"$name" is a built-in step');
    if (_steps.containsKey(name)) throw ArgumentError('step "$name" is registered twice');
    _steps[name] = handler;
  }

  /// Registers the reader of `follow: name`.
  void position(String name, PositionReader reader) {
    if (_positions.containsKey(name)) throw ArgumentError('position "$name" is registered twice');
    _positions[name] = reader;
  }

  StepHandler? stepFor(String name) => _steps[name];
  PositionReader? positionFor(String name) => _positions[name];
}

/// Runs a recording plan (the tool's `STORE_PREVIEW_PLAN`) in the app under
/// test, printing scene marks; the app's integration test is one call:
///
/// ```dart
/// void main() => storePreviewTest(appMain: app.main, registry: myAppSteps());
/// ```
void storePreviewTest({
  required void Function() appMain,
  StepRegistry? registry,
  String plan = const String.fromEnvironment('STORE_PREVIEW_PLAN'),
}) {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Animations run in real time, as on a user's device: the recording is the
  // product.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('store preview recording', (tester) async {
    if (plan.isEmpty) {
      markTestSkipped('STORE_PREVIEW_PLAN not set: run by store-preview recordings');
      return;
    }
    final json = jsonDecode(utf8.decode(base64.decode(plan))) as Map<String, dynamic>;
    // The real keyboard: text goes in through the field's controller, so the
    // screen shows what a user sees while typing.
    tester.binding.testTextInput.unregister();
    appMain();
    await PlanRunner(tester, json, registry: registry ?? StepRegistry()).runAll();
  }, timeout: const Timeout(Duration(minutes: 30)));
}

/// Runs a plan: waits for the app, runs the prelude, every script's setup
/// and scenes, and marks each scene's edges.
class PlanRunner {
  PlanRunner(this.tester, this.plan, {required this.registry, this.mark = printMark});

  final WidgetTester tester;
  final Map<String, dynamic> plan;
  final StepRegistry registry;
  final MarkSink mark;

  late final StepContext context = StepContext._(this);

  Future<void> runAll() async {
    try {
      await context.waitFor(PlanFinder.parse((plan['ready'] as Map).cast<String, dynamic>()), timeout: 90);
      await context.steps(plan['prelude'] as List? ?? const []);
      _mark({'edge': 'ready'});
      await context.steps(plan['afterReady'] as List? ?? const []);
      for (final run in (plan['runs'] as List).cast<Map<String, dynamic>>()) {
        await _run(run);
      }
    } on Object catch (e) {
      // The app's own error hooks may keep a failed test from ending; the
      // recorder stops the run on this line.
      _mark({'edge': 'failed', 'error': '$e'});
      rethrow;
    }
    _mark({'edge': 'done'});
  }

  void _mark(Map<String, Object?> fields) => mark({'t': DateTime.now().millisecondsSinceEpoch, ...fields});

  Future<void> _run(Map<String, dynamic> run) async {
    final script = run['script'] as String;
    await context.steps(run['setup'] as List? ?? const []);
    for (final scene in (run['scenes'] as List).cast<Map<String, dynamic>>()) {
      await context.steps(scene['before'] as List? ?? const []);
      await _scene(script, scene);
    }
  }

  Future<void> _scene(String script, Map<String, dynamic> scene) async {
    final id = scene['id'] as String;
    final duration = Duration(milliseconds: ((scene['duration'] as num) * 1000).round());
    final locked = scene['locked'] == true;
    final follow = scene['follow'] as String?;
    final started = DateTime.now();
    final fields = <String, Object?>{'script': script, 'scene': id, 'edge': 'start', 't': started.millisecondsSinceEpoch};
    if (follow != null) {
      final reader = registry.positionFor(follow) ?? (throw StateError('no position reader "$follow" is registered'));
      fields['pos'] = await reader(context, started);
    }
    mark(fields);
    await context.steps(scene['steps'] as List? ?? const []);
    final spent = DateTime.now().difference(started);
    if (locked && spent > duration) {
      fail('scene $script/$id is played in real time (${duration.inMilliseconds} ms) but its steps took ${spent.inMilliseconds} ms');
    }
    await context.hold(duration - spent);
    _mark({'script': script, 'scene': id, 'edge': 'end'});
  }
}

/// What a step handler works with: the tester, the plan's shared state and
/// the building blocks of the built-in steps.
class StepContext {
  StepContext._(this._runner)
    : sync = Directory(_runner.plan['sync'] as String? ?? Directory.systemTemp.path),
      admin = _runner.plan['admin'] == null ? null : Uri.parse(_runner.plan['admin'] as String);

  final PlanRunner _runner;

  /// Where the system-UI helper reports (host path; the simulator shares the
  /// host file system).
  final Directory sync;

  /// The backend's admin base URL, if the app has one.
  final Uri? admin;

  /// Values steps keep for later steps (e.g. a remembered location).
  final Map<String, String> remembered = {};
  final HttpClient _http = HttpClient();

  WidgetTester get tester => _runner.tester;

  Future<void> steps(List<dynamic> steps) async {
    for (final raw in steps.cast<Map<String, dynamic>>()) {
      await step(raw);
    }
  }

  Future<void> step(Map<String, dynamic> step) async {
    final op = step['do'] as String;
    final app = _runner.registry.stepFor(op);
    if (app != null) return app(this, step);
    switch (op) {
      case 'pause':
        await hold(Duration(milliseconds: (step['ms'] as num).toInt()));
      case 'waitFor':
        await waitFor(PlanFinder.parse(step), timeout: (step['timeout'] as num?)?.toInt() ?? 30);
      case 'waitGone':
        final spec = PlanFinder.parse(step);
        await waitUntil(() => spec.finder.evaluate().isEmpty, timeout: (step['timeout'] as num?)?.toInt() ?? 30, what: '$spec to go');
      case 'tap':
        await tap(PlanFinder.parse(step), reveal: step['reveal'] != false, within: step['within'] as String?);
      case 'type':
        await type(PlanFinder.parse(step), '${step['text']}', (step['cps'] as num?)?.toDouble() ?? 8);
      case 'submit':
        final field = find.descendant(of: PlanFinder.parse(step).finder.first, matching: find.byType(EditableText));
        tester.state<EditableTextState>(field.first).performAction(TextInputAction.done);
        await tester.pump();
      case 'dismissKeyboard':
        FocusManager.instance.primaryFocus?.unfocus();
        await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
        await hold(const Duration(milliseconds: 350));
      case 'scrollTo':
        await reveal(
          PlanFinder.parse(step).finder,
          alignment: (step['alignment'] as num?)?.toDouble() ?? 0.3,
          within: step['within'] as String?,
        );
      case 'fling':
        await tester.fling(PlanFinder.parse(step).finder.first, Offset(0, (step['dy'] as num).toDouble()), 1200);
      case 'pop':
        // A system back, as the platform sends it.
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          SystemChannels.navigation.name,
          SystemChannels.navigation.codec.encodeMethodCall(const MethodCall('popRoute')),
          (_) {},
        );
        await hold(const Duration(milliseconds: 400));
      case 'admin':
        await postAdmin(step['path'] as String, (step['body'] as Map?)?.cast<String, Object?>() ?? const {});
      case 'pickPhotos':
        // The picker is open; the system-UI helper picks (or, count 0,
        // cancels) and reports the session.
        final session = File('${sync.path}/session-${step['session']}.done');
        await waitUntil(session.existsSync, timeout: 180, what: 'picker session ${step['session']}');
      case 'waitSync':
        // A file the helper writes (e.g. `alert.done` once it has answered a
        // system prompt off camera).
        final file = File('${sync.path}/${step['name']}');
        await waitUntil(file.existsSync, timeout: (step['timeout'] as num?)?.toInt() ?? 120, what: 'the helper\'s ${step['name']}');
        await hold(const Duration(milliseconds: 500));
      case 'waitHelper':
        // The helper took the foreground to start and handed it back;
        // nothing is filmed before that.
        await waitUntil(File('${sync.path}/attached').existsSync, timeout: 240, what: 'the system-UI helper');
        await hold(const Duration(milliseconds: 1500));
      case 'screenshot':
        // Off-camera diagnostics: the texts on screen.
        // ignore: avoid_print
        print('STORE_PREVIEW_SCREEN ${step['note'] ?? ''}: ${onScreenText()}');
      default:
        fail('unknown step "$op" (built in: ${builtInSteps.join(', ')}; registered by the app: none of that name)');
    }
  }

  /// Waits in real time while the app keeps drawing (fully live frames).
  Future<void> hold(Duration d) async {
    if (d <= Duration.zero) return;
    final until = DateTime.now().add(d);
    while (DateTime.now().isBefore(until)) {
      final left = until.difference(DateTime.now());
      await tester.pump(left < const Duration(milliseconds: 16) ? left : const Duration(milliseconds: 16));
    }
  }

  Future<void> waitFor(PlanFinder spec, {int timeout = 30}) =>
      waitUntil(() => spec.finder.evaluate().isNotEmpty, timeout: timeout, what: spec.toString());

  Future<void> waitUntil(bool Function() done, {required int timeout, required String what}) async {
    final deadline = DateTime.now().add(Duration(seconds: timeout));
    while (!done()) {
      if (DateTime.now().isAfter(deadline)) fail('timed out after $timeout s waiting for $what; on screen: ${onScreenText()}');
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  String onScreenText() => find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().join(' | ');

  /// A row of the list to scroll: a test id, or `widget:<Class>`.
  Finder within(String within) =>
      within.startsWith('widget:') ? PlanFinder.byWidgetName(within.substring(7)) : find.byKey(ValueKey(within));

  /// Brings [finder] on screen. A lazy list builds the target only once
  /// scrolled to: [within] names a row known to be built in the same list.
  Future<void> reveal(Finder finder, {double alignment = 0.3, String? within}) async {
    await waitUntil(
      () => finder.evaluate().isNotEmpty || find.byType(Scrollable).evaluate().isNotEmpty,
      timeout: 10,
      what: '$finder',
    );
    if (finder.evaluate().isEmpty) {
      final scrollable = within == null
          ? find.byType(Scrollable).first
          : find.ancestor(of: this.within(within).first, matching: find.byType(Scrollable)).first;
      await tester.scrollUntilVisible(finder, 120, scrollable: scrollable, maxScrolls: 80);
    }
    await Scrollable.ensureVisible(tester.element(finder.first), alignment: alignment, duration: const Duration(milliseconds: 300));
    await hold(const Duration(milliseconds: 350));
  }

  Future<void> tap(PlanFinder spec, {bool reveal = true, String? within}) async {
    // A row of a lazy list exists only once scrolled to: its list is found
    // through [within] instead.
    await (within == null ? waitFor(spec) : waitFor(PlanFinder(this.within(within), within)));
    if (reveal) await this.reveal(spec.finder, within: within);
    await tester.tap(spec.finder.first, warnIfMissed: false);
    await tester.pump();
  }

  /// Types [text] into the field under [spec] a character at a time.
  Future<void> type(PlanFinder spec, String text, double cps) async {
    await waitFor(spec);
    final field = find.descendant(of: spec.finder.first, matching: find.byType(EditableText));
    var editable = tester.widget<EditableText>(field.first);
    // A focused field is typed into as is: a second tap would open the
    // selection menu.
    if (!editable.focusNode.hasFocus) {
      await tap(spec);
      editable = tester.widget<EditableText>(field.first);
    }
    final perChar = Duration(milliseconds: (1000 / cps).round());
    final runes = text.runes.toList();
    for (var i = 1; i <= runes.length; i++) {
      final value = String.fromCharCodes(runes.take(i));
      editable.controller.value = TextEditingValue(text: value, selection: TextSelection.collapsed(offset: value.length));
      editable.onChanged?.call(value);
      await hold(perChar);
    }
  }

  Future<void> postAdmin(String path, Map<String, Object?> body) async {
    final base = admin ?? (throw StateError('the plan has no backend admin URL (app.yaml backend.admin)'));
    final request = await _http.postUrl(base.resolve(path));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body));
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) fail('admin $path → ${response.statusCode} $text');
  }
}
