import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:meta/meta.dart';

import '../domain/cloud_sync.dart';
import '../domain/work.dart';
import 'library_providers.dart';

/// Where library sync stands (Settings toggle, Library header — docs/ui P12).
@immutable
class LibrarySyncState {
  const LibrarySyncState({
    this.enabled = false,
    this.account,
    this.syncing = false,
    this.lastSyncedAt,
    this.failed = false,
  });

  final bool enabled;

  /// Last known iCloud account status; null until checked.
  final CloudAccount? account;
  final bool syncing;
  final DateTime? lastSyncedAt;

  /// The last sync attempt failed (retried on the next trigger).
  final bool failed;

  bool get unavailable => account != null && account != CloudAccount.available;

  LibrarySyncState copyWith({
    bool? enabled,
    CloudAccount? account,
    bool? syncing,
    DateTime? lastSyncedAt,
    bool? failed,
  }) =>
      LibrarySyncState(
        enabled: enabled ?? this.enabled,
        account: account ?? this.account,
        syncing: syncing ?? this.syncing,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        failed: failed ?? this.failed,
      );
}

/// Opt-in iCloud library sync (PRD F10, off by default; ADR-0013): pushes
/// finished works, pulls the other devices' changes, tombstones deletions.
/// Works are immutable once ready, so a work already on the device is kept.
class LibrarySyncController extends Notifier<LibrarySyncState> {
  static const String enabledKey = 'songlet.library.icloud_sync';
  static const String lastSyncKey = 'songlet.library.icloud_last_sync';
  static const String pushedKey = 'songlet.library.icloud_pushed';

  Future<void>? _running;

  CloudSyncGateway get _gateway => ref.read(cloudSyncGatewayProvider);
  KeyValueStore get _prefs => ref.read(keyValueStoreProvider);

  @override
  LibrarySyncState build() {
    final prefs = ref.watch(keyValueStoreProvider);
    final last = prefs.getInt(lastSyncKey);
    return LibrarySyncState(
      enabled: prefs.getBool(enabledKey) ?? false,
      lastSyncedAt: last == null ? null : DateTime.fromMillisecondsSinceEpoch(last, isUtc: true),
    );
  }

  /// Turns sync on (after checking the iCloud account) or off.
  Future<void> setEnabled({required bool enabled}) async {
    if (!enabled) {
      await _prefs.setBool(enabledKey, value: false);
      state = state.copyWith(enabled: false, failed: false);
      return;
    }
    final account = await _gateway.account();
    if (account != CloudAccount.available) {
      state = state.copyWith(enabled: false, account: account);
      return;
    }
    await _prefs.setBool(enabledKey, value: true);
    state = state.copyWith(enabled: true, account: account, failed: false);
    await syncNow();
  }

  /// One sync round; concurrent calls share it. No-op when sync is off.
  Future<void> syncNow() {
    if (!state.enabled) return Future.value();
    return _running ??= _sync().whenComplete(() => _running = null);
  }

  Future<void> _sync() async {
    state = state.copyWith(syncing: true);
    try {
      final account = await _gateway.account();
      if (account != CloudAccount.available) {
        state = state.copyWith(account: account, syncing: false);
        return;
      }
      final works = ref.read(workRepositoryProvider);
      final audio = ref.read(audioStoreProvider);
      final pushed = (_prefs.getStringList(pushedKey) ?? const <String>[]).toSet();

      for (final work in await works.all()) {
        if (!work.isReady || pushed.contains(work.id)) continue;
        await _gateway.push(work, audioPath: await audio.pathOf(work.audioFile!));
        pushed.add(work.id);
      }

      final started = DateTime.now().toUtc();
      for (final change in await _gateway.pull(since: state.lastSyncedAt)) {
        if (change.isDeletion) {
          final local = await works.byId(change.id);
          if (local != null) {
            await works.delete(local.id);
            final file = local.audioFile;
            if (file != null) await audio.delete(file);
          }
          pushed.remove(change.id);
          continue;
        }
        if (await works.byId(change.id) != null) continue;
        final source = change.audioPath;
        var work = change.work!;
        if (source != null) {
          work = work.copyWith(audioFile: await audio.importFile(sourcePath: source, workId: work.id));
        }
        await works.upsert(work.status == WorkStatus.ready && work.audioFile == null
            ? work.copyWith(status: WorkStatus.failed, errorCode: 'CLOUD_AUDIO_MISSING')
            : work);
        pushed.add(work.id);
      }

      await _prefs.setStringList(pushedKey, pushed.toList());
      await _prefs.setInt(lastSyncKey, started.millisecondsSinceEpoch);
      state = state.copyWith(account: account, syncing: false, lastSyncedAt: started, failed: false);
      ref.invalidate(libraryProvider);
    } on Object catch (error, stackTrace) {
      ref.read(telemetrySinkProvider).recordError(error, stackTrace, fatal: false);
      state = state.copyWith(syncing: false, failed: true);
    }
  }

  /// A local deletion: tombstone it so other devices remove it too.
  Future<void> onDeleted(Work work) async {
    if (!state.enabled) return;
    try {
      await _gateway.remove(work.id);
      final pushed = (_prefs.getStringList(pushedKey) ?? const <String>[]).toSet()..remove(work.id);
      await _prefs.setStringList(pushedKey, pushed.toList());
    } on Object catch (error, stackTrace) {
      ref.read(telemetrySinkProvider).recordError(error, stackTrace, fatal: false);
    }
  }
}
