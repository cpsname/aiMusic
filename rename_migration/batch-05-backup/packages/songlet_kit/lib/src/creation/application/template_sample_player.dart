import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../playback/application/player_controller.dart';
import '../domain/idea.dart';
import 'creation_providers.dart';

/// Which create-home preview is playing — the key of an [Idea] — through the
/// one app-wide player so a preview and a song never overlap.
class TemplateSamplePlayer extends Notifier<String?> {
  final Map<String, String> _paths = {};

  @override
  String? build() {
    // Follows the shared player: another track or a stop clears the sample.
    ref.listen(playerControllerProvider, (previous, next) {
      final current = state;
      if (current == null) return;
      final path = _paths[current];
      if (next.path != path || (!next.isPlaying && previous?.isPlaying == true)) {
        state = null;
      }
    });
    return null;
  }

  /// Plays [idea]'s clip, or stops it when it is the one playing. The
  /// inspiration's preview comes first — the server lists the templates as
  /// inspirations and no longer sends `templates[]` — and a template's own
  /// sample (an older server) stands in when there is no preview or it fails.
  Future<void> toggleIdea(Idea idea) => _toggle(idea.key, () => _clip(idea));

  Future<String> _clip(Idea idea) async {
    final template = idea.template;
    final inspiration = idea.inspiration;
    Object? failure;
    StackTrace? trace;
    if (inspiration != null) {
      try {
        return await ref.read(inspirationSourceProvider).previewPath(inspiration);
      } on Object catch (error, stackTrace) {
        if (template == null) rethrow;
        failure = error;
        trace = stackTrace;
      }
    }
    try {
      return await ref.read(templateSampleSourceProvider).samplePath(template!.id);
    } on Object {
      // Both sources failed: the preview's failure is the one worth reporting.
      if (failure != null) Error.throwWithStackTrace(failure, trace!);
      rethrow;
    }
  }

  Future<void> _toggle(String key, Future<String> Function() resolve) async {
    final player = ref.read(playerControllerProvider.notifier);
    if (state == key) {
      state = null;
      await player.stop();
      return;
    }
    final path = _paths[key] ??= await resolve();
    state = key;
    await player.toggle(path);
  }

  Future<void> stop() async {
    if (state == null) return;
    state = null;
    await ref.read(playerControllerProvider.notifier).stop();
  }
}
