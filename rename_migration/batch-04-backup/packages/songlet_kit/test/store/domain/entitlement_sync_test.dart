import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:songlet_kit/src/store/domain/entitlement_sync.dart';

import '../../support/songlet_fakes.dart';

void main() {
  late FakeEntitlementRemote remote;
  late FakeSignedTransactionSource source;
  late FakeOutbox outbox;
  late int tokenReads;

  setUp(() {
    remote = FakeEntitlementRemote();
    source = FakeSignedTransactionSource();
    outbox = FakeOutbox();
    tokenReads = 0;
  });

  EntitlementSync build() => EntitlementSync(
        remote: remote,
        source: source,
        outbox: outbox,
        appAccountToken: () async {
          tokenReads++;
          return 'token-uuid';
        },
      );

  test('sends outbox ∪ currentEntitlements, deduplicated', () async {
    outbox.items.addAll(['a', 'b']);
    source.current = ['b', 'c'];

    final result = await build().sync();

    expect(remote.calls, hasLength(1));
    expect(remote.calls.single.appAccountToken, 'token-uuid');
    expect(remote.calls.single.signedTransactions, ['a', 'b', 'c']);
    expect(result, remote.result);
  });

  test('removes the sent outbox entries on success', () async {
    outbox.items.addAll(['a', 'b']);
    source.current = ['c'];

    await build().sync();

    expect(outbox.items, isEmpty);
    expect(outbox.removed.single, ['a', 'b'], reason: 'current entitlements are not outbox entries');
  });

  test('keeps entries added while the sync was in flight', () async {
    outbox.items.add('a');
    remote.gate = Completer<void>();
    final sync = build();

    final pending = sync.sync();
    await pumpEventQueue();
    await outbox.add('late');
    remote.gate!.complete();
    await pending;

    expect(outbox.items, ['late']);
  });

  test('a failing sync keeps the outbox and leaves latest unchanged', () async {
    outbox.items.add('a');
    remote.error = StateError('offline');
    final sync = build();

    await expectLater(sync.sync(), throwsStateError);

    expect(outbox.items, ['a']);
    expect(sync.latest, isNull);
  });

  test('a failing entitlement source still syncs the outbox', () async {
    outbox.items.add('a');
    source.error = StateError('StoreKit unavailable');

    final result = await build().sync();

    expect(remote.calls.single.signedTransactions, ['a']);
    expect(result.tier, SongletTier.pro);
    expect(outbox.items, isEmpty);
  });

  test('an empty device still asks the ledger (free tier answer)', () async {
    remote.result = const SongletEntitlement(
      tier: SongletTier.free,
      songsLeft: 0,
      clipsLeft: 3,
    );

    final result = await build().sync();

    expect(remote.calls.single.signedTransactions, isEmpty);
    expect(result.clipsLeft, 3);
    expect(outbox.items, isEmpty);
    expect(outbox.removed.expand((r) => r), isEmpty, reason: 'nothing queued → nothing removed');
  });

  test('single-flight: concurrent calls share one remote request', () async {
    remote.gate = Completer<void>();
    final sync = build();

    final first = sync.sync();
    final second = sync.sync();
    await pumpEventQueue();
    expect(remote.calls, hasLength(1));

    remote.gate!.complete();
    final results = await Future.wait([first, second]);

    expect(results[0], results[1]);
    expect(remote.calls, hasLength(1));
    expect(source.calls, 1);
    expect(tokenReads, 1);
  });

  test('concurrent callers all see the error of the shared flight', () async {
    remote
      ..gate = Completer<void>()
      ..error = StateError('down');
    final sync = build();

    final first = sync.sync();
    final second = sync.sync();
    remote.gate!.complete();

    await expectLater(first, throwsStateError);
    await expectLater(second, throwsStateError);
    expect(remote.calls, hasLength(1));
  });

  test('a new sync after the flight completes makes a new request', () async {
    final sync = build();
    await sync.sync();
    await sync.sync();
    expect(remote.calls, hasLength(2));
  });

  test('a new sync after a failed flight is allowed', () async {
    remote.error = StateError('down');
    final sync = build();
    await expectLater(sync.sync(), throwsStateError);

    remote.error = null;
    await sync.sync();
    expect(remote.calls, hasLength(2));
    expect(sync.latest, isNotNull);
  });

  test('latest follows the most recent server answer', () async {
    final sync = build();
    expect(sync.latest, isNull);

    await sync.sync();
    expect(sync.latest, remote.result);

    remote.result = const SongletEntitlement(
      tier: SongletTier.pack,
      songsLeft: 10,
      clipsLeft: 0,
    );
    await sync.sync();
    expect(sync.latest!.tier, SongletTier.pack);
    expect(sync.latest!.songsLeft, 10);
  });

  group('SongletEntitlement / SongletTier', () {
    test('tier parsing and flags', () {
      expect(SongletTier.fromWire('PRO'), SongletTier.pro);
      expect(SongletTier.fromWire('premier'), SongletTier.premier);
      expect(SongletTier.fromWire('pack'), SongletTier.pack);
      expect(SongletTier.fromWire('nope'), SongletTier.free);
      expect(SongletTier.pro.hasSubscription, isTrue);
      expect(SongletTier.pack.hasSubscription, isFalse);
      expect(SongletTier.pack.isPaid, isTrue);
      expect(SongletTier.free.isPaid, isFalse);
    });

    test('value equality and capabilities', () {
      const a = SongletEntitlement(tier: SongletTier.pro, songsLeft: 1, clipsLeft: 0);
      const b = SongletEntitlement(tier: SongletTier.pro, songsLeft: 1, clipsLeft: 0);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.canMakeSong, isTrue);
      expect(a.canMakeClip, isFalse);
      expect(SongletEntitlement.unknown.canMakeSong, isFalse);
    });
  });
}
