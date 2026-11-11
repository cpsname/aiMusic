import 'package:path/path.dart' as p;

import '../core/fields.dart';

/// An App Store preview slot (defaults/devices.yaml).
class DeviceSlot {
  const DeviceSlot({
    required this.id,
    required this.width,
    required this.height,
    required this.ascDisplay,
    required this.simulator,
    required this.captionSize,
    required this.captionBottom,
    required this.deviceFamily,
    required this.fileSuffix,
  });

  factory DeviceSlot.read(String id, Fields f) {
    f.only({'width', 'height', 'asc_display', 'simulator', 'caption_size', 'caption_bottom', 'device_family', 'file_suffix'});
    return DeviceSlot(
      id: id,
      width: f.integer('width'),
      height: f.integer('height'),
      ascDisplay: f.string('asc_display'),
      simulator: f.string('simulator'),
      captionSize: f.number('caption_size'),
      captionBottom: f.integer('caption_bottom'),
      deviceFamily: f.integer('device_family'),
      fileSuffix: f.raw['file_suffix'] as String? ?? '',
    );
  }

  final String id;
  final int width;
  final int height;
  final String ascDisplay;
  final String simulator;
  final double captionSize;
  final int captionBottom;
  final int deviceFamily;
  final String fileSuffix;

  /// [overrides] (app.yaml `slots.<id>`) on top of this slot.
  DeviceSlot merged(Fields overrides) {
    overrides.only({'caption_size', 'caption_bottom', 'simulator'});
    return DeviceSlot(
      id: id,
      width: width,
      height: height,
      ascDisplay: ascDisplay,
      simulator: overrides.optString('simulator') ?? simulator,
      captionSize: overrides.optNumber('caption_size', captionSize),
      captionBottom: overrides.optInteger('caption_bottom', captionBottom),
      deviceFamily: deviceFamily,
      fileSuffix: fileSuffix,
    );
  }
}

Map<String, DeviceSlot> loadSlots(String packageRoot) {
  final f = readYamlFile(p.join(packageRoot, 'defaults', 'devices.yaml')).map('slots');
  return {for (final id in f.raw.keys) id: DeviceSlot.read(id, f.map(id))};
}

/// Encoding, mixing and transition targets (defaults/encoding.yaml).
class Encoding {
  const Encoding({
    required this.videoBitrate,
    required this.fps,
    required this.gopSeconds,
    required this.profile,
    required this.level,
    required this.audioBitrate,
    required this.sampleRate,
    required this.channels,
    required this.fadeIn,
    required this.fadeOut,
    required this.crossfade,
    required this.duckThreshold,
    required this.duckRatio,
    required this.cardTransition,
    required this.bridgeIn,
    required this.bridgeOut,
    required this.captionIn,
    required this.captionRise,
    required this.captionOut,
  });

  factory Encoding.read(Fields f) {
    final video = f.map('video');
    final audio = f.map('audio');
    final mix = f.map('mix');
    final transitions = f.map('transitions');
    final captions = f.map('captions');
    return Encoding(
      videoBitrate: video.integer('bitrate'),
      fps: video.integer('fps'),
      gopSeconds: video.integer('gop_seconds'),
      profile: video.string('profile'),
      level: video.string('level'),
      audioBitrate: audio.integer('bitrate'),
      sampleRate: audio.integer('sample_rate'),
      channels: audio.integer('channels'),
      fadeIn: mix.number('fade_in'),
      fadeOut: mix.number('fade_out'),
      crossfade: mix.number('crossfade'),
      duckThreshold: mix.number('duck_threshold'),
      duckRatio: mix.number('duck_ratio'),
      cardTransition: transitions.number('card'),
      bridgeIn: transitions.number('bridge_in'),
      bridgeOut: transitions.number('bridge_out'),
      captionIn: captions.number('in'),
      captionRise: captions.number('rise'),
      captionOut: captions.number('out'),
    );
  }

  final int videoBitrate;
  final int fps;
  final int gopSeconds;
  final String profile;
  final String level;
  final int audioBitrate;
  final int sampleRate;
  final int channels;
  final double fadeIn;
  final double fadeOut;
  final double crossfade;
  final double duckThreshold;
  final double duckRatio;
  final double cardTransition;
  final double bridgeIn;
  final double bridgeOut;
  final double captionIn;
  final double captionRise;
  final double captionOut;
}

Encoding loadEncoding(String packageRoot) => Encoding.read(readYamlFile(p.join(packageRoot, 'defaults', 'encoding.yaml')));
