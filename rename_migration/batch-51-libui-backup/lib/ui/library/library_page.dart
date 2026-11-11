import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:intl/intl.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/art.dart';
import '../common/brand.dart';
import '../common/error_retry_view.dart';
import '../common/page_layout.dart';
import '../common/test_id.dart';
import '../create/create_labels.dart';
import '../mv/mv_entry.dart';
import '../player/lyrics_model.dart';
import '../player/work_actions.dart';
import '../player/work_title.dart';
import '../routing/navigation.dart';
import '../routing/routes.dart';

/// P12 — the library (PRD F10): songs grouped by occasion, filter chips, inline
/// play, Preview / Full badges, the sync status; [occasion] set = that
/// occasion's "See all" list.
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key, this.occasion});

  final MusicOccasion? occasion;

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  /// Filter chips shown before "More".
  static const int visibleFilters = 3;

  /// Songs per section before "See all".
  static const int sectionPreview = 2;

  MusicOccasion? _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.occasion;
  }

  Future<void> _more(List<MusicOccasion> hidden) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<MusicOccasion>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final o in hidden)
              ListTile(
                leading: Icon(occasionIcon(o)),
                title: Text(
                  o == MusicOccasion.custom
                      ? l10n.libraryJustBecause
                      : occasionName(l10n, o),
                ),
                onTap: () => Navigator.pop(context, o),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _filter = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final library = ref.watch(libraryProvider);
    final grouped = ref.watch(libraryByOccasionProvider);
    final occasions = grouped.keys.toList();
    final pushed = widget.occasion != null;
    final gutter = pageGutter(context);

    final header = pushed
        ? const PushedHeader(showBrand: false)
        : BrandHeader(title: SongletBrand.name, tagline: l10n.appTagline);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: library.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ErrorRetryView(
            failure: ref.read(errorHandlerProvider).handle(error, stackTrace),
            onRetry: () => ref.invalidate(libraryProvider),
          ),
          data: (works) {
            if (works.isEmpty || occasions.isEmpty) {
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      gutter,
                      SongletSpace.x3,
                      gutter,
                      0,
                    ),
                    child: header,
                  ),
                  Expanded(
                    child: Center(
                      child: TestId(
                        'library.empty',
                        child: EmptyState(
                          icon: Icons.library_music_outlined,
                          title: l10n.libraryEmpty,
                          message: l10n.aboutSubtitle,
                          actionLabel: l10n.libraryEmptyAction,
                          onAction: () => context.goTo(const CreateRoute()),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            final filter = _filter;
            final shown = filter == null
                ? occasions
                : [if (grouped.containsKey(filter)) filter];
            final chips = [null, ...occasions];
            final visible = chips.take(visibleFilters + 1).toList();
            final hidden = occasions.skip(visibleFilters).toList();
            return ListView(
              padding: EdgeInsetsDirectional.fromSTEB(
                gutter,
                SongletSpace.x3,
                gutter,
                SongletSpace.x8,
              ),
              children: [
                header,
                const SizedBox(height: SongletSpace.x4),
                if (!pushed)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final o in visible)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              end: SongletSpace.x2,
                            ),
                            child: TestId(
                              'library.filter.${o?.wire ?? 'all'}',
                              child: PillChip(
                                label: o == null
                                    ? l10n.libraryFilterAll
                                    : _groupName(l10n, o),
                                selected: filter == o,
                                onTap: () => setState(() => _filter = o),
                              ),
                            ),
                          ),
                        if (hidden.isNotEmpty)
                          PillChip(
                            label: l10n.commonMore,
                            trailingIcon: Icons.expand_more_rounded,
                            selected: filter != null && hidden.contains(filter),
                            onTap: () => _more(hidden),
                          ),
                      ],
                    ),
                  ),
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      top: SongletSpace.x8,
                    ),
                    child: Text(
                      l10n.libraryNoMatch,
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final occasion in shown) ...[
                  const SizedBox(height: SongletSpace.x5),
                  SectionHeader(
                    title: _groupName(l10n, occasion),
                    trailing:
                        filter == null &&
                            grouped[occasion]!.length > sectionPreview
                        ? l10n.commonSeeAll
                        : null,
                    onTrailing: () =>
                        context.open(LibraryRoute(occasion: occasion)),
                  ),
                  const SizedBox(height: SongletSpace.x2),
                  SurfaceCard(
                    padding: EdgeInsetsDirectional.zero,
                    child: Column(
                      children: [
                        for (final work
                            in filter == null
                                ? grouped[occasion]!.take(sectionPreview)
                                : grouped[occasion]!)
                          _WorkTile(work: work),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  static String _groupName(AppLocalizations l10n, MusicOccasion occasion) =>
      occasion == MusicOccasion.custom
      ? l10n.libraryJustBecause
      : occasionName(l10n, occasion);
}

class _WorkTile extends ConsumerWidget {
  const _WorkTile({required this.work});

  final MusicWork work;

  Future<void> _actions(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (work.isReady) ...[
              ListTile(
                leading: const Icon(Icons.ios_share_rounded),
                title: Text(l10n.actionShare),
                onTap: () => Navigator.pop(context, 'share'),
              ),
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: Text(l10n.actionDownload),
                onTap: () => Navigator.pop(context, 'download'),
              ),
            ],
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
    if (!context.mounted) return;
    switch (choice) {
      case 'share':
        context.open(ShareRoute(work.id));
      case 'download':
        context.open(DownloadRoute(work.id));
      case 'details':
        context.open(WorkRoute(work.id));
      case 'delete':
        await WorkActions(context, ref).delete(work);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final path = ref.watch(workAudioPathProvider(work.id)).value;
    final playback = ref.watch(playerControllerProvider);
    final playing =
        path != null && playback.isCurrent(path) && playback.isPlaying;
    final title = workTitle(l10n, work);
    final status = switch (work.status) {
      MusicWorkStatus.pending => StatusPill(
        label: l10n.libraryPending,
        tone: PillTone.neutral,
      ),
      MusicWorkStatus.failed => StatusPill(
        label: l10n.libraryFailed,
        tone: PillTone.danger,
      ),
      MusicWorkStatus.ready =>
        work.isClip
            ? StatusPill(label: l10n.libraryPreviewBadge)
            : StatusPill(label: l10n.librarySongBadge, tone: PillTone.success),
    };
    // The song's video, when it has one (docs/ui P19).
    final badge = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        status,
        if (ref.watch(mvStatusOfWorkProvider(work.id)) !=
            MusicWorkVideoStatus.none) ...[
          const SizedBox(height: SongletSpace.x1),
          MvStatusChip(workId: work.id),
        ],
      ],
    );
    return TestId(
      'library.work.${work.id}',
      child: WorkRow(
        cover: CoverArt(
          seed: work.id,
          image: SongletArt.cover(work),
          radius: SongletRadius.thumb,
        ),
        title: title,
        subtitle: work.recipient,
        meta: [
          clockLabel(workDuration(work), l10n.localeName),
          DateFormat.yMMMd(l10n.localeName).format(work.createdAt.toLocal()),
        ],
        badge: badge,
        playing: playing,
        playLabel: l10n.libraryPlay(title),
        moreLabel: l10n.libraryActions(title),
        onTap: () => context.open(
          work.isReady ? playerRouteFor(work) : WorkRoute(work.id),
        ),
        onPlay: path == null
            ? null
            : () => ref.read(playerControllerProvider.notifier).toggle(path),
        onMore: () => _actions(context, ref),
      ),
    );
  }
}
