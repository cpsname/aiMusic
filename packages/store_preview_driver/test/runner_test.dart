import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:store_preview_driver/store_preview_driver.dart';

/// A field and a button that counts taps.
class _App extends StatefulWidget {
  const _App();

  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  int taps = 0;
  String typed = '';

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          TextField(key: const ValueKey('name'), onChanged: (v) => setState(() => typed = v)),
          TextButton(key: const ValueKey('go'), onPressed: () => setState(() => taps++), child: Text('taps $taps')),
          Text(key: const ValueKey('typed'), 'typed $typed'),
        ],
      ),
    ),
  );
}

void main() {
  test('app steps cannot shadow built-ins or register twice', () {
    final r = StepRegistry();
    expect(() => r.step('tap', (_, _) async {}), throwsArgumentError);
    r.step('newDraft', (_, _) async {});
    expect(() => r.step('newDraft', (_, _) async {}), throwsArgumentError);
    r.position('song', (_, _) async => 0);
    expect(() => r.position('song', (_, _) async => 0), throwsArgumentError);
  });

  testWidgets('finders: key, widget, label, index', (tester) async {
    await tester.pumpWidget(const _App());
    expect(PlanFinder.parse({'key': 'go'}).finder, findsOneWidget);
    expect(PlanFinder.parse({'key': 'go', 'widget': 'Text'}).finder, findsOneWidget);
    expect(PlanFinder.parse({'label': 'taps 0'}).finder, findsOneWidget);
    expect(PlanFinder.parse({'widget': 'Text', 'index': 1}).finder, findsOneWidget);
    expect(() => PlanFinder.parse({'index': 1}), throwsArgumentError);
  });

  testWidgets('runs the plan: prelude, setup, scenes in order, app steps, marks with positions', (tester) async {
    tester.binding.testTextInput.unregister();
    await tester.pumpWidget(const _App());
    final marks = <Map<String, Object?>>[];
    final calls = <String>[];
    final registry = StepRegistry()
      ..step('remember', (c, s) async => calls.add('remember ${s['as']}'))
      ..position('song', (c, at) async => 42.5);
    final plan = {
      'ready': {'key': 'go'},
      'prelude': [
        {'do': 'remember', 'as': 'prelude'},
      ],
      'afterReady': const <Object>[],
      'runs': [
        {
          'script': 'A',
          'setup': [
            {'do': 'remember', 'as': 'setup'},
          ],
          'scenes': [
            {
              'id': 'type',
              'duration': 0.05,
              'locked': false,
              'steps': [
                {'do': 'type', 'key': 'name', 'text': 'Alex', 'cps': 400},
              ],
            },
            {
              'id': 'play',
              'duration': 0.05,
              'locked': true,
              'follow': 'song',
              'before': [
                {'do': 'tap', 'key': 'go', 'reveal': false},
              ],
            },
          ],
        },
      ],
    };
    await PlanRunner(tester, plan, registry: registry, mark: marks.add).runAll();
    expect(calls, ['remember prelude', 'remember setup']);
    expect(find.text('typed Alex'), findsOneWidget);
    expect(find.text('taps 1'), findsOneWidget);
    expect(marks.map((m) => '${m['edge']}${m['scene'] == null ? '' : ' ${m['scene']}'}'), [
      'ready',
      'start type',
      'end type',
      'start play',
      'end play',
      'done',
    ]);
    expect(marks.firstWhere((m) => m['scene'] == 'play' && m['edge'] == 'start')['pos'], 42.5);
  });

  testWidgets('an unknown step fails the run with a failed mark', (tester) async {
    await tester.pumpWidget(const _App());
    final marks = <Map<String, Object?>>[];
    final plan = {
      'ready': {'key': 'go'},
      'runs': [
        {
          'script': 'A',
          'setup': [
            {'do': 'teleport'},
          ],
          'scenes': const <Object>[],
        },
      ],
    };
    await expectLater(PlanRunner(tester, plan, registry: StepRegistry(), mark: marks.add).runAll(), throwsA(isA<TestFailure>()));
    expect(marks.last['edge'], 'failed');
    expect('${marks.last['error']}', contains('unknown step "teleport"'));
  });
}
