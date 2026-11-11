import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/music_art.dart';
import '../common/music_page_layout.dart';
import '../common/music_test_id.dart';
import '../create/music_create_labels.dart';
import '../mv/music_mv_entry.dart';
import '../routing/music_navigation.dart';
import '../routing/music_routes.dart';
import 'music_lyrics_model.dart';
import 'music_playback_binding.dart';
import 'music_work_actions.dart';
import 'music_work_title.dart';

/// P07 — the 30-second preview: cover, scrubber, loop, timed lyrics, then the
/// way to the full song (PRD §8.2), share and "another version" (F14).
class MusicPreviewPage extends ConsumerStatefulWidget {
  const MusicPreviewPage({super.key, required this.workId});

  final String workId;

  @override
  ConsumerState<MusicPreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends ConsumerState<MusicPreviewPage>
    with MusicWorkPlaybackBinding {
  @override
  String get workId => widget.workId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = SongletColors.of(context);
    final work = ref.watch(workByIdProvider(widget.workId));
    final audio = ref.watch(workAudioPathProvider(widget.workId));
    final path = audio.value;
    final playback = ref.watch(playerControllerProvider);
    if (work == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    bindPlayback(work, path);
    final view = MusicPlayerView(work, playback, path);
    final player = ref.read(playerControllerProvider.notifier);
    final actions = MusicWorkActions(context, ref);

    return Scaffold(
      body: MusicPageFrame(
        header: MusicPushedHeader(
          actions: [
            IconButton(
              tooltip: l10n.previewShare,
              onPressed: () => context.open(MusicShareRoute(work.id)),
              icon: const Icon(Icons.ios_share_rounded),
            ),
            IconButton(
              tooltip: l10n.commonMore,
              onPressed: () => showWorkMenu(work),
              icon: const Icon(Icons.more_horiz_rounded),
            ),
          ],
        ),
        children: [
          // The video the length panel asked for (docs/ui P23).
          MusicAutoVideoBanner(workId: work.id),
          Center(
            child: SizedBox(
              width: SongletSize.coverLarge,
              child: CoverArt(
                seed: work.id,
                image: MusicSongletArt.cover(work),
                framed: true,
                badgeLabel: l10n.playerAiGenerated,
              ),
            ),
          ),
          const SizedBox(height: SongletSpace.x4),
          Text(
            workTitle(l10n, work),
            textAlign: TextAlign.center,
            style: SongletType.title1.copyWith(color: c.ink),
          ),
          MetaLine(
            parts: [
              workKindName(
                l10n,
                template: work.template,
                occasion: work.occasion,
              ),
              workGenre(l10n, work),
              clockLabel(view.duration, l10n.localeName),
            ],
          ),
          const SizedBox(height: SongletSpace.x4),
          if (path == null)
            audio.isLoading ? const MusicAudioLoading() : const MusicMissingAudio()
          else ...[
            MusicTestId(
              'player.scrubber',
              child: WaveformScrubber(
                bars: waveformBars(work.id),
                progress: view.fraction,
                elapsedLabel: clockLabel(view.position, l10n.localeName),
                totalLabel: clockLabel(view.duration, l10n.localeName),
                semanticsLabel: l10n.playerPosition,
                labelFor: (f) => clockLabel(f * view.duration, l10n.localeName),
                onSeek: (f) => player.seek(f * view.duration),
              ),
            ),
            const SizedBox(height: SongletSpace.x2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MusicTestId(
                  'player.loop',
                  child: LabeledIconToggle(
                    icon: Icons.repeat_rounded,
                    label: l10n.playerLoop,
                    selected: playback.loop,
                    onPressed: () => player.setLoop(loop: !playback.loop),
                  ),
                ),
                const SizedBox(width: SongletSpace.x8),
                MusicTestId(
                  'player.toggle',
                  child: PlayButton(
                    playing: view.playing,
                    onPressed: () => player.toggle(path),
                    playLabel: l10n.playerPlay,
                    pauseLabel: l10n.playerPause,
                  ),
                ),
                const SizedBox(width: SongletSpace.x8 + SongletSize.iconXl),
              ],
            ),
          ],
          if (!work.isInstrumental && view.lines.isNotEmpty) ...[
            const SizedBox(height: SongletSpace.x4),
            SyncedLyricsView(
              lines: lyricLineViews(
                view.lines,
                withTimes: true,
                locale: l10n.localeName,
              ),
              active: view.activeLine,
              onTapLine: path == null
                  ? null
                  : (i) => player.seek(view.lines[i].start ?? 0),
            ),
          ],
          const SizedBox(height: SongletSpace.x5),
          MusicTestId(
            'player.fullSong',
            child: ObsButton(
              label: l10n.previewGetFull,
              icon: Icons.arrow_forward_rounded,
              onPressed: () => actions.makeFullSong(work),
            ),
          ),
          const SizedBox(height: SongletSpace.x3),
          MusicTestId(
            'player.share',
            child: SecondaryButton(
              label: l10n.previewShare,
              trailingIcon: Icons.ios_share_rounded,
              onPressed: () => context.open(MusicShareRoute(work.id)),
            ),
          ),
          const SizedBox(height: SongletSpace.x2),
          Center(
            child: MusicTestId(
              'player.anotherVersion',
              child: TextButton(
                onPressed: () => actions.anotherVersion(work),
                style: TextButton.styleFrom(foregroundColor: c.inkSecondary),
                child: Text(
                  l10n.previewAnother,
                  style: SongletType.subhead.copyWith(
                    color: c.inkSecondary,
                    decoration: TextDecoration.underline,
                    decorationColor: c.inkSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
