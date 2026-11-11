import 'dart:convert';

import 'package:flutter/services.dart';

import '../../common/json.dart';
import '../domain/music_cloud_sync.dart';
import '../domain/music_work.dart';
import 'music_work_codec.dart';

/// [MusicCloudSyncGateway] over `songlet/cloud_sync` (CloudSyncService.swift,
/// CloudKit private database, record type `MusicWork`) — beside the fixed PRD §6.4
/// bridge, like ADR-0006.
class MusicChannelCloudSync implements MusicCloudSyncGateway {
  const MusicChannelCloudSync([this._channel = const MethodChannel('songlet/cloud_sync')]);

  final MethodChannel _channel;

  @override
  Future<MusicCloudAccount> account() async {
    try {
      return MusicCloudAccount.fromWire(await _channel.invokeMethod<String>('account'));
    } on PlatformException {
      return MusicCloudAccount.unavailable;
    } on MissingPluginException {
      return MusicCloudAccount.unavailable;
    }
  }

  @override
  Future<void> push(MusicWork work, {String? audioPath}) => _channel.invokeMethod<void>('push', {
        'id': work.id,
        'record': jsonEncode(MusicWorkCodec.toJson(work)),
        'audioPath': audioPath,
      });

  @override
  Future<void> remove(String workId) => _channel.invokeMethod<void>('remove', {'id': workId});

  @override
  Future<List<MusicCloudWorkChange>> pull({DateTime? since}) async {
    final raw = await _channel.invokeListMethod<Object?>('pull', {
      'since': since?.toUtc().millisecondsSinceEpoch,
    });
    return [
      for (final change in (raw ?? const []).map(asMap))
        if (change['deleted'] == true)
          MusicCloudWorkChange.deleted(asString(change['id']))
        else
          MusicCloudWorkChange.upsert(
            MusicWorkCodec.fromJson(asMap(jsonDecode(asString(change['record'])))),
            audioPath: asNullableString(change['audioPath']),
          ),
    ];
  }
}
