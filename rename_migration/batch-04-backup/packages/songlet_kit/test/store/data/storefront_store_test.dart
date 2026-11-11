import 'package:flutter_test/flutter_test.dart';
import 'package:songlet_kit/src/store/data/storefront_store.dart';

import '../../support/songlet_fakes.dart';

void main() {
  late InMemoryKeyValueStore kv;

  setUp(() => kv = InMemoryKeyValueStore());

  test('is null until a storefront is seen', () {
    expect(StorefrontStore(kv).current, isNull);
  });

  test('remembers the storefront upper-cased and persists it', () async {
    await StorefrontStore(kv).remember('bra');
    expect(StorefrontStore(kv).current, 'BRA');
  });

  test('ignores an empty value', () async {
    final store = StorefrontStore(kv);
    await store.remember('USA');
    await store.remember('');
    expect(store.current, 'USA');
  });

  test('a later storefront replaces the earlier one', () async {
    final store = StorefrontStore(kv);
    await store.remember('USA');
    await store.remember('JPN');
    expect(store.current, 'JPN');
  });
}
