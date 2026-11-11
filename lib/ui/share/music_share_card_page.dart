import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:share_plus/share_plus.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/music_brand.dart';
import '../common/music_messages.dart';
import '../common/music_page_layout.dart';
import '../common/music_test_id.dart';
import '../create/music_create_labels.dart';
import '../player/music_lyrics_model.dart';
import '../player/music_work_title.dart';
import 'music_share_card_renderer.dart';

/// P10 — the 9:16 share card (PRD F08): pick a theme and a layout, then share
/// the video through the system sheet (Messages, Instagram, TikTok… appear
/// there — ADR-0010), save it to Photos, or copy the lyrics. The preview is
/// the exact widget the video frames are rendered from.
class MusicShareCardPage extends ConsumerStatefulWidget {
  const MusicShareCardPage({super.key, required this.workId});

  final String workId;

  @override
  ConsumerState<MusicShareCardPage> createState() => _ShareCardPageState();
}

enum _Busy { none, share, save }

class _ShareCardPageState extends ConsumerState<MusicShareCardPage> {
  /// Lyric lines shown on the on-screen card preview.
  static const int _previewLines = 3;

  ArtPalette _palette = ArtPalette.terracotta;
  ShareCardLayout _layout = ShareCardLayout.scene;
  _Busy _busy = _Busy.none;

  /// Composed video per look, so share and save don't compose twice.
  final Map<(ArtPalette, ShareCardLayout), String> _videos = {};

  MusicShareCardSpec _spec(AppLocalizations l10n, MusicWork work) => MusicShareCardSpec(
    brand: MusicSongletBrand.name,
    tagline: l10n.shareCardTagline,
    title: workTitle(l10n, work),
    badgeLabel: l10n.playerAiGenerated,
    bars: waveformBars(work.id),
    palette: _palette,
    layout: _layout,
  );

  Future<String> _compose(MusicWork work) async {
    final key = (_palette, _layout);
    final cached = _videos[key];
    if (cached != null) return cached;
    final l10n = AppLocalizations.of(context);
    final frames = await MusicShareCardRenderer(
      _spec(l10n, work),
    ).render(context, lyricBlocks(work.lyrics, work.structure));
    final path = await ref
        .read(shareCardServiceProvider)
        .compose(work, frames: frames, duration: workDuration(work));
    return _videos[key] = path;
  }

  Future<void> _run(
    _Busy kind,
    MusicWork work,
    Future<void> Function(String video) action,
  ) async {
    if (_busy != _Busy.none) return;
    final l10n = AppLocalizations.of(context);
    final messages = ref.read(messageControllerProvider);
    setState(() => _busy = kind);
    messages.loading(l10n.shareComposing, tag: 'share');
    try {
      final video = await _compose(work);
      messages.dismissTag('share');
      await action(video);
    } on Object catch (error, stackTrace) {
      ref
          .read(telemetrySinkProvider)
          .recordError(error, stackTrace, fatal: false);
      messages.error(l10n.shareFailed, tag: 'share');
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
    }
  }

  Future<void> _share(MusicWork work) => _run(_Busy.share, work, (video) async {
    final l10n = AppLocalizations.of(context);
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(video, mimeType: 'video/mp4')],
        text: l10n.shareText,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  });

  Future<void> _save(MusicWork work) => _run(_Busy.save, work, (video) async {
    final l10n = AppLocalizations.of(context);
    final saved = await ref.read(videoSaverProvider).saveVideo(video);
    final messages = ref.read(messageControllerProvider);
    saved
        ? messages.success(l10n.shareVideoSaved)
        : messages.error(l10n.shareSaveFailed);
  });

  Future<void> _copyLyrics(MusicWork work) async {
    final l10n = AppLocalizations.of(context);
    final text = lyricBlocks(
      work.lyrics,
      work.structure,
    ).expand((b) => [...b.lines, '']).join('\n').trim();
    await Clipboard.setData(
      ClipboardData(
        text:
            '$text\n\n${l10n.shareLyricsAttribution(l10n.playerAiGenerated, MusicSongletBrand.name)}',
      ),
    );
    ref.read(messageControllerProvider).success(l10n.shareLyricsCopied);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = SongletColors.of(context);
    final work = ref.watch(workByIdProvider(widget.workId));
    if (work == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final blocks = lyricBlocks(work.lyrics, work.structure);
    final firstLines =
        blocks
            .where((b) => b.lines.isNotEmpty)
            .map((b) => b.lines)
            .firstOrNull ??
        const <String>[];
    final spec = _spec(l10n, work);

    return Scaffold(
      body: MusicPageFrame(
        header: const MusicPushedHeader(),
        children: [
          MusicPageTitle(title: l10n.shareTitle, subtitle: l10n.shareSubtitle),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MusicTestId(
                  'share.card',
                  child: spec.card(firstLines.take(_previewLines).toList()),
                ),
              ),
              const SizedBox(width: SongletSpace.x3),
              Container(
                width: SongletSize.hairline,
                height: SongletSize.coverLarge * 2,
                color: c.hairline,
              ),
              const SizedBox(width: SongletSpace.x3),
              Column(
                children: [
                  Text(
                    l10n.shareTheme,
                    style: SongletType.callout.copyWith(color: c.ink),
                  ),
                  const SizedBox(height: SongletSpace.x2),
                  for (final palette in ArtPalette.values)
                    MusicTestId(
                      'share.theme.${palette.name}',
                      child: PaletteSwatch(
                        palette: palette,
                        label: paletteName(l10n, palette),
                        selected: palette == _palette,
                        onTap: () => setState(() => _palette = palette),
                      ),
                    ),
                  const SizedBox(height: SongletSpace.x4),
                  Text(
                    l10n.shareLayout,
                    style: SongletType.callout.copyWith(color: c.ink),
                  ),
                  const SizedBox(height: SongletSpace.x2),
                  for (final (layout, icon, label) in [
                    (
                      ShareCardLayout.scene,
                      Icons.landscape_outlined,
                      l10n.shareLayoutScene,
                    ),
                    (
                      ShareCardLayout.text,
                      Icons.notes_rounded,
                      l10n.shareLayoutText,
                    ),
                  ]) ...[
                    MusicTestId(
                      'share.layout.${layout.name}',
                      child: LayoutOptionTile(
                        icon: icon,
                        label: label,
                        selected: layout == _layout,
                        onTap: () => setState(() => _layout = layout),
                      ),
                    ),
                    const SizedBox(height: SongletSpace.x2),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: SongletSpace.x5),
          SurfaceCard(
            // Equal thirds, so long or enlarged labels wrap instead of overflowing.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MusicTestId(
                    'share.send',
                    child: ShareTargetButton(
                      icon: Icons.ios_share_rounded,
                      label: l10n.shareAction,
                      primary: true,
                      busy: _busy == _Busy.share,
                      onPressed: () => _share(work),
                    ),
                  ),
                ),
                Expanded(
                  child: MusicTestId(
                    'share.save',
                    child: ShareTargetButton(
                      icon: Icons.download_rounded,
                      label: l10n.shareSaveVideo,
                      busy: _busy == _Busy.save,
                      onPressed: () => _save(work),
                    ),
                  ),
                ),
                if (!work.isInstrumental && firstLines.isNotEmpty)
                  Expanded(
                    child: ShareTargetButton(
                      icon: Icons.copy_rounded,
                      label: l10n.shareCopyLyrics,
                      onPressed: () => _copyLyrics(work),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
