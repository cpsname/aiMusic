import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/launch_clock.dart';
import '../common/test_id.dart';
import '../routing/navigation.dart';
import '../routing/routes.dart';
import 'lyrics_model.dart';
import 'work_actions.dart';

/// Player-page plumbing shared by P07 and P09: resolves the work's audio,
/// autoplays it once, hands the section windows to the player, and shows the
/// first-session paywall after a free user's first finished preview (PRD
/// §8.2 — after the first listen, not at launch).
mixin WorkPlaybackBinding<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  static const String firstSessionPaywallKey =
      'songlet.paywall.first_listen_shown';

  String get workId;

  bool _started = false;

  /// Call from build: wires playback once the audio path is known.
  void bindPlayback(Work work, String? path) {
    if (path == null) return;
    ref.listen<PlaybackState>(playerControllerProvider, (previous, next) {
      if (previous != null &&
          next.completedCount > previous.completedCount &&
          next.isCurrent(path)) {
        _onCompleted(work);
      }
    });
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final player = ref.read(playerControllerProvider.notifier);
      if (!ref.read(playerControllerProvider).isCurrent(path)) {
        await player.toggle(path);
        if (work.isClip) ref.read(firstListenRecorderProvider)();
      }
      player.setSections([
        for (final s in work.structure) (start: s.start, end: s.end),
      ]);
    });
  }

  Future<void> _onCompleted(Work work) async {
    if (!work.isClip) return;
    final store = ref.read(keyValueStoreProvider);
    if (store.getBool(firstSessionPaywallKey) ?? false) return;
    final entitlement = ref.read(musicEntitlementProvider).value;
    if (entitlement != null && entitlement.tier.isPaid) return;
    await store.setBool(firstSessionPaywallKey, value: true);
    if (!mounted) return;
    await context.openPaywall(PaywallReason.fullSong);
  }

  /// The work's more-menu: details and delete.
  Future<void> showWorkMenu(Work work) async {
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(l10n.actionDetails),
              onTap: () => Navigator.pop(context, 'details'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: SongletColors.of(context).danger,
              ),
              title: Text(
                l10n.commonDelete,
                style: TextStyle(color: SongletColors.of(context).danger),
              ),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'details':
        context.open(WorkRoute(work.id));
      case 'delete':
        unawaited(WorkActions(context, ref).delete(work));
    }
  }
}

/// Resolved player facts for a work at the current playback position.
class PlayerView {
  PlayerView(this.work, this.playback, this.path)
    : duration = workDuration(work),
      lines = timedLines(lyricBlocks(work.lyrics, work.structure));

  final Work work;
  final PlaybackState playback;
  final String? path;
  final double duration;
  final List<TimedLine> lines;

  bool get current => path != null && playback.isCurrent(path!);
  bool get playing => current && playback.isPlaying;
  double get position => current ? playback.position : 0;
  double get fraction => duration <= 0 ? 0 : (position / duration).clamp(0, 1);
  int get activeLine => current ? activeLineAt(position) : -1;

  int activeLineAt(double seconds) =>
      lines.isEmpty ? -1 : activeLineIndex(lines, seconds);
}

/// Index of the line being sung (exposed for tests).
int activeLineIndex(List<TimedLine> lines, double position) =>
    activeLine(lines, position);

/// The scrubber's place while the work's audio path is still being read: a
/// song that has just landed is not "missing" for that moment.
class AudioLoading extends StatelessWidget {
  const AudioLoading({super.key});

  @override
  Widget build(BuildContext context) => const TestId(
    'player.audioLoading',
    child: SizedBox(height: SongletSize.waveformHeight),
  );
}

/// A missing-audio state (the file was removed from the device).
class MissingAudio extends StatelessWidget {
  const MissingAudio({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TestId(
      'player.missing',
      child: EmptyState(
        icon: Icons.music_off_outlined,
        title: l10n.playerMissing,
        message: l10n.libraryEmptyAction,
        actionLabel: l10n.navLibrary,
        onAction: () => context.goTo(const LibraryRoute()),
      ),
    );
  }
}
