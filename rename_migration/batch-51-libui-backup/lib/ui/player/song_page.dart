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

/// P09 — the full song: sections under the waveform, section jumps, shuffle
/// and repeat, synced lyrics, Download · Share · License · Regenerate, and
/// the music-video entry (docs/ui P19) with the automatic video (P23).
class SongPage extends ConsumerStatefulWidget {
  const SongPage({super.key, required this.workId});

  final String workId;

  @override
  ConsumerState<SongPage> createState() => _SongPageState();
}

class _SongPageState extends ConsumerState<SongPage> with WorkPlaybackBinding {
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
    final duration = view.duration <= 0 ? 1.0 : view.duration;
    final sections = [
      for (final s in work.structure)
        (
          label: sectionName(l10n, s.label),
          start: s.start / duration,
          end: s.end / duration,
        ),
    ];
    final currentSection = view.current ? player.sectionAt(view.position) : -1;
    final region = RegionPresets.byCode(work.region);
    final language = MusicLyricLanguage.fromCode(work.lyricLanguage);

    return Scaffold(
      body: PageFrame(
        header: PushedHeader(
          actions: [
            IconCircleButton(
              icon: Icons.more_horiz_rounded,
              tooltip: l10n.commonMore,
              onPressed: () => showWorkMenu(work),
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
              clockLabel(view.duration, l10n.localeName),
              workGenre(l10n, work),
              if (language != null)
                languageName(l10n, language)
              else if (region != null)
                countryName(l10n, region.code),
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
                playhead: PlayheadStyle.line,
                labelFor: (f) => clockLabel(f * view.duration, l10n.localeName),
                onSeek: (f) => player.seek(f * view.duration),
              ),
            ),
            if (sections.isNotEmpty) ...[
              const SizedBox(height: SongletSpace.x2),
              TestId(
                'player.sections',
                child: SectionTrack(
                  sections: sections,
                  current: currentSection,
                  onSelect: (i) => player.seek(work.structure[i].start),
                ),
              ),
            ],
            const SizedBox(height: SongletSpace.x3),
            TestId(
              'player.toggle',
              child: PlaybackControls(
                playing: view.playing,
                onPlayPause: () => player.toggle(path),
                labels: (
                  play: l10n.playerPlay,
                  pause: l10n.playerPause,
                  previous: l10n.playerPrevSection,
                  next: l10n.playerNextSection,
                  shuffle: l10n.playerShuffle,
                  repeat: l10n.playerRepeat,
                ),
                onPrevious: sections.isEmpty
                    ? null
                    : () => player.jumpSection(-1),
                onNext: sections.isEmpty ? null : () => player.jumpSection(1),
                onShuffle: sections.length < 2
                    ? null
                    : () => player.setShuffle(shuffle: !playback.shuffle),
                shuffle: playback.shuffle,
                onRepeat: () => player.setLoop(loop: !playback.loop),
                repeat: playback.loop,
              ),
            ),
          ],
          if (!work.isInstrumental && view.lines.isNotEmpty) ...[
            const SizedBox(height: SongletSpace.x4),
            SyncedLyricsView(
              lines: lyricLineViews(
                view.lines,
                withTimes: false,
                locale: l10n.localeName,
              ),
              active: view.activeLine,
              onTapLine: path == null
                  ? null
                  : (i) => player.seek(view.lines[i].start ?? 0),
            ),
          ],
          const SizedBox(height: SongletSpace.x4),
          Row(
            children: [
              for (final (id, icon, label, onTap) in [
                (
                  'download',
                  Icons.download_rounded,
                  l10n.actionDownload,
                  () => context.open(DownloadRoute(work.id)),
                ),
                (
                  'share',
                  Icons.ios_share_rounded,
                  l10n.actionShare,
                  () => context.open(ShareRoute(work.id)),
                ),
                (
                  'license',
                  Icons.description_outlined,
                  l10n.actionLicense,
                  () => context.open(DownloadRoute(work.id)),
                ),
                (
                  'regenerate',
                  Icons.autorenew_rounded,
                  l10n.actionRegenerate,
                  () => WorkActions(context, ref).anotherVersion(work),
                ),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: SongletSpace.x1,
                    ),
                    child: TestId(
                      'player.$id',
                      child: ActionTile(
                        icon: icon,
                        label: label,
                        onPressed: onTap,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: SongletSpace.x4),
          // Music video (PRD ch.15, docs/ui P19): this song's video, or the hub.
          MvEntryCard(work: work),
          const SizedBox(height: SongletSpace.x4),
          Text(
            l10n.playerProvenance,
            textAlign: TextAlign.center,
            style: SongletType.footnote.copyWith(color: c.inkSecondary),
          ),
        ],
      ),
    );
  }
}
