import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../share/data/music_method_channel_video_composer.dart';
import '../../store/application/store_providers.dart';
import '../data/channel_music_local_notifications.dart';
import '../data/music_native_bridge.dart';
import '../domain/music_local_notifications.dart';
import '../domain/music_native_gateways.dart';

/// Composition root of the PRD §6.4 bridge. The single [MusicNativeBridge] registers
/// the Flutter-side handlers on creation, so it is read at startup.
final nativeBridgeProvider = Provider<MusicNativeBridge>((ref) {
  final bridge = MusicNativeBridge(outbox: ref.watch(signedTransactionOutboxProvider));
  ref.onDispose(bridge.dispose);
  return bridge;
});

final photoSourceProvider =
    Provider<MusicPhotoSource>((ref) => ref.watch(nativeBridgeProvider));

final promptPolisherProvider =
    Provider<MusicPromptPolisher>((ref) => ref.watch(nativeBridgeProvider));

final fileExporterProvider =
    Provider<MusicFileExporter>((ref) => ref.watch(nativeBridgeProvider));

final attestationProvider =
    Provider<MusicAttestationProvider>((ref) => ref.watch(nativeBridgeProvider));

final audioEngineProvider =
    Provider<MusicAudioEngine>((ref) => ref.watch(nativeBridgeProvider));

final videoComposerProvider =
    Provider<MusicVideoComposer>((ref) => const MusicMethodChannelVideoComposer());

final videoSaverProvider = Provider<MusicVideoSaver>((ref) => const MusicMethodChannelVideoComposer());

/// Local notifications (ADR-0025).
final localNotificationsProvider = Provider<MusicLocalNotifications>((ref) => const MusicChannelLocalNotifications());
