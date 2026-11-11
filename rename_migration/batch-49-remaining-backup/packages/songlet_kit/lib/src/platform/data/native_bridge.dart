import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../../common/json.dart';
import '../../store/domain/music_entitlement_sync.dart';
import '../domain/native_gateways.dart';
import 'songlet_api.g.dart';

/// The Dart end of the PRD §6.4 Pigeon bridge. Wraps the generated
/// [SongletNativeApi] behind the domain gateways and receives the two
/// Flutter-bound events of [SongletFlutterApi].
///
/// `onTransactionUpdated` is written to the [SignedTransactionOutbox]
/// **synchronously inside the handler** — Swift finishes the StoreKit
/// transaction once this handler returns, so the JWS must be durable before
/// anything else (a listener may not even exist yet on a cold start).
class NativeBridge
    implements
        SongletFlutterApi,
        PhotoSource,
        PromptPolisher,
        FileExporter,
        AttestationProvider,
        AudioEngine,
        SignedTransactionSource {
  NativeBridge({
    required SignedTransactionOutbox outbox,
    SongletNativeApi? api,
    MethodChannel playback = const MethodChannel('songlet/playback'),
  })  : _outbox = outbox,
        _playback = playback,
        api = api ?? SongletNativeApi() {
    SongletFlutterApi.setUp(this);
  }

  /// The raw host API (StoreKit calls are adapted by `MusicPigeonStoreClient`).
  final SongletNativeApi api;
  final SignedTransactionOutbox _outbox;

  /// Seek lives beside the fixed Pigeon interface (ADR-0017).
  final MethodChannel _playback;
  final StreamController<double> _progress = StreamController.broadcast();
  final StreamController<String> _updates = StreamController.broadcast();

  /// Signed transactions from `Transaction.updates` (renewals, refunds,
  /// Ask-to-Buy approvals, re-deliveries) — already persisted to the outbox.
  Stream<String> get transactionUpdates => _updates.stream;

  void dispose() {
    SongletFlutterApi.setUp(null);
    _progress.close();
    _updates.close();
  }

  // SongletFlutterApi ------------------------------------------------------

  @override
  void onPlaybackProgress(double seconds) => _progress.add(seconds);

  @override
  void onTransactionUpdated(String signedTransaction) {
    unawaited(_outbox.add(signedTransaction));
    _updates.add(signedTransaction);
  }

  // Domain gateways --------------------------------------------------------

  @override
  Future<List<Uint8List>> pickPhotos(int max) => api.pickPhotos(max);

  @override
  Future<String> polish(String raw, String locale) async {
    try {
      final polished = await api.polishPrompt(raw, locale);
      return polished.trim().isEmpty ? raw : polished;
    } on PlatformException {
      return raw;
    }
  }

  @override
  Future<bool> exportToFiles(String path, String name) async {
    try {
      await api.exportToFiles(path, name);
      return true;
    } on PlatformException catch (e) {
      if (e.code == 'cancelled') return false;
      rethrow;
    }
  }

  @override
  Future<Map<String, Object?>> assertion(String challenge) async {
    final raw = await api.appAttestAssertion(challenge);
    return asMap(jsonDecode(raw));
  }

  @override
  Future<void> play(String path, {required bool loop}) => api.playAudio(path, loop);

  @override
  Future<void> seek(double seconds) =>
      _playback.invokeMethod<void>('seek', <String, Object?>{'seconds': seconds});

  @override
  Stream<double> get progress => _progress.stream;

  @override
  Future<List<String>> currentSignedTransactions() =>
      api.currentSignedTransactions();
}
