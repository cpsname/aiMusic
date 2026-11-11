import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/art.dart';
import '../common/page_layout.dart';
import '../common/test_id.dart';
import '../create/create_labels.dart';
import '../mv/mv_entry.dart';
import '../routing/navigation.dart';
import '../routing/routes.dart';
import 'lyrics_model.dart';
import 'playback_binding.dart';
import 'work_actions.dart';
import 'work_title.dart';

/// P07 — the 30-second preview: cover, scrubber, loop, timed lyrics, then the
/// way to the full song (PRD §8.2), share and "another version" (F14).
class PreviewPage extends ConsumerStatefulWidget {
  const PreviewPage({super.key, required this.workId});

  final String workId;

  @override
  ConsumerState<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends ConsumerState<PreviewPage>
    with WorkPlaybackBinding {
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
    final view = PlayerView(work, playback, path);
    final player = ref.read(playerControllerProvider.notifier);
    final actions = WorkActions(context, ref);

    return Scaffold(
      body: PageFrame(
        header: PushedHeader(
          actions: [
            IconButton(
              tooltip: l10n.previewShare,
              onPressed: () => context.open(ShareRoute(work.id)),
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
          AutoVideoBanner(workId: work.id),
          Center(
            child: SizedBox(
              width: SongletSize.coverLarge,
              child: CoverArt(
                seed: work.id,
                image: SongletArt.cover(work),
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
            audio.isLoading ? const AudioLoading() : const MissingAudio()
          else ...[
            TestId(
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
                TestId(
                  'player.loop',
                  child: LabeledIconToggle(
                    icon: Icons.repeat_rounded,
                    label: l10n.playerLoop,
                    selected: playback.loop,
                    onPressed: () => player.setLoop(loop: !playback.loop),
                  ),
                ),
                const SizedBox(width: SongletSpace.x8),
                TestId(
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
          TestId(
            'player.fullSong',
            child: ObsButton(
              label: l10n.previewGetFull,
              icon: Icons.arrow_forward_rounded,
              onPressed: () => actions.makeFullSong(work),
            ),
          ),
          const SizedBox(height: SongletSpace.x3),
          TestId(
            'player.share',
            child: SecondaryButton(
              label: l10n.previewShare,
              trailingIcon: Icons.ios_share_rounded,
              onPressed: () => context.open(ShareRoute(work.id)),
            ),
          ),
          const SizedBox(height: SongletSpace.x2),
          Center(
            child: TestId(
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
