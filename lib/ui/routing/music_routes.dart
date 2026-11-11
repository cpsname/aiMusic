import 'package:songlet_kit/songlet_kit.dart';

/// Typed routes (ADR-0003). Every screen is reached through one of these value
/// classes — pages never build path strings — and each location is also a
/// deep link: `songlet://app<location>`.
sealed class MusicAppRoute {
  const MusicAppRoute();

  /// The go_router location (path + query).
  String get location;

  /// Parses a location or deep link; unknown paths resolve to [MusicCreateRoute].
  static MusicAppRoute parse(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final query = uri.queryParameters;
    final MusicAppRoute? route = switch (segments) {
      [] || ['create'] => MusicCreateRoute(
        panel: MusicCreatePanel.fromWire(query[MusicCreateRoute.panelParam]),
        voice: query[MusicCreateRoute.modeParam] == MusicCreateRoute.voiceMode,
        pick: MusicCreateRoute.validPick(query[MusicCreateRoute.pickParam]),
        options: query[MusicCreateRoute.optionsParam] == MusicCreateRoute.optionsOpen,
      ),
      // The former template form's links (ADR-0032): the create home with
      // that tile picked.
      ['create', 'template', final id] when MusicCreateRoute.validPick(id) != null =>
        MusicCreateRoute(pick: id),
      ['create', 'region'] => const MusicRegionRoute(),
      ['create', 'photos'] => const MusicPhotosRoute(),
      ['create', 'generate'] => const MusicGenerateRoute(),
      ['create', 'festival', final id] when MusicFestival.fromWire(id) != null =>
        MusicFestivalRoute(id),
      ['library'] => const MusicLibraryRoute(),
      ['library', 'occasion', final o]
          when MusicOccasion.values.any((v) => v.wire == o) =>
        MusicLibraryRoute(occasion: MusicOccasion.fromWire(o)),
      ['library', 'works', final id] => MusicWorkRoute(id),
      ['library', 'works', final id, 'preview'] => MusicPreviewRoute(id),
      ['library', 'works', final id, 'play'] => MusicSongRoute(id),
      ['library', 'works', final id, 'share'] => MusicShareRoute(id),
      ['library', 'works', final id, 'download'] => MusicDownloadRoute(id),
      ['library', 'works', final id, 'mv'] => MusicMvRoute(
        id,
        level: MusicMvLevel.fromWire(query[MusicMvRoute.levelParam]),
        from: query[MusicMvRoute.fromParam],
      ),
      // A progress link without its video (a v1 link) opens the hub.
      ['library', 'works', final id, 'mv', 'generate'] => MusicMvRoute(id),
      ['library', 'works', final id, 'mv', 'generate', final videoId] =>
        MusicMvGenerateRoute(id, videoId),
      ['library', 'works', final id, 'mv', final videoId] => MusicMvPlayerRoute(
        id,
        videoId,
      ),
      ['settings'] => const MusicSettingsRoute(),
      ['settings', 'about'] => const MusicAboutRoute(),
      ['paywall'] => MusicPaywallRoute(
        reason: MusicPaywallReason.fromWire(query[MusicPaywallRoute.reasonParam]),
        productId: query[MusicPaywallRoute.productParam],
        offer: MusicQuotaOffer.fromWire(query[MusicPaywallRoute.offerParam]),
      ),
      ['unavailable'] => const MusicUnavailableRoute(),
      _ => null,
    };
    return route ?? const MusicCreateRoute();
  }

  /// A deep link (`songlet://app/...` or a path) → the location to open.
  static String locationFor(Uri link) => parse(link).location;
}

/// The create home's anchored panels (docs/ui P02a–c).
enum MusicCreatePanel {
  length('length'),
  vocals('vocals'),
  genre('genre');

  const MusicCreatePanel(this.wire);

  final String wire;

  static MusicCreatePanel? fromWire(String? value) {
    for (final panel in values) {
      if (panel.wire == value) return panel;
    }
    return null;
  }
}

/// P01 create home, optionally with the composer's options unfolded
/// ([options], ADR-0033), a panel open (P02a–c), dictating (P03a), or with a
/// tile to pick ([pick], ADR-0032): a template id or an entry's slug — picked,
/// scrolled into view, its fields in the composer — or [custom] for free
/// input. `/create/template/<id>` (the former form) resolves here.
final class MusicCreateRoute extends MusicAppRoute {
  const MusicCreateRoute({
    this.panel,
    this.voice = false,
    this.pick,
    this.options = false,
  });

  static const String path = '/create';
  static const String panelParam = 'panel';
  static const String modeParam = 'mode';
  static const String pickParam = 'template';
  static const String optionsParam = 'options';
  static const String voiceMode = 'voice';
  static const String optionsOpen = '1';

  /// [pick] for "nothing picked": free input.
  static const String custom = 'custom';

  final MusicCreatePanel? panel;
  final bool voice;
  final String? pick;

  /// The composer's options are unfolded (state C, ADR-0033): the Length /
  /// MusicVocals / MusicGenre selectors, own lyrics and the video switch.
  final bool options;

  /// Whether the options show: asked for, or a panel is open (its selector
  /// is the panel's anchor).
  bool get optionsShown => options || panel != null;

  /// [value] when it can name a tile (`custom`, or a slug: the server's list
  /// is data-driven, so any well-formed slug), else null.
  static String? validPick(String? value) =>
      value != null && RegExp(r'^[a-z0-9]+(_[a-z0-9]+)*$').hasMatch(value)
      ? value
      : null;

  @override
  String get location {
    final query = {
      if (panel != null) panelParam: panel!.wire,
      if (voice) modeParam: voiceMode,
      pickParam: ?pick,
      if (options) optionsParam: optionsOpen,
    };
    return Uri(
      path: path,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }
}

/// P02 region sheet.
final class MusicRegionRoute extends MusicAppRoute {
  const MusicRegionRoute();

  static const String path = 'region';

  @override
  String get location => '${MusicCreateRoute.path}/region';
}

/// P04 photos.
final class MusicPhotosRoute extends MusicAppRoute {
  const MusicPhotosRoute();

  static const String path = 'photos';

  @override
  String get location => '${MusicCreateRoute.path}/photos';
}

/// P05 / P06 generating & queued — follows the app's one running generation.
final class MusicGenerateRoute extends MusicAppRoute {
  const MusicGenerateRoute();

  static const String path = 'generate';

  @override
  String get location => '${MusicCreateRoute.path}/generate';
}

/// P16 festival landing.
final class MusicFestivalRoute extends MusicAppRoute {
  const MusicFestivalRoute(this.festivalId);

  static const String path = 'festival/:festivalId';
  static const String idParam = 'festivalId';

  final String festivalId;

  MusicFestival? get festival => MusicFestival.fromWire(festivalId);

  @override
  String get location => '${MusicCreateRoute.path}/festival/$festivalId';
}

/// P12 library, optionally one occasion's "See all".
final class MusicLibraryRoute extends MusicAppRoute {
  const MusicLibraryRoute({this.occasion});

  static const String path = '/library';
  static const String occasionPath = 'occasion/:occasion';
  static const String occasionParam = 'occasion';

  final MusicOccasion? occasion;

  @override
  String get location =>
      occasion == null ? path : '$path/occasion/${occasion!.wire}';
}

/// Base of the per-work routes.
sealed class MusicWorkScopedRoute extends MusicAppRoute {
  const MusicWorkScopedRoute(this.workId);

  static const String idParam = 'workId';
  static const String basePath = 'works/:workId';

  final String workId;

  String get _base => '${MusicLibraryRoute.path}/works/$workId';
}

/// P13 work detail.
final class MusicWorkRoute extends MusicWorkScopedRoute {
  const MusicWorkRoute(super.workId);

  @override
  String get location => _base;
}

/// P07 preview (30 s clip) player.
final class MusicPreviewRoute extends MusicWorkScopedRoute {
  const MusicPreviewRoute(super.workId);

  static const String path = 'preview';

  @override
  String get location => '$_base/preview';
}

/// P09 full-song player.
final class MusicSongRoute extends MusicWorkScopedRoute {
  const MusicSongRoute(super.workId);

  static const String path = 'play';

  @override
  String get location => '$_base/play';
}

/// P10 share card.
final class MusicShareRoute extends MusicWorkScopedRoute {
  const MusicShareRoute(super.workId);

  static const String path = 'share';

  @override
  String get location => '$_base/share';
}

/// P11 download & license.
final class MusicDownloadRoute extends MusicWorkScopedRoute {
  const MusicDownloadRoute(super.workId);

  static const String path = 'download';

  @override
  String get location => '$_base/download';
}

/// The player for [work]: the clip player or the full-song player.
MusicAppRoute playerRouteFor(MusicWork work) =>
    work.isClip ? MusicPreviewRoute(work.id) : MusicSongRoute(work.id);

/// P20/P21 music-video hub of a work (PRD ch.15, ADR-0027): pick a level,
/// see the price, make the video. [level] preselects a level; [from] is an
/// earlier video whose format, quality and chorus window prefill the hub —
/// "Make another" on a video, the retry of a failed one, and the upgrade of
/// a lyric video to a chorus video (recorded as source `upgrade`).
final class MusicMvRoute extends MusicWorkScopedRoute {
  const MusicMvRoute(super.workId, {this.level, this.from});

  static const String path = 'mv';
  static const String levelParam = 'level';
  static const String fromParam = 'from';

  final MusicMvLevel? level;

  /// Local [MusicVideo] id.
  final String? from;

  @override
  String get location {
    final query = {
      if (level != null) levelParam: level!.wire,
      if (from != null && from!.isNotEmpty) fromParam: from!,
    };
    return Uri(
      path: '${MusicWorkRoute(workId).location}/mv',
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }
}

/// P24/P25 one video being made (progress, cancel, failure), followed by id
/// whichever path started it (ADR-0021) — also the target of its ETA
/// notification (ADR-0025).
final class MusicMvGenerateRoute extends MusicWorkScopedRoute {
  const MusicMvGenerateRoute(super.workId, this.videoId);

  static const String path = 'generate/:$videoParam';
  static const String videoParam = 'videoId';

  /// Local [MusicVideo] id (= the request's `client_ref`).
  final String videoId;

  @override
  String get location => '${MusicWorkRoute(workId).location}/mv/generate/$videoId';
}

/// P26/P27 the finished video.
final class MusicMvPlayerRoute extends MusicWorkScopedRoute {
  const MusicMvPlayerRoute(super.workId, this.videoId);

  static const String path = ':$videoParam';
  static const String videoParam = 'videoId';

  /// Local [MusicVideo] id.
  final String videoId;

  @override
  String get location => '${MusicWorkRoute(workId).location}/mv/$videoId';
}

/// P14 settings.
final class MusicSettingsRoute extends MusicAppRoute {
  const MusicSettingsRoute();

  static const String path = '/settings';

  @override
  String get location => path;
}

/// P15 about generation.
final class MusicAboutRoute extends MusicAppRoute {
  const MusicAboutRoute();

  static const String path = 'about';

  @override
  String get location => '${MusicSettingsRoute.path}/about';
}

/// Why the paywall opened (copy + analytics-free context, PRD §8.2).
enum MusicPaywallReason {
  fullSong('full_song'),
  quota('quota'),
  download('download'),
  wav('wav'),
  upgrade('upgrade'),

  /// Not enough credits for a music video: the paywall preselects the
  /// recommended pack (PRD ch.15, ADR-0020).
  mv('mv');

  const MusicPaywallReason(this.wire);

  final String wire;

  static MusicPaywallReason fromWire(String? value) =>
      values.firstWhere((r) => r.wire == value, orElse: () => upgrade);
}

/// P08 paywall (full-screen dialog over everything). [productId] preselects
/// a product — the pack a `QUOTA_EXHAUSTED` recommended; [offer] picks which
/// side leads (contract 02 v2.1): plans (the default) or credit packs.
final class MusicPaywallRoute extends MusicAppRoute {
  const MusicPaywallRoute({
    this.reason = MusicPaywallReason.upgrade,
    this.productId,
    this.offer,
  });

  static const String path = '/paywall';
  static const String reasonParam = 'reason';
  static const String productParam = 'product';
  static const String offerParam = 'offer';

  final MusicPaywallReason reason;
  final String? productId;
  final MusicQuotaOffer? offer;

  @override
  String get location => Uri(
    path: path,
    queryParameters: {
      reasonParam: reason.wire,
      if (productId != null && productId!.isNotEmpty) productParam: productId!,
      if (offer != null) offerParam: offer!.wire,
    },
  ).toString();
}

/// P17 temporarily unavailable.
final class MusicUnavailableRoute extends MusicAppRoute {
  const MusicUnavailableRoute();

  static const String path = '/unavailable';

  @override
  String get location => path;
}
