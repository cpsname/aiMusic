import 'package:app_config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:songlet_kit/songlet_kit.dart';

/// Switches the app reads from the remote config (`GET /v1/app/config`
/// `config`, app_config) — fail-open, so each has a safe default.
abstract final class RemoteFlags {
  /// WAV export for Premier full songs (contract v2 §7): off until the
  /// platform's lyria-3.5 WAV probe passes. While off, the download page shows
  /// no WAV row and the paywall does not list WAV as a Premier benefit.
  static const String wavExport = 'wav_export';

  /// Music-video settings (`config.mv`, contract gap G1, ADR-0026). `qualities` lists
  /// the render qualities the platform offers (`["standard", "high"]`);
  /// absent or unreadable = standard only, and the hub shows no choice.
  static const String mv = 'mv';
  static const String mvQualities = 'qualities';

  /// The qualities in [config] (the remote `config.mv` object), in platform
  /// order, standard always first.
  static List<MvQuality> mvQualitiesFrom(Object? config) {
    final raw = config is Map ? config[mvQualities] : null;
    final offered = <MvQuality>{MvQuality.standard};
    if (raw is List) {
      for (final value in raw) {
        final quality = MvQuality.fromWire(value is String ? value : null);
        if (quality != null) offered.add(quality);
      }
    }
    return offered.toList(growable: false);
  }
}

/// Whether WAV export is offered (read from a widget's `build`).
bool wavExportEnabled(WidgetRef ref) => ref
    .watch(appConfigProvider)
    .configValue<bool>(RemoteFlags.wavExport, false);

/// The music-video qualities the hub offers (read from a widget's `build`).
List<MvQuality> mvQualities(WidgetRef ref) => RemoteFlags.mvQualitiesFrom(
  ref.watch(appConfigProvider).configValue<Object?>(RemoteFlags.mv, null),
);
