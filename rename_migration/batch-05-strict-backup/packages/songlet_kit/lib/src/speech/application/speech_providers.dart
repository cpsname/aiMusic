import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/channel_speech_gateway.dart';
import '../domain/speech_gateway.dart';
import 'dictation_controller.dart';

/// Composition root of on-device dictation (ADR-0006).
final speechGatewayProvider =
    Provider<SpeechGateway>((ref) => const ChannelSpeechGateway());

final dictationProvider =
    NotifierProvider<DictationController, DictationState>(DictationController.new);
