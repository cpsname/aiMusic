import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/src/store/data/kv_signed_transaction_outbox.dart';

import '../../support/music_fakes.dart';

void main() {
  late InMemoryKeyValueStore store;

  setUp(() => store = InMemoryKeyValueStore());

  test('starts empty', () {
    expect(KvSignedTransactionOutbox(store).pending(), isEmpty);
  });

  test('adds in order and persists across instances', () async {
    await KvSignedTransactionOutbox(store).add('a');
    await KvSignedTransactionOutbox(store).add('b');

    expect(KvSignedTransactionOutbox(store).pending(), ['a', 'b']);
    expect(store.getJson('songlet.jws_outbox.v1'), {
      'items': ['a', 'b'],
    });
  });

  test('deduplicates: re-adding moves the entry to the newest slot', () async {
    final outbox = KvSignedTransactionOutbox(store);
    await outbox.add('a');
    await outbox.add('b');
    await outbox.add('a');

    expect(outbox.pending(), ['b', 'a']);
  });

  test('ignores an empty JWS', () async {
    final outbox = KvSignedTransactionOutbox(store);
    await outbox.add('');
    expect(outbox.pending(), isEmpty);
    expect(store.values, isEmpty);
  });

  test('is bounded: the oldest entries drop first past capacity', () async {
    final outbox = KvSignedTransactionOutbox(store, capacity: 3);
    for (final jws in ['1', '2', '3', '4', '5']) {
      await outbox.add(jws);
    }
    expect(outbox.pending(), ['3', '4', '5']);
  });

  test('the default capacity is 50', () async {
    final outbox = KvSignedTransactionOutbox(store);
    expect(outbox.capacity, 50);
    for (var i = 0; i < 55; i++) {
      await outbox.add('jws-$i');
    }
    expect(outbox.pending(), hasLength(50));
    expect(outbox.pending().first, 'jws-5');
    expect(outbox.pending().last, 'jws-54');
  });

  test('removeAll drops only the given entries', () async {
    final outbox = KvSignedTransactionOutbox(store);
    for (final jws in ['a', 'b', 'c', 'd']) {
      await outbox.add(jws);
    }

    await outbox.removeAll(['b', 'd', 'unknown']);

    expect(outbox.pending(), ['a', 'c']);
  });

  test('removeAll with nothing to drop is a no-op', () async {
    final outbox = KvSignedTransactionOutbox(store);
    await outbox.add('a');
    await outbox.removeAll(const []);
    expect(outbox.pending(), ['a']);
  });

  test('corrupt persisted data degrades to empty and recovers on add', () async {
    await store.setString('songlet.jws_outbox.v1', '{not json');
    final outbox = KvSignedTransactionOutbox(store);
    expect(outbox.pending(), isEmpty);

    await outbox.add('a');
    expect(outbox.pending(), ['a']);
  });

  test('a wrongly shaped record degrades to empty', () async {
    await store.setJson('songlet.jws_outbox.v1', {'items': 'oops'});
    expect(KvSignedTransactionOutbox(store).pending(), isEmpty);
  });
}
