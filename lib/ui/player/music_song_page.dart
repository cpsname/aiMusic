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

/// P09 — the full song: sections under the waveform, section jumps, shuffle
/// and repeat, synced lyrics, Download · Share · License · Regenerate, and
/// the music-video entry (docs/ui P19) with the automatic video (P23).
class MusicSongPage extends ConsumerStatefulWidget {
  const MusicSongPage({super.key, required this.workId});

  final String workId;

  @override
  ConsumerState<MusicSongPage> createState() => _SongPageState();
}

class _SongPageState extends ConsumerState<MusicSongPage> with MusicWorkPlaybackBinding {
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
      body: MusicPageFrame(        header: MusicPushedHeader(
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
          MusicAutoVideoBanner(workId: work.id),
          // The sleeve head: the plate at the margin with its catalogue spine,
          // the title set beside it, then the staff that opens the player.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Spine(label: work.isClip ? 'A1 · LYRIA 3' : 'A1 · LYRIA 3.5'),
              const SizedBox(width: SongletSpace.x1),
              SizedBox.square(
                dimension: SongletSize.thumbnail * 1.7,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: SongletRadius.thumbAll,
                    border: Border.all(color: c.hairline),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(SongletRadius.thumb),
                    ),
                    child: CoverArt(
                      seed: work.id,
                      image: MusicSongletArt.cover(work),
                      badgeLabel: l10n.playerAiGenerated,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: SongletSpace.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workTitle(l10n, work),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SongletType.largeTitle.copyWith(color: c.ink),
                    ),
                    const SizedBox(height: 6),
                    MetaLine(
                      parts: [
                        clockLabel(view.duration, l10n.localeName),
                        workGenre(l10n, work),
                        if (language != null)
                          languageName(l10n, language)
                        else if (region != null)
                          countryName(l10n, region.code),
                      ],
                      textAlign: TextAlign.start,
                      style: SongletType.folio.copyWith(
                        color: c.inkSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: SongletSpace.x4),
          const StaffDivider(accentFirst: true),
          const SizedBox(height: SongletSpace.x3),
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
                playhead: PlayheadStyle.line,
                labelFor: (f) => clockLabel(f * view.duration, l10n.localeName),
                onSeek: (f) => player.seek(f * view.duration),
              ),
            ),
            if (sections.isNotEmpty) ...[
              const SizedBox(height: SongletSpace.x2),
              MusicTestId(
                'player.sections',
                child: SectionTrack(
                  sections: sections,
                  current: currentSection,
                  onSelect: (i) => player.seek(work.structure[i].start),
                ),
              ),
            ],
            const SizedBox(height: SongletSpace.x3),
            MusicTestId(
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
                  () => context.open(MusicDownloadRoute(work.id)),
                ),
                (
                  'share',
                  Icons.ios_share_rounded,
                  l10n.actionShare,
                  () => context.open(MusicShareRoute(work.id)),
                ),
                (
                  'license',
                  Icons.description_outlined,
                  l10n.actionLicense,
                  () => context.open(MusicDownloadRoute(work.id)),
                ),
                (
                  'regenerate',
                  Icons.autorenew_rounded,
                  l10n.actionRegenerate,
                  () => MusicWorkActions(context, ref).anotherVersion(work),
                ),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: SongletSpace.x1,
                    ),
                    child: MusicTestId(
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
          MusicMvEntryCard(work: work),
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

/// The catalogue spine of the sleeve: the folded edge of the plate, lettered
/// with the model's mark and ruled in ink — the one place the player says what
/// made this recording, without a badge or an icon.
class _Spine extends StatelessWidget {
  const _Spine({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Container(
      width: 20,
      height: SongletSize.thumbnail * 1.7,
      decoration: BoxDecoration(
        color: c.surfaceMuted.withValues(alpha: 0.45),
        border: BorderDirectional(
          start: BorderSide(color: c.ink, width: SongletSize.rule),
          end: BorderSide(color: c.hairline),
        ),
      ),
      child: ExcludeSemantics(
        child: RotatedBox(
          quarterTurns: 3,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: SongletType.folio.copyWith(
                color: c.inkSecondary,
                fontSize: 8.5,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
