import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/application/music_library_providers.dart';
import '../../platform/application/music_platform_providers.dart';
import 'music_share_card_service.dart';

final shareCardServiceProvider = Provider<MusicShareCardService>(
  (ref) => MusicShareCardService(
    audio: ref.watch(audioStoreProvider),
    composer: ref.watch(videoComposerProvider),
  ),
);
