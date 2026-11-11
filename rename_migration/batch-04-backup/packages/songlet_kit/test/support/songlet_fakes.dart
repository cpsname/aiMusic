import 'dart:async';
import 'dart:convert';

import 'package:infra_core/infra_core.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:songlet_kit/src/store/domain/entitlement_sync.dart';

/// Builds an Apple-style JWS (`header.payload.signature`) whose payload is the
/// base64url (unpadded) JSON of [payload]. The signature is opaque — the client
/// never verifies it.
String makeJws(Map<String, Object?> payload) {
  String segment(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${segment({'alg': 'ES256', 'x5c': <String>[]})}.${segment(payload)}.c2lnbmF0dXJl';
}

/// A minimal JWS for [productId] / [transactionId].
String jwsFor(
  String productId,
  String transactionId, {
  String? storefront,
  int? purchaseDate,
}) =>
    makeJws({
      'transactionId': transactionId,
      'originalTransactionId': transactionId,
      'productId': productId,
      'storefront': ?storefront,
      'purchaseDate': ?purchaseDate,
    });

/// In-memory [KeyValueStore]: values are held as the strings SharedPreferences
/// would persist (JSON round-trips through `jsonEncode` / `jsonDecode`), so the
/// persisted shape is exercised exactly as with the real store.
class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, Object> values = {};

  @override
  String? getString(String key) {
    final value = values[key];
    return value is String ? value : null;
  }

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  bool? getBool(String key) {
    final value = values[key];
    return value is bool ? value : null;
  }

  @override
  Future<void> setBool(String key, {required bool value}) async =>
      values[key] = value;

  @override
  int? getInt(String key) {
    final value = values[key];
    return value is int ? value : null;
  }

  @override
  Future<void> setInt(String key, int value) async => values[key] = value;

  @override
  List<String>? getStringList(String key) {
    final value = values[key];
    return value is List<String> ? List.of(value) : null;
  }

  @override
  Future<void> setStringList(String key, List<String> value) async => values[key] = List.of(value);

  @override
  Map<String, dynamic>? getJson(String key) {
    final raw = getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async =>
      values[key] = jsonEncode(value);

  @override
  bool containsKey(String key) => values.containsKey(key);

  @override
  Future<void> remove(String key) async => values.remove(key);
}

/// In-memory [SignedTransactionOutbox] (insertion order, deduplicated).
class FakeOutbox implements SignedTransactionOutbox {
  FakeOutbox([Iterable<String> initial = const []]) : items = [...initial];

  final List<String> items;
  final List<String> added = [];
  final List<List<String>> removed = [];

  @override
  List<String> pending() => List.unmodifiable(items);

  @override
  Future<void> add(String jws) async {
    added.add(jws);
    items
      ..remove(jws)
      ..add(jws);
  }

  @override
  Future<void> removeAll(Iterable<String> jws) async {
    final drop = jws.toList();
    removed.add(drop);
    items.removeWhere(drop.contains);
  }
}

class FakeSignedTransactionSource implements SignedTransactionSource {
  FakeSignedTransactionSource({this.current = const [], this.error});

  List<String> current;
  Object? error;
  int calls = 0;

  @override
  Future<List<String>> currentSignedTransactions() async {
    calls++;
    final failure = error;
    if (failure != null) throw failure;
    return current;
  }
}

class SyncCall {
  const SyncCall(this.appAccountToken, this.signedTransactions);

  final String appAccountToken;
  final List<String> signedTransactions;
}

/// [EntitlementRemote] recording each call. When [gate] is set, every call
/// waits for it (to hold a sync in flight).
class FakeEntitlementRemote implements EntitlementRemote {
  FakeEntitlementRemote({
    this.result = const SongletEntitlement(
      tier: SongletTier.pro,
      songsLeft: 40,
      clipsLeft: 100,
    ),
  });

  SongletEntitlement result;
  Object? error;
  Completer<void>? gate;
  final List<SyncCall> calls = [];

  @override
  Future<SongletEntitlement> sync({
    required String appAccountToken,
    required List<String> signedTransactions,
  }) async {
    calls.add(SyncCall(appAccountToken, signedTransactions));
    final pending = gate;
    if (pending != null) await pending.future;
    final failure = error;
    if (failure != null) throw failure;
    return result;
  }
}

/// In-memory [WorkRepository] recording every upsert.
class FakeWorkRepository implements WorkRepository {
  final Map<String, Work> works = {};
  final List<Work> upserts = [];

  @override
  Future<List<Work>> all() async => works.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<Work?> byId(String id) async => works[id];

  @override
  Future<void> upsert(Work work) async {
    upserts.add(work);
    works[work.id] = work;
  }

  @override
  Future<void> delete(String id) async => works.remove(id);
}

class DownloadCall {
  const DownloadCall(this.url, this.workId, this.title);

  final String url;
  final String workId;
  final String title;
}

class FakeAudioStore implements AudioStore {
  final List<DownloadCall> downloads = [];
  Object? error;

  @override
  Future<String> download({
    required String url,
    required String workId,
    required String title,
  }) async {
    downloads.add(DownloadCall(url, workId, title));
    final failure = error;
    if (failure != null) throw failure;
    return '$workId.mp3';
  }

  @override
  Future<String> pathOf(String fileName) async => '/audio/$fileName';

  @override
  Future<String> scratchDirectory() async => '/scratch';

  final List<String> fetched = [];
  final List<String> imported = [];

  @override
  Future<String> importFile({required String sourcePath, required String workId}) async {
    imported.add(sourcePath);
    return '$workId.mp3';
  }

  @override
  Future<String> fetchToScratch({required String url, required String fileName}) async {
    fetched.add(url);
    return '/scratch/$fileName';
  }

  @override
  Future<void> delete(String fileName) async {}
}

/// A pending work for [JobRunner] / repository tests.
Work sampleWork({
  String id = 'w1',
  String? jobId = 'job-1',
  SongModel model = SongModel.clip,
  WorkStatus status = WorkStatus.pending,
  Occasion occasion = Occasion.birthday,
  String recipient = 'Alex',
  List<String> keywords = const ['coffee', 'hiking'],
  DateTime? createdAt,
}) =>
    Work(
      id: id,
      jobId: jobId,
      model: model,
      status: status,
      occasion: occasion,
      region: 'US',
      genre: 'Indie Pop',
      lyricLanguage: 'en',
      recipient: recipient,
      keywords: keywords,
      createdAt: createdAt ?? DateTime.utc(2026, 9, 1, 12),
    );
