import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';

import '../domain/music_region_preset.dart';

/// The user's default lyrics language (docs/ui P14), or null to follow the
/// region preset and the device language (PRD §11.3 default).
class MusicLyricLanguagePreference extends Notifier<MusicLyricLanguage?> {
  static const String key = 'songlet.default_lyric_language';

  @override
  MusicLyricLanguage? build() => MusicLyricLanguage.fromCode(ref.watch(keyValueStoreProvider).getString(key));

  Future<void> set(MusicLyricLanguage? language) async {
    final prefs = ref.read(keyValueStoreProvider);
    if (language == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, language.code);
    }
    state = language;
  }
}
