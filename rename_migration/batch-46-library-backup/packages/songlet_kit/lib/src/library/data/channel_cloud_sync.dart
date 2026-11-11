import 'dart:convert';

import 'package:flutter/services.dart';

import '../../common/json.dart';
import '../domain/cloud_sync.dart';
import '../domain/work.dart';
import 'work_codec.dart';

/// [CloudSyncGateway] over `songlet/cloud_sync` (CloudSyncService.swift,
/// CloudKit private database, record type `Work`) — beside the fixed PRD §6.4
/// bridge, like ADR-0006.
class ChannelCloudSync implements CloudSyncGateway {
  const ChannelCloudSync([this._channel = const MethodChannel('songlet/cloud_sync')]);

  final MethodChannel _channel;

  @override
  Future<CloudAccount> account() async {
    try {
      return CloudAccount.fromWire(await _channel.invokeMethod<String>('account'));
    } on PlatformException {
      return CloudAccount.unavailable;
    } on MissingPluginException {
      return CloudAccount.unavailable;
    }
  }

  @override
  Future<void> push(Work work, {String? audioPath}) => _channel.invokeMethod<void>('push', {
        'id': work.id,
        'record': jsonEncode(WorkCodec.toJson(work)),
        'audioPath': audioPath,
      });

  @override
  Future<void> remove(String workId) => _channel.invokeMethod<void>('remove', {'id': workId});

  @override
  Future<List<CloudWorkChange>> pull({DateTime? since}) async {
    final raw = await _channel.invokeListMethod<Object?>('pull', {
      'since': since?.toUtc().millisecondsSinceEpoch,
    });
    return [
      for (final change in (raw ?? const []).map(asMap))
        if (change['deleted'] == true)
          CloudWorkChange.deleted(asString(change['id']))
        else
          CloudWorkChange.upsert(
            WorkCodec.fromJson(asMap(jsonDecode(asString(change['record'])))),
            audioPath: asNullableString(change['audioPath']),
          ),
    ];
  }
}
