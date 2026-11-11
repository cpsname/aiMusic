import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/channel_music_speech_gateway.dart';
import '../domain/music_speech_gateway.dart';
import 'music_dictation_controller.dart';

/// Composition root of on-device dictation (ADR-0006).
final speechGatewayProvider =
    Provider<MusicSpeechGateway>((ref) => const MusicChannelSpeechGateway());

final dictationProvider =
    NotifierProvider<MusicDictationController, MusicDictationState>(MusicDictationController.new);
