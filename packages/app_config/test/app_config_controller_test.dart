import 'dart:async';

import 'package:app_config/app_config.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infra_core/infra_core.dart';

class _FakeRepo implements AppConfigRepository {
  AppConfig result = AppConfig.safeDefault;
  Object? error;
  Completer<void>? gate;
  int calls = 0;

  @override
  Future<AppConfig> fetch() async {
    calls += 1;
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
    return result;
  }
}

class _Language extends Notifier<String> {
  @override
  String build() => 'en';
  void select(String value) => state = value;
}

final _language = NotifierProvider<_Language, String>(_Language.new);

class _QueuedRepo implements AppConfigRepository {
  final requests = <Completer<AppConfig>>[];
  @override
  Future<AppConfig> fetch() {
    final request = Completer<AppConfig>();
    requests.add(request);
    return request.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late _FakeRepo repo;

  setUp(() {
    now = DateTime.utc(2026, 1, 1, 12);
    repo = _FakeRepo();
  });

  testWidgets(
    'language changes queue a refresh and reject obsolete responses',
    (tester) async {
      final queued = _QueuedRepo();
      final container = ProviderContainer(
        overrides: [
          appConfigRepositoryProvider.overrideWithValue(queued),
          languageTagProvider.overrideWith((ref) => ref.watch(_language)),
        ],
      );
      container.read(appConfigProvider);
      queued.requests.single.complete(
        const AppConfig(
          maintenance: Maintenance(
            active: true,
            message: 'English maintenance',
          ),
          killSwitches: ['iap_purchase'],
          config: {'promo_text': 'English promo', 'other_flag': true},
        ),
      );
      await tester.pump();
      final oldRefresh = container
          .read(appConfigProvider.notifier)
          .refresh(force: true);
      container.read(_language.notifier).select('de');
      await tester.pump();
      container.read(_language.notifier).select('ja');
      await tester.pump();
      expect(queued.requests, hasLength(2));
      final interim = container.read(appConfigProvider);
      expect(interim.maintenance.active, isTrue);
      expect(interim.maintenance.message, isEmpty);
      expect(interim.isKilled('iap_purchase'), isTrue);
      expect(interim.configValue('promo_text', ''), isEmpty);
      expect(interim.configValue('other_flag', false), isTrue);
      queued.requests[1].complete(AppConfig.safeDefault);
      await oldRefresh;
      await tester.pump();
      expect(container.read(appConfigProvider).maintenance.active, isTrue);
      expect(queued.requests, hasLength(3));
      queued.requests.last.complete(
        const AppConfig(
          maintenance: Maintenance(active: true, message: '日本語'),
          killSwitches: [],
          config: {'promo_text': '日本語の案内'},
        ),
      );
      await tester.pump();
      expect(container.read(appConfigProvider).maintenance.message, '日本語');
      container.read(_language.notifier).select('de');
      await tester.pump();
      container.read(appConfigProvider);
      expect(queued.requests, hasLength(4));
      queued.requests.last.completeError(StateError('offline'));
      await tester.pump();
      expect(container.read(appConfigProvider).maintenance.active, isTrue);
      expect(container.read(appConfigProvider).maintenance.message, isEmpty);
      expect(
        container.read(appConfigProvider).configValue('promo_text', ''),
        isEmpty,
      );
      container.dispose();
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  Future<ProviderContainer> mount(WidgetTester tester) async {
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        appConfigRepositoryProvider.overrideWithValue(repo),
        clockOffsetServiceProvider.overrideWithValue(
          ClockOffsetService(deviceClock: () => now),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SizedBox.shrink(),
      ),
    );
    return container;
  }

  testWidgets('starts at safeDefault then the initial fetch lands', (
    tester,
  ) async {
    repo.result = const AppConfig(
      maintenance: Maintenance(active: true, message: 'm'),
      killSwitches: ['k'],
      config: {},
    );
    final container = await mount(tester);

    // First read is the synchronous safe default; the fetch is fire-and-forget.
    expect(container.read(appConfigProvider).maintenance.active, isFalse);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(container.read(appConfigProvider).maintenance.active, isTrue);
    expect(container.read(isFeatureKilledProvider('k')), isTrue);
  });

  testWidgets('fail-open: a throwing fetch keeps the safe default, no error', (
    tester,
  ) async {
    repo.error = StateError('config down');
    final container = await mount(tester);
    container.read(appConfigProvider);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(container.read(appConfigProvider), AppConfig.safeDefault);
  });

  testWidgets('throttles within the interval; force + elapsed bypass', (
    tester,
  ) async {
    final container = await mount(tester);
    container.read(appConfigProvider); // triggers the initial fetch
    await tester.pump();
    expect(repo.calls, 1);

    await container.read(appConfigProvider.notifier).refresh(); // within 60s
    expect(repo.calls, 1);

    await container.read(appConfigProvider.notifier).refresh(force: true);
    expect(repo.calls, 2);

    now = now.add(const Duration(seconds: 61));
    await container.read(appConfigProvider.notifier).refresh(); // elapsed
    expect(repo.calls, 3);
  });

  testWidgets('refreshes on app resume (throttle elapsed)', (tester) async {
    final container = await mount(tester);
    container.read(appConfigProvider);
    await tester.pump();
    expect(repo.calls, 1);

    now = now.add(const Duration(seconds: 61));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(repo.calls, 2);
  });

  testWidgets('resume within the interval is throttled (no refetch)', (
    tester,
  ) async {
    final container = await mount(tester);
    container.read(appConfigProvider);
    await tester.pump();
    expect(repo.calls, 1);

    // Resume WITHOUT advancing the clock → throttled (uses the monotonic clock).
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(repo.calls, 1);
  });

  testWidgets('drops a concurrent refresh while one is in flight', (
    tester,
  ) async {
    repo.gate = Completer<void>();
    final container = await mount(tester);
    container.read(appConfigProvider); // build() → refresh() held at the gate
    await tester.pump();
    expect(repo.calls, 1);

    await container.read(appConfigProvider.notifier).refresh(force: true);
    expect(repo.calls, 1); // dropped: a fetch is already in flight

    repo.gate!.complete();
    await tester.pump();
    expect(repo.calls, 1);
  });

  testWidgets('a failure does not arm the throttle (fast retry on recovery)', (
    tester,
  ) async {
    repo.error = StateError('config down');
    final container = await mount(tester);
    container.read(appConfigProvider); // build() → refresh() fails
    await tester.pump();
    expect(container.read(appConfigProvider), AppConfig.safeDefault);
    expect(repo.calls, 1);

    // Server recovers; a NON-forced refresh retries immediately (not throttled,
    // because the failed attempt did not stamp _lastFetchedAt).
    repo.error = null;
    repo.result = const AppConfig(
      maintenance: Maintenance(active: true, message: 'm'),
      killSwitches: [],
      config: {},
    );
    await container.read(appConfigProvider.notifier).refresh();
    await tester.pump();
    expect(container.read(appConfigProvider).maintenance.active, isTrue);
    expect(repo.calls, 2);
  });
}
