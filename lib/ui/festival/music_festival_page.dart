import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/music_ui_locale.dart';
import '../common/music_art.dart';
import '../common/music_page_layout.dart';
import '../common/music_test_id.dart';
import '../create/music_create_labels.dart';
import '../routing/music_navigation.dart';
import '../routing/music_routes.dart';

/// P16 — a festival landing (PRD §11.3: festival templates follow the
/// country): the season's hero, the eight occasions, and songs in the user's
/// language.
class MusicFestivalPage extends ConsumerWidget {
  const MusicFestivalPage({super.key, required this.festival});

  final MusicFestival festival;

  /// Grid columns on a phone; wide layouts add more.
  static const int compactColumns = 2;
  static const int regularColumns = 4;

  /// Page width cap: wider than a form column so the template grid breathes.
  static const double pageMaxWidth = SongletSize.contentMaxWidth * 1.6;

  void _start(BuildContext context, WidgetRef ref, MusicSongTemplate template) {
    final locale = ref.read(systemUiLocaleProvider);
    ref.read(creationDraftProvider.notifier)
      ..applyTemplate(
        template,
        deviceLanguage: locale.languageCode,
        deviceScript: locale.scriptCode,
      )
      ..update((d) => d.copyWith(festival: festival));
    // The create home with the tile picked and the composer unfolded
    // (ADR-0032); the festival stays on the draft.
    context.goTo(MusicCreateRoute(pick: template.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = SongletColors.of(context);
    final name = festivalName(l10n, festival);
    final language = ref.watch(creationDraftProvider).draft?.lyricLanguage;
    final columns = MusicWindowClass.of(context) == MusicWindowClass.regular
        ? regularColumns
        : compactColumns;

    return Scaffold(
      body: MusicPageFrame(
        header: const MusicPushedHeader(),
        maxWidth: pageMaxWidth,
        children: [
          MusicTestId(
            'festival.hero',
            child: FestivalHero(
              kicker: l10n.festivalKicker,
              title: name,
              subtitle: l10n.festivalComing,
              body: l10n.festivalBody,
              ctaLabel: l10n.festivalCta(name),
              art: MusicSongletArt.festival(festival),
              onCta: () => _start(context, ref, MusicSongTemplate.festival),
            ),
          ),
          const SizedBox(height: SongletSpace.x6),
          Semantics(
            header: true,
            child: Text(
              l10n.createTitle,
              style: SongletType.title1.copyWith(color: c.ink),
            ),
          ),
          Text(
            l10n.festivalPickOccasion,
            style: SongletType.callout.copyWith(color: c.inkSecondary),
          ),
          const SizedBox(height: SongletSpace.x4),
          LayoutBuilder(
            builder: (context, constraints) {
              final width =
                  (constraints.maxWidth - SongletSpace.x3 * (columns - 1)) /
                  columns;
              return Wrap(
                spacing: SongletSpace.x3,
                runSpacing: SongletSpace.x3,
                children: [
                  for (final occasion in MusicOccasion.templates)
                    SizedBox(
                      width: width,
                      child: MusicTestId(
                        'festival.occasion.${occasion.wire}',
                        child: OccasionCard(
                          image: MusicSongletArt.occasion(occasion),
                          title: occasionName(l10n, occasion),
                          hint: occasionHint(l10n, occasion),
                          onTap: () => _start(
                            context,
                            ref,
                            MusicSongTemplate.primaryFor(occasion),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: SongletSpace.x4),
          LinkCard(
            icon: Icons.language_rounded,
            title: l10n.festivalLanguagesTitle,
            subtitle: l10n.festivalLanguagesBody(
              languageName(l10n, language ?? MusicLyricLanguage.en),
            ),
            onTap: () => context.open(const MusicRegionRoute()),
          ),
        ],
      ),
    );
  }
}
