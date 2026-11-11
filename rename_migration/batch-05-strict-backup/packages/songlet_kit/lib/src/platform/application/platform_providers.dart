import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../share/data/method_channel_video_composer.dart';
import '../../store/application/store_providers.dart';
import '../data/channel_local_notifications.dart';
import '../data/native_bridge.dart';
import '../domain/local_notifications.dart';
import '../domain/native_gateways.dart';

/// Composition root of the PRD §6.4 bridge. The single [NativeBridge] registers
/// the Flutter-side handlers on creation, so it is read at startup.
final nativeBridgeProvider = Provider<NativeBridge>((ref) {
  final bridge = NativeBridge(outbox: ref.watch(signedTransactionOutboxProvider));
  ref.onDispose(bridge.dispose);
  return bridge;
});

final photoSourceProvider =
    Provider<PhotoSource>((ref) => ref.watch(nativeBridgeProvider));

final promptPolisherProvider =
    Provider<PromptPolisher>((ref) => ref.watch(nativeBridgeProvider));

final fileExporterProvider =
    Provider<FileExporter>((ref) => ref.watch(nativeBridgeProvider));

final attestationProvider =
    Provider<AttestationProvider>((ref) => ref.watch(nativeBridgeProvider));

final audioEngineProvider =
    Provider<AudioEngine>((ref) => ref.watch(nativeBridgeProvider));

final videoComposerProvider =
    Provider<VideoComposer>((ref) => const MethodChannelVideoComposer());

final videoSaverProvider = Provider<VideoSaver>((ref) => const MethodChannelVideoComposer());

/// Local notifications (ADR-0025).
final localNotificationsProvider = Provider<LocalNotifications>((ref) => const ChannelLocalNotifications());
