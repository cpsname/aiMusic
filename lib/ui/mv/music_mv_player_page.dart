import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:infra_core/infra_core.dart';
import 'package:share_plus/share_plus.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:video_player/video_player.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/music_messages.dart';
import '../common/music_page_layout.dart';
import '../common/music_test_id.dart';
import '../player/music_lyrics_model.dart';
import '../player/music_work_title.dart';
import '../routing/music_navigation.dart';
import '../routing/music_routes.dart';
import 'music_mv_labels.dart';
import 'music_mv_timeline.dart';

/// P26 (portrait) / P27 (landscape, iPad, 16:9 and 1:1 videos) — the
/// finished music video, immersive and dark (PRD §15.2 step 5): the video
/// full-bleed with its AI badge (burned in by the platform, and stated on
/// the page, PRD §9.4), a scrubber, the song's sections and synced lyrics on
/// the video's clock (a chorus video is offset by its window), and Share ·
/// Save to Photos · Save to Files · Make another. No picture-in-picture.
class MusicMvPlayerPage extends ConsumerStatefulWidget {
  const MusicMvPlayerPage({super.key, required this.workId, required this.videoId});

  final String workId;
  final String videoId;

  @override
  ConsumerState<MusicMvPlayerPage> createState() => _MvPlayerPageState();
}

class _MvPlayerPageState extends ConsumerState<MusicMvPlayerPage> {
  VideoPlayerController? _player;
  String? _boundPath;
  String? _busy;

  /// Width of the side panel beside the video on wide layouts.
  static const double _sidePanelWidth = SongletSize.anchoredPanelWidth;

  /// Share of the height the video may take above the panel (portrait);
  /// the panel keeps the rest for the scrubber and the actions.
  static const double _portraitVideoShare = 0.55;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  void _bind(String? path) {
    if (path == null || path == _boundPath) return;
    _boundPath = path;
    final old = _player;
    final player = VideoPlayerController.file(File(path))..setLooping(true);
    _player = player;
    unawaited(old?.dispose());
    unawaited(
      player.initialize().then((_) {
        if (!mounted) return;
        player.addListener(_onTick);
        setState(() {});
      }),
    );
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  Future<void> _perform(String id, Future<void> Function() action) async {
    if (_busy != null) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = id);
    try {
      await action();
    } on Object catch (error, stackTrace) {
      final failure = ref.read(errorHandlerProvider).handle(error, stackTrace);
      ref.read(messageControllerProvider).show(failureMessage(l10n, failure));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _share(String path) => _perform('share', () async {
    final l10n = AppLocalizations.of(context);
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'video/mp4')],
        text: l10n.mvShareText,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  });

  Future<void> _save(String path) => _perform('save', () async {
    final l10n = AppLocalizations.of(context);
    final saved = await ref.read(videoSaverProvider).saveVideo(path);
    final messages = ref.read(messageControllerProvider);
    saved
        ? messages.success(l10n.shareVideoSaved)
        : messages.error(l10n.shareSaveFailed);
  });

  Future<void> _saveFiles(String path, MusicWork work) =>
      _perform('files', () async {
        final l10n = AppLocalizations.of(context);
        final saved = await ref
            .read(fileExporterProvider)
            .exportToFiles(path, '${workFileName(l10n, work)}.mp4');
        if (saved) {
          ref.read(messageControllerProvider).success(l10n.downloadSaved);
        }
      });

  Future<void> _delete(MusicVideo video) async {
    final l10n = AppLocalizations.of(context);
    final messages = ref.read(messageControllerProvider);
    final router = GoRouter.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.mvDeleteTitle),
        content: Text(l10n.mvDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _player?.pause();
    await ref.read(musicVideosProvider.notifier).delete(video);
    messages.success(l10n.mvDeleted);
    router.go(MusicWorkRoute(widget.workId).location);
  }

  void _seekFraction(double fraction, double durationSeconds) => unawaited(
    _player?.seekTo(
      Duration(milliseconds: (fraction * durationSeconds * 1000).round()),
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Immersive: the video page is dark whatever the system appearance.
    return Theme(
      data: AuraTheme.warmDark,
      child: Builder(builder: _build),
    );
  }

  Widget _build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = SongletColors.of(context);
    final work = ref.watch(workByIdProvider(widget.workId));
    final video = ref.watch(musicVideoByIdProvider(widget.videoId));
    final path = ref.watch(musicVideoPathProvider(widget.videoId)).value;
    if (work == null || video == null) {
      return Scaffold(
        backgroundColor: c.canvas,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    _bind(path);
    final player = _player;
    final value = player?.value;
    final ready = player != null && value!.isInitialized;
    final durationSeconds =
        (ready ? value.duration.inMilliseconds : video.durationMs) / 1000;
    final positionSeconds = (value?.position.inMilliseconds ?? 0) / 1000;
    final fraction = durationSeconds <= 0
        ? 0.0
        : (positionSeconds / durationSeconds).clamp(0.0, 1.0);
    final aspect = ready && value.aspectRatio > 0
        ? value.aspectRatio
        : _nominalAspect(video.aspectRatio);

    final window = mvSongWindow(work, video);
    // A lyric video has the lyrics in the picture; the panel does not repeat them.
    final lines =
        window == null ||
            work.isInstrumental ||
            video.level == MusicMvLevel.lyricVideo
        ? const <MusicTimedLine>[]
        : mvTimedLines(work, window);
    final sections = window == null
        ? const <TrackSection>[]
        : mvSections(l10n, work, window);

    final videoArea = path == null
        ? MusicTestId(
            'mv.missing',
            child: StatusView(
              title: l10n.mvMissing,
              icon: Icons.videocam_off_outlined,
              expand: false,
            ),
          )
        : Center(
            child: AspectRatio(
              aspectRatio: aspect,
              child: MusicTestId(
                'mv.player',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (ready)
                      VideoPlayer(player)
                    else
                      ColoredBox(color: c.surfaceMuted),
                    PositionedDirectional(
                      top: SongletSpace.x3,
                      start: SongletSpace.x3,
                      child: AiGeneratedBadge(
                        label: l10n.playerAiGenerated,
                        compact: true,
                      ),
                    ),
                    Center(
                      child: MusicTestId(
                        'mv.toggle',
                        child: IconCircleButton(
                          icon: (value?.isPlaying ?? false)
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          tooltip: (value?.isPlaying ?? false)
                              ? l10n.playerPause
                              : l10n.playerPlay,
                          onPressed: ready
                              ? () => value.isPlaying
                                    ? player.pause()
                                    : player.play()
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

    final panel = <Widget>[
      Text(
        workTitle(l10n, work),
        style: SongletType.title2.copyWith(color: c.ink),
      ),
      MetaLine(
        textAlign: TextAlign.start,
        parts: [
          mvLevelName(l10n, video.level),
          clockLabel(durationSeconds, l10n.localeName),
          if (video.creditsCharged > 0)
            l10n.mvPriceCredits(video.creditsCharged),
        ],
      ),
      if (ready) ...[
        const SizedBox(height: SongletSpace.x2),
        MusicTestId(
          'mv.scrubber',
          child: Row(
            children: [
              Text(
                clockLabel(positionSeconds, l10n.localeName),
                style: SongletType.caption.copyWith(color: c.inkSecondary),
              ),
              Expanded(
                child: Slider(
                  value: fraction,
                  onChanged: (f) => _seekFraction(f, durationSeconds),
                ),
              ),
              Text(
                clockLabel(durationSeconds, l10n.localeName),
                style: SongletType.caption.copyWith(color: c.inkSecondary),
              ),
            ],
          ),
        ),
      ],
      if (sections.isNotEmpty) ...[
        const SizedBox(height: SongletSpace.x2),
        MusicTestId(
          'mv.sections',
          child: SectionTrack(
            sections: sections,
            current: ready ? mvSectionAt(sections, fraction) : -1,
            onSelect: ready
                ? (i) => _seekFraction(sections[i].start, durationSeconds)
                : null,
          ),
        ),
      ],
      if (lines.isNotEmpty) ...[
        const SizedBox(height: SongletSpace.x4),
        MusicTestId(
          'mv.lyrics',
          child: SyncedLyricsView(
            lines: lyricLineViews(
              lines,
              withTimes: false,
              locale: l10n.localeName,
            ),
            active: activeLine(lines, positionSeconds),
            onTapLine: ready
                ? (i) => _seekFraction(
                    (lines[i].start ?? 0) / durationSeconds,
                    durationSeconds,
                  )
                : null,
          ),
        ),
      ],
      const SizedBox(height: SongletSpace.x3),
      MusicTestId(
        'mv.aiLabel',
        child: Row(
          children: [
            AiGeneratedBadge(label: l10n.playerAiGenerated, compact: true),
            const SizedBox(width: SongletSpace.x2),
            Flexible(
              child: Text(
                l10n.mvAiLabelBurnedIn,
                style: SongletType.footnote.copyWith(color: c.inkSecondary),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: SongletSpace.x4),
      Row(
        children: [
          for (final (id, icon, label, onTap) in [
            (
              'share',
              Icons.ios_share_rounded,
              l10n.actionShare,
              path == null ? null : () => _share(path),
            ),
            (
              'save',
              Icons.photo_library_outlined,
              l10n.mvSave,
              path == null ? null : () => _save(path),
            ),
            (
              'files',
              Icons.folder_outlined,
              l10n.mvSaveFiles,
              path == null ? null : () => _saveFiles(path, work),
            ),
            (
              'regenerate',
              Icons.autorenew_rounded,
              l10n.mvRegenerate,
              // The hub is this page's parent: go back to it, prefilled.
              () => context.goTo(
                MusicMvRoute(work.id, level: video.level, from: video.id),
              ),
            ),
          ])
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: SongletSpace.x1,
                ),
                child: MusicTestId(
                  'mv.$id',
                  child: ActionTile(
                    icon: icon,
                    label: label,
                    onPressed: _busy != null ? null : onTap,
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: SongletSpace.x4),
      Text(
        l10n.mvProvenance,
        textAlign: TextAlign.center,
        style: SongletType.footnote.copyWith(color: c.inkSecondary),
      ),
    ];

    final header = MusicPushedHeader(
      showBrand: false,
      actions: [
        MusicTestId(
          'mv.delete',
          child: IconCircleButton(
            icon: Icons.delete_outline_rounded,
            tooltip: l10n.commonDelete,
            onPressed: () => _delete(video),
          ),
        ),
      ],
    );
    final size = MediaQuery.sizeOf(context);
    final wide =
        (size.width > size.height ||
            MusicWindowClass.of(context) == MusicWindowClass.regular) &&
        !SongletType.isAccessibilitySize(context);
    final gutter = pageGutter(context);
    final panelList = ListView(
      padding: EdgeInsetsDirectional.fromSTEB(
        gutter,
        SongletSpace.x3,
        gutter,
        SongletSpace.x6,
      ),
      children: panel,
    );

    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.symmetric(
                            horizontal: gutter,
                          ),
                          child: header,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.all(
                              SongletSpace.x3,
                            ),
                            child: videoArea,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: _sidePanelWidth, child: panelList),
                ],
              )
            : SongletType.isAccessibilitySize(context)
            ? ListView(
                padding: EdgeInsetsDirectional.fromSTEB(
                  gutter,
                  SongletSpace.x2,
                  gutter,
                  SongletSpace.x6,
                ),
                children: [
                  header,
                  SizedBox(
                    height: size.height * _portraitVideoShare,
                    child: videoArea,
                  ),
                  ...panel,
                ],
              )
            : Column(
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: gutter,
                    ),
                    child: header,
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: size.height * _portraitVideoShare,
                    ),
                    child: videoArea,
                  ),
                  Expanded(child: panelList),
                ],
              ),
      ),
    );
  }

  static double _nominalAspect(MusicMvAspectRatio ratio) => switch (ratio) {
    MusicMvAspectRatio.portrait => 9 / 16,
    MusicMvAspectRatio.landscape => 16 / 9,
    MusicMvAspectRatio.square => 1,
  };
}
