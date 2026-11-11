import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infra_core/infra_core.dart';
import 'package:songlet_kit/songlet_kit.dart';
import 'package:ui_kit/ui_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/ui_locale.dart';
import '../common/art.dart';
import '../common/brand.dart';
import '../common/failure_copy.dart';
import '../common/messages.dart';
import '../common/page_layout.dart';
import '../common/test_id.dart';
import '../routing/navigation.dart';
import '../routing/routes.dart';
import 'composer_budget.dart';
import 'composer_section.dart';
import 'idea_grid_layout.dart';
import 'inspiration_labels.dart';

/// P01 — the create home (ADR-0032): one grid of photo tiles (the server's
/// list by `sort`; the 16 built-in templates while it is not loaded) and the
/// composer. A tile is a single pick held by the draft: tapping picks it and
/// the composer unfolds its fields in place; tapping it again folds back to
/// free input. The composer's send button is the only way to start a song.
/// Compact: grid above the composer; regular (iPad): side by side.
class CreateHomePage extends ConsumerStatefulWidget {
  const CreateHomePage({
    super.key,
    this.panel,
    this.voice = false,
    this.pick,
    this.options = false,
  });

  final CreatePanel? panel;
  final bool voice;

  /// The composer's options are unfolded (state C, ADR-0033).
  final bool options;

  /// A tile to pick on arrival (`/create?template=<id>`, also reached as
  /// `/create/template/<id>`): picked, scrolled into view, composer unfolded.
  final String? pick;

  @override
  ConsumerState<CreateHomePage> createState() => _CreateHomePageState();
}

class _CreateHomePageState extends ConsumerState<CreateHomePage> {
  /// Width of the composer pane beside the template grid on wide layouts.
  static const double _composerPaneWidth =
      SongletSize.leadingPaneMaxWidth * 0.8;

  /// The composer's padding above and below it on a phone.
  static const double _composerInset = SongletSpace.x3;

  final _gridScroll = ScrollController();
  final _tileKeys = <String, GlobalKey>{};
  final _grid = _GridMetrics();

  /// A deep-linked tile the list has not delivered yet.
  String? _pendingPick;

  /// A deep-linked tile to keep in view until the server list has landed
  /// (the grid changes under it once).
  String? _revealSlug;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final locale = ref.read(systemUiLocaleProvider);
      ref
          .read(creationDraftProvider.notifier)
          .ensureStarted(
            deviceLanguage: locale.languageCode,
            deviceScript: locale.scriptCode,
          );
      if (widget.pick != null) _arrive(widget.pick!);
    });
  }

  @override
  void didUpdateWidget(CreateHomePage old) {
    super.didUpdateWidget(old);
    final pick = widget.pick;
    if (pick != null && pick != old.pick) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _arrive(pick);
      });
    }
  }

  @override
  void dispose() {
    _gridScroll.dispose();
    super.dispose();
  }

  GlobalKey _tileKey(String slug) => _tileKeys.putIfAbsent(slug, GlobalKey.new);

  /// A deep link: pick the tile, keep it in view, and drop the parameter so
  /// coming back to the tab does not pick it again.
  void _arrive(String pick) {
    if (pick == CreateRoute.custom) {
      _pendingPick = null;
      if (ref.read(creationDraftProvider).draft?.hasPick ?? false) {
        ref.read(creationDraftProvider.notifier).clearPick();
      }
    } else {
      _pendingPick = pick;
      _revealSlug = pick;
      _resolvePending();
    }
    context.goTo(
      CreateRoute(
        panel: widget.panel,
        voice: widget.voice,
        options: widget.options,
      ),
    );
  }

  /// Picks [_pendingPick] once the grid has it. A built-in template id picks
  /// the template straight away; the server's entry replaces it when the
  /// list lands (see [_adoptList]).
  void _resolvePending() {
    final pick = _pendingPick;
    if (pick == null) return;
    final ideas = ref.read(ideasProvider);
    final idea = ideas.where((i) => i.slug == pick).firstOrNull;
    if (idea != null) {
      if (!idea.isPickedIn(ref.read(creationDraftProvider).draft)) {
        _pickIdea(idea);
      }
      if (idea.inspiration != null) _pendingPick = null;
    } else if (MusicSongTemplate.fromId(pick) case final template?) {
      final draft = ref.read(creationDraftProvider).draft;
      if (draft?.template != template || draft?.inspirationSlug != null) {
        _pickIdea(MusicIdea.template(template));
      }
    }
    _reveal();
  }

  /// The server list replaced the offline grid: a built-in template picked
  /// there becomes the server's entry for it (same slug).
  void _adoptList(List<MusicIdea> ideas) {
    final draft = ref.read(creationDraftProvider).draft;
    final template = draft?.template;
    if (draft != null && template != null && draft.inspirationSlug == null) {
      final entry = ideas
          .where((i) => i.inspiration?.slug == template.id)
          .firstOrNull;
      if (entry != null) _pickIdea(entry);
    }
    _resolvePending();
    if (ideas.any((i) => i.inspiration != null)) {
      _reveal();
      _revealSlug = null;
    }
  }

  /// Scrolls the deep-linked tile into view: near its row first (the grid
  /// builds lazily), then exactly once it is built.
  void _reveal() {
    final slug = _revealSlug;
    if (slug == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tile = _tileKeys[slug]?.currentContext;
      if (tile != null) {
        Scrollable.ensureVisible(tile, alignment: 0.5, duration: _motion);
        return;
      }
      final index = ref.read(ideasProvider).indexWhere((i) => i.slug == slug);
      if (index < 0 || !_gridScroll.hasClients) return;
      final position = _gridScroll.position;
      _gridScroll.jumpTo(
        (_grid.layout?.offsetOf(index) ?? 0).clamp(0, position.maxScrollExtent),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final built = _tileKeys[slug]?.currentContext;
        if (mounted && built != null) {
          Scrollable.ensureVisible(built, alignment: 0.5);
        }
      });
    });
  }

  Duration get _motion => MotionPolicy.reduceMotion(context)
      ? SongletMotion.none
      : SongletMotion.standard;

  /// Tapping a tile: pick it, or unpick it when it is the pick. The preview
  /// keeps playing either way.
  void _toggle(MusicIdea idea) {
    _pendingPick = null;
    _revealSlug = null;
    if (idea.isPickedIn(ref.read(creationDraftProvider).draft)) {
      ref.read(creationDraftProvider.notifier).clearPick();
      return;
    }
    _pickIdea(idea);
  }

  /// Makes [idea] the draft's pick and applies its defaults; the prompt field
  /// keeps the user's words (the card's hint is its placeholder).
  void _pickIdea(MusicIdea idea) {
    final locale = ref.read(systemUiLocaleProvider);
    final drafts = ref.read(creationDraftProvider.notifier);
    final inspiration = idea.inspiration;
    if (inspiration != null) {
      drafts.applyInspiration(
        inspiration,
        deviceLanguage: locale.languageCode,
        deviceScript: locale.scriptCode,
      );
    } else {
      drafts.applyTemplate(
        idea.template!,
        deviceLanguage: locale.languageCode,
        deviceScript: locale.scriptCode,
      );
    }
    final draft = drafts.draft;
    if (draft != null &&
        draft.occasion == MusicOccasion.festival &&
        draft.festival == null) {
      drafts.update(
        (d) => d.copyWith(festival: _seasonFestival(d.region.code)),
      );
    }
  }

  /// The season's festival for [region]: its own first, universal ones (New
  /// Year) after (PRD §11.3).
  MusicFestival _seasonFestival(String region) {
    final festivals =
        MusicFestival.available(
          region: region,
          languageCode: ref.read(systemUiLocaleProvider).languageCode,
        )..sort(
          (a, b) =>
              (a.regions.isEmpty ? 1 : 0).compareTo(b.regions.isEmpty ? 1 : 0),
        );
    return festivals.isEmpty ? MusicFestival.newYear : festivals.first;
  }

  /// A preview that cannot play, worded by what failed: the connectivity
  /// copy only for a transport failure — a server answer (a clip missing
  /// from storage is a 404) is not a connection problem.
  void _previewFailed(Object error, StackTrace stackTrace) {
    final failure = ref.read(errorHandlerProvider).handle(error, stackTrace);
    ref
        .read(messageControllerProvider)
        .error(failureMessageText(AppLocalizations.of(context), failure));
  }

  /// The play button: the preview only, never the pick.
  Future<void> _playIdea(MusicIdea idea) async {
    try {
      await ref.read(templateSampleProvider.notifier).toggleIdea(idea);
    } on Object catch (error, stackTrace) {
      if (!mounted) return;
      _previewFailed(error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen(ideasProvider, (_, next) => _adoptList(next));
    // Accessibility Dynamic Type sizes use one scrolling column at any width
    // (ADR-0018, ADR-0034): the composer first, the grid under it.
    final accessible = SongletType.isAccessibilitySize(context);
    final regular =
        WindowClass.of(context) == WindowClass.regular && !accessible;
    final gutter = WindowClass.of(context) == WindowClass.regular
        ? pageGutter(context)
        : SongletSpace.gutterDense;
    final header = BrandHeader(
      title: SongletBrand.name,
      tagline: l10n.appTagline,
    );
    final composer = ComposerSection(
      panel: widget.panel,
      voice: widget.voice,
      options: widget.options,
      wide: regular,
    );
    _IdeaGrid grid({bool embedded = false}) => _IdeaGrid(
      onTap: _toggle,
      onPlay: _playIdea,
      tileKey: _tileKey,
      metrics: _grid,
      controller: embedded ? null : _gridScroll,
      embedded: embedded,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: regular
            ? _wide(
                header: header,
                grid: grid(),
                composer: composer,
                gutter: gutter,
              )
            : accessible
            ? ListView(
                padding: EdgeInsetsDirectional.fromSTEB(
                  gutter,
                  SongletSpace.x3,
                  gutter,
                  SongletSpace.x6,
                ),
                children: [
                  header,
                  const SizedBox(height: SongletSpace.x3),
                  composer,
                  const SizedBox(height: SongletSpace.x4),
                  grid(embedded: true),
                ],
              )
            : _stacked(
                header: header,
                grid: grid(),
                composer: composer,
                gutter: gutter,
              ),
      ),
    );
  }

  /// iPad (ADR-0034): the grid on the leading side, the composer in its own
  /// pane — the picked card's head at its top and the primary action at its
  /// bottom stay put while its fields scroll. Nothing overlaps the grid.
  Widget _wide({
    required Widget header,
    required Widget grid,
    required Widget composer,
    required double gutter,
  }) => Padding(
    padding: EdgeInsetsDirectional.symmetric(horizontal: gutter),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: SongletSpace.x4,
          ),
          child: header,
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: grid),
              const SizedBox(width: SongletSpace.x6),
              SizedBox(
                width: _composerPaneWidth,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: SongletSpace.x4,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.topCenter,
                    child: composer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  /// Phones (ADR-0034): the grid above, the composer pinned under it within
  /// its share of the screen ([ComposerBudget]) — the grid always shows its
  /// heading and a full row of tiles. The shell keeps the page above the
  /// keyboard, so the composer rides up with it; then the brand header steps
  /// aside, and with a picked card or the options the grid folds away.
  Widget _stacked({
    required Widget header,
    required Widget grid,
    required Widget composer,
    required double gutter,
  }) {
    final draft = ref.watch(creationDraftProvider).draft;
    final picked = draft?.hasPick ?? false;
    final unfolded = widget.options || widget.panel != null || widget.voice;
    final names = [
      for (final idea in ref.watch(ideasProvider)) ideaName(context, idea),
      ...knownInspirationNames(context),
    ];
    final reduce = MotionPolicy.reduceMotion(context);
    // The shell's Scaffold resizes for the keyboard and hides it from this
    // page's media query; the view still reports it. Read here, where the
    // resize rebuilds.
    return LayoutBuilder(
      builder: (context, _) {
        final keyboard =
            MediaQueryData.fromView(View.of(context)).viewInsets.bottom > 0;
        final showHeader = ComposerBudget.showsHeader(keyboard: keyboard);
        final headerSlot = showHeader
            ? Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  gutter,
                  SongletSpace.x3,
                  gutter,
                  SongletSpace.x3,
                ),
                child: header,
              )
            : const SizedBox(width: double.infinity);
        return Column(
          children: [
            if (reduce)
              headerSlot
            else
              AnimatedSize(
                duration: SongletMotion.state,
                curve: SongletMotion.emphasizedCurve,
                alignment: AlignmentDirectional.topCenter,
                child: headerSlot,
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, room) {
                  final layout = IdeaGridLayout.of(
                    context,
                    width: room.maxWidth - 2 * gutter,
                    names: names,
                  );
                  final budget = ComposerBudget.resolve(
                    screenHeight: MediaQuery.sizeOf(context).height,
                    roomHeight: room.maxHeight - 2 * _composerInset,
                    gridMinExtent: layout.minExtent,
                    picked: picked,
                    unfolded: unfolded,
                    keyboard: keyboard,
                  );
                  return Column(
                    children: [
                      if (budget.gridCollapsed)
                        const Spacer()
                      else
                        Expanded(
                          child: Padding(
                            padding: EdgeInsetsDirectional.symmetric(
                              horizontal: gutter,
                            ),
                            child: grid,
                          ),
                        ),
                      Padding(
                        padding: EdgeInsetsDirectional.symmetric(
                          horizontal: gutter,
                          vertical: _composerInset,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: budget.maxHeight,
                          ),
                          child: composer,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Where the grid's rows sit, recorded on layout so a deep link can scroll to
/// a tile the lazy grid has not built yet.
class _GridMetrics {
  IdeaGridLayout? layout;
}

class _IdeaGrid extends ConsumerWidget {
  const _IdeaGrid({
    required this.onTap,
    required this.onPlay,
    required this.tileKey,
    required this.metrics,
    this.controller,
    this.embedded = false,
  });

  /// Picks or unpicks the tile.
  final ValueChanged<MusicIdea> onTap;

  /// Plays or pauses its preview.
  final ValueChanged<MusicIdea> onPlay;
  final GlobalKey Function(String slug) tileKey;
  final _GridMetrics metrics;
  final ScrollController? controller;

  /// Laid out at full height inside an outer scroll view instead of
  /// scrolling itself.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ideas = ref.watch(ideasProvider);
    final playing = ref.watch(templateSampleProvider);
    final draft = ref.watch(creationDraftProvider).draft;
    final names = [for (final idea in ideas) ideaName(context, idea)];
    // Room is reserved for every name the app knows, loaded or not, so the
    // columns never reflow when the inspirations arrive.
    final measured = [...names, ...knownInspirationNames(context)];
    return FutureBuilder<Set<String>>(
      future: SongletArt.bundledInspirationArt(DefaultAssetBundle.of(context)),
      initialData: const <String>{},
      builder: (context, art) => LayoutBuilder(
        builder: (context, constraints) {
          final bundled = art.data ?? const <String>{};
          final layout = IdeaGridLayout.of(
            context,
            width: constraints.maxWidth,
            names: measured,
          );
          metrics.layout = layout;

          return CustomScrollView(
            controller: controller,
            shrinkWrap: embedded,
            physics: embedded ? const NeverScrollableScrollPhysics() : null,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: SongletSpace.x2,
                  ),
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.inspirationHeader,
                      style: SongletType.headline.copyWith(
                        color: SongletColors.of(context).ink,
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsetsDirectional.only(
                  bottom: SongletSpace.x2,
                ),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: layout.columns,
                    mainAxisSpacing: SongletSpace.x2,
                    crossAxisSpacing: SongletSpace.x2,
                    childAspectRatio: layout.aspect,
                  ),
                  itemCount: ideas.length,
                  itemBuilder: (context, i) {
                    final idea = ideas[i];
                    final name = names[i];
                    final isPlaying = playing == idea.key;
                    return KeyedSubtree(
                      key: tileKey(idea.slug),
                      child: TestId(
                        'tile.${idea.slug}',
                        child: TemplateTile(
                          title: name,
                          description: ideaStyle(context, idea),
                          image: SongletArt.idea(idea, bundled),
                          fallbackImage: SongletArt.ideaFallback(idea),
                          selected: idea.isPickedIn(draft),
                          playing: isPlaying,
                          playLabel: isPlaying
                              ? l10n.templatePauseSample
                              : l10n.templatePlaySample(name),
                          onTap: () => onTap(idea),
                          onPlay: () => onPlay(idea),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
