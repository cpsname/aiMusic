import 'dart:io';

import '../config/defaults.dart';
import '../config/script.dart';
import '../core/probe.dart';
import '../post/compose.dart';

/// Apple's App Preview limits (docs/store/apple-preview-rules.md).
const int maxPreviewBytes = 500 * 1024 * 1024;
const double maxFrameRate = 30;
const int minVideoBitrate = 10000000;
const int maxVideoBitrate = 12000000;
const Set<int> audioSampleRates = {44100, 48000};
const int targetAudioBitrate = 256000;

/// The spec layer for one rendered preview: what ffprobe reads, against
/// Apple's specification.
class SpecCheck {
  SpecCheck();

  final List<String> failures = [];
  String resolution = '-';
  String duration = '-';
  String fps = '-';
  String video = '-';
  String audio = '-';
  String size = '-';

  bool get ok => failures.isEmpty;
}

SpecCheck checkSpec(PreviewFiles files, PreviewScript script, DeviceSlot slot, {Prober prober = const FfprobeProber()}) {
  final check = SpecCheck();
  void need(bool ok, String failure) {
    if (!ok) check.failures.add(failure);
  }

  if (!File(files.video).existsSync()) {
    check.failures.add('missing ${files.video}');
    return check;
  }
  final info = prober.probe(files.video);
  if (info == null) {
    check.failures.add('unreadable ${files.video}');
    return check;
  }
  final v = info.video;
  final a = info.audio;
  check
    ..resolution = v == null ? 'none' : '${v.width}×${v.height}'
    ..duration = '${info.duration.toStringAsFixed(2)}s'
    ..fps = v == null ? '-' : v.frameRate.toStringAsFixed(2)
    ..video = v == null ? '-' : '${v.codec} ${v.profile}@${v.level / 10} ${(v.bitRate / 1e6).toStringAsFixed(2)}M'
    ..audio = a == null ? '-' : '${a.codec} ${a.channels}ch ${a.sampleRate} ${(a.bitRate / 1000).round()}k'
    ..size = '${(info.size / 1048576).toStringAsFixed(1)}MB';
  need(info.formatName.contains('mp4'), 'container ${info.formatName} is not MPEG-4');
  need(v != null && v.width == slot.width && v.height == slot.height, 'resolution ${check.resolution} ≠ ${slot.width}×${slot.height}');
  need(info.duration >= minPreviewSeconds && info.duration <= maxPreviewSeconds, 'duration ${check.duration} outside 15–30 s');
  need((info.duration - script.duration).abs() < 0.1, 'duration ${check.duration} ≠ the script\'s ${script.duration}s');
  need(v != null && v.frameRate <= maxFrameRate + 0.01 && v.frameRate > 0, 'frame rate ${check.fps} > $maxFrameRate');
  need(v?.codec == 'h264', 'video codec ${v?.codec} is not H.264');
  need(v?.pixFmt == 'yuv420p', 'pixel format ${v?.pixFmt} is not yuv420p');
  need(v?.profile == 'High' && v?.level == 40, 'H.264 ${v?.profile} level ${v?.level} is not High Profile Level 4.0');
  need(v != null && v.bitRate >= minVideoBitrate && v.bitRate <= maxVideoBitrate, 'video bitrate ${check.video} outside 10–12 Mbps');
  need(a?.codec == 'aac', 'audio codec ${a?.codec} is not AAC');
  need(a?.channels == 2, 'audio is not stereo');
  need(a != null && audioSampleRates.contains(a.sampleRate), 'audio sample rate ${a?.sampleRate} is not 44.1/48 kHz');
  need(a != null && (a.bitRate - targetAudioBitrate).abs() <= targetAudioBitrate * 0.05, 'audio bitrate ${check.audio} ≠ 256 kbps');
  need(info.size <= maxPreviewBytes, 'size ${check.size} > 500 MB');
  final poster = File(files.poster).existsSync() ? prober.probe(files.poster)?.video : null;
  need(poster != null && poster.width == slot.width && poster.height == slot.height, 'poster frame missing or not ${slot.width}×${slot.height}');
  need(File(files.captions).existsSync(), 'captions file missing');
  need(File(files.edl).existsSync(), 'EDL missing');
  return check;
}
