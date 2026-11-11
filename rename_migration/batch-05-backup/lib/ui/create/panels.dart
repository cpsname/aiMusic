import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/brand.dart';
import '../common/test_id.dart';
import '../routing/navigation.dart';
import '../routing/routes.dart';
import 'create_labels.dart';

/// P02a / P28 — Length: Short (the 30-second preview) / Standard (the full
/// song) / Premier's song + chorus video (ADR-0022). The "also make a lyric
/// video" switch lives in the composer's options, under Standard (ADR-0033).
class LengthPanel extends ConsumerWidget {
  const LengthPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(creationDraftProvider).draft;
    final model = draft?.model ?? SongModel.clip;
    final autoVideo = draft?.autoVideo ?? AutoVideo.none;
    final premier =
        ref.watch(musicEntitlementProvider).value?.tier == MusicTier.premier;
    final drafts = ref.read(creationDraftProvider.notifier);

    Future<void> pick(SongModel next, {bool chorusBundle = false}) async {
      final navigator = Navigator.of(context);
      drafts.setModel(next);
      if (chorusBundle) {
        drafts.setAutoVideo(AutoVideo.chorus);
      } else if (autoVideo == AutoVideo.chorus) {
        drafts.setAutoVideo(AutoVideo.none);
      }
      navigator.pop();
    }

    return AnchoredPanelBody(
      title: l10n.paramLength,
      children: [
        TestId(
          'panel.length.short',
          child: OptionRow(
            title: l10n.lengthShort,
            hint: l10n.lengthShortHint,
            icon: Icons.schedule_rounded,
            selected: model == SongModel.clip,
            onTap: () => pick(SongModel.clip),
          ),
        ),
        const Divider(),
        TestId(
          'panel.length.standard',
          child: OptionRow(
            title: l10n.lengthStandard,
            hint: l10n.lengthStandardHint,
            icon: Icons.schedule_rounded,
            selected:
                model == SongModel.fullSong && autoVideo != AutoVideo.chorus,
            onTap: () => pick(SongModel.fullSong),
          ),
        ),
        const Divider(),
        // Premier: the full song, then a chorus video (docs/ui P28, ADR-0022).
        TestId(
          'panel.length.songChorus',
          child: OptionRow(
            title: l10n.lengthSongAndChorus,
            hint: l10n.lengthSongAndChorusHint,
            icon: Icons.music_video_outlined,
            badge: premier
                ? null
                : StatusPill(
                    label: SongletBrand.premier,
                    tone: PillTone.neutral,
                  ),
            selected:
                model == SongModel.fullSong && autoVideo == AutoVideo.chorus,
            // Off Premier: the plans, over the panel.
            onTap: premier
                ? () => pick(SongModel.fullSong, chorusBundle: true)
                : () => unawaited(context.openPaywall(PaywallReason.upgrade)),
          ),
        ),
      ],
    );
  }
}

/// P02b — Vocals: custom / on / instrumental, with the lyric language note.
class VocalsPanel extends ConsumerWidget {
  const VocalsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(creationDraftProvider).draft;
    final vocals = draft?.vocals ?? Vocals.vocals;
    void pick(Vocals next) {
      ref.read(creationDraftProvider.notifier).setVocals(next);
      Navigator.of(context).pop();
    }

    return AnchoredPanelBody(
      title: l10n.paramVocals,
      footer: draft == null
          ? null
          : InkWell(
              onTap: () {
                Navigator.of(context).pop();
                context.open(const RegionRoute());
              },
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  vertical: SongletSpace.x2,
                ),
                child: Text(
                  l10n.vocalsLyricsIn(languageName(l10n, draft.lyricLanguage)),
                  style: SongletType.footnote.copyWith(
                    color: SongletColors.of(context).inkSecondary,
                  ),
                ),
              ),
            ),
      children: [
        for (final option in Vocals.values) ...[
          if (option != Vocals.values.first) const Divider(),
          TestId(
            'panel.vocals.${option.wire}',
            child: OptionRow(
              title: option == Vocals.custom
                  ? l10n.createVocalsCustomSummary
                  : vocalsName(l10n, option),
              subtitle: option == Vocals.custom
                  ? l10n.vocalsCustomDetail
                  : null,
              icon: vocalsIcon(option),
              selected: vocals == option,
              onTap: () => pick(option),
            ),
          ),
        ],
      ],
    );
  }
}

/// P02c — Genre: custom, the region's three ("Popular in {country}"), then
/// all 18 genres for every region (ADR-0005).
class GenrePanel extends ConsumerWidget {
  const GenrePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(creationDraftProvider).draft;
    final genre = draft?.genre;
    final region = draft?.region ?? RegionPresets.all.first;
    void pick(String? next) {
      ref.read(creationDraftProvider.notifier).setGenre(next);
      Navigator.of(context).pop();
    }

    return AnchoredPanelBody(
      title: l10n.paramGenre,
      onClose: () => Navigator.of(context).pop(),
      closeLabel: l10n.commonClose,
      children: [
        OptionRow(
          title: l10n.genreCustom,
          subtitle: l10n.genreCustomHint,
          icon: Icons.edit_note_rounded,
          selected: genre == null,
          onTap: () => pick(null),
        ),
        const Divider(),
        PanelSectionHeader(
          label: l10n.genrePopularIn(countryName(l10n, region.code)),
          onTap: () {
            Navigator.of(context).pop();
            context.open(const RegionRoute());
          },
        ),
        for (final (i, name) in region.genres.indexed)
          TestId(
            'panel.genre.popular.$i',
            child: OptionRow(
              title: genreName(l10n, name),
              icon: i == 0
                  ? Icons.equalizer_rounded
                  : Icons.music_note_outlined,
              emphasizeIcon: i == 0,
              dense: true,
              selected: genre == name,
              onTap: () => pick(name),
            ),
          ),
        const Divider(),
        PanelSectionHeader(label: l10n.genreAll),
        for (final g in Genre.values)
          TestId(
            'panel.genre.${g.name}',
            child: OptionRow(
              title: genreName(l10n, g.label),
              icon: Icons.music_note_outlined,
              dense: true,
              selected: genre == g.label,
              onTap: () => pick(g.label),
            ),
          ),
      ],
    );
  }
}
