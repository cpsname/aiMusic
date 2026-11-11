import 'package:infra_core/infra_core.dart';

import '../../common/json.dart';
import '../domain/music_entitlement_sync.dart';

/// [SignedTransactionOutbox] persisted in [KeyValueStore]. Deduplicated,
/// bounded (the oldest entries drop first past [capacity]) — a JWS is a few
/// KB and the outbox only ever holds a handful between syncs.
class KvSignedTransactionOutbox implements SignedTransactionOutbox {
  KvSignedTransactionOutbox(this._store, {this.capacity = 50});

  static const String _key = 'songlet.jws_outbox.v1';

  final KeyValueStore _store;
  final int capacity;

  @override
  List<String> pending() => asStringList(_store.getJson(_key)?['items']);

  @override
  Future<void> add(String jws) async {
    if (jws.isEmpty) return;
    final items = pending().where((e) => e != jws).toList()..add(jws);
    final bounded =
        items.length > capacity ? items.sublist(items.length - capacity) : items;
    await _store.setJson(_key, {'items': bounded});
  }

  @override
  Future<void> removeAll(Iterable<String> jws) async {
    final drop = jws.toSet();
    if (drop.isEmpty) return;
    final items = pending().where((e) => !drop.contains(e)).toList();
    await _store.setJson(_key, {'items': items});
  }
}
