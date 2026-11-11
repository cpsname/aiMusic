import 'package:flutter/services.dart';

import '../../platform/domain/native_gateways.dart';

/// [VideoComposer] over the `songlet/share_card` channel (AVAssetWriter in
/// ShareCardComposer.swift — kept outside the fixed PRD §6.4 Pigeon bridge).
class MethodChannelVideoComposer implements VideoComposer, VideoSaver {
  const MethodChannelVideoComposer([
    this._channel = const MethodChannel('songlet/share_card'),
  ]);

  final MethodChannel _channel;

  @override
  Future<void> compose({
    required List<VideoFrame> frames,
    required String audioPath,
    required String outputPath,
    required double duration,
    int width = 1080,
    int height = 1920,
  }) =>
      _channel.invokeMethod<void>('compose', <String, Object?>{
        'frames': [
          for (final f in frames) {'path': f.path, 'start': f.start},
        ],
        'audioPath': audioPath,
        'outputPath': outputPath,
        'duration': duration,
        'width': width,
        'height': height,
        'fps': 5,
      });

  @override
  Future<bool> saveVideo(String path) async =>
      await _channel.invokeMethod<bool>('saveToPhotos', <String, Object?>{'path': path}) ?? false;
}
