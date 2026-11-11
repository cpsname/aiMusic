import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/application/library_providers.dart';
import '../../platform/application/platform_providers.dart';
import 'share_card_service.dart';

final shareCardServiceProvider = Provider<ShareCardService>(
  (ref) => ShareCardService(
    audio: ref.watch(audioStoreProvider),
    composer: ref.watch(videoComposerProvider),
  ),
);
