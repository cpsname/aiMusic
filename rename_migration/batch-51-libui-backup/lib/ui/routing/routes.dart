import 'package:songlet_kit/songlet_kit.dart';

/// Typed routes (ADR-0003). Every screen is reached through one of these value
/// classes — pages never build path strings — and each location is also a
/// deep link: `songlet://app<location>`.
sealed class AppRoute {
  const AppRoute();

  /// The go_router location (path + query).
  String get location;

  /// Parses a location or deep link; unknown paths resolve to [CreateRoute].
  static AppRoute parse(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final query = uri.queryParameters;
    final AppRoute? route = switch (segments) {
      [] || ['create'] => CreateRoute(
        panel: CreatePanel.fromWire(query[CreateRoute.panelParam]),
        voice: query[CreateRoute.modeParam] == CreateRoute.voiceMode,
        pick: CreateRoute.validPick(query[CreateRoute.pickParam]),
        options: query[CreateRoute.optionsParam] == CreateRoute.optionsOpen,
      ),
      // The former template form's links (ADR-0032): the create home with
      // that tile picked.
      ['create', 'template', final id] when CreateRoute.validPick(id) != null =>
        CreateRoute(pick: id),
      ['create', 'region'] => const RegionRoute(),
      ['create', 'photos'] => const PhotosRoute(),
      ['create', 'generate'] => const GenerateRoute(),
      ['create', 'festival', final id] when MusicFestival.fromWire(id) != null =>
        FestivalRoute(id),
      ['library'] => const LibraryRoute(),
      ['library', 'occasion', final o]
          when MusicOccasion.values.any((v) => v.wire == o) =>
        LibraryRoute(occasion: MusicOccasion.fromWire(o)),
      ['library', 'works', final id] => WorkRoute(id),
      ['library', 'works', final id, 'preview'] => PreviewRoute(id),
      ['library', 'works', final id, 'play'] => SongRoute(id),
      ['library', 'works', final id, 'share'] => ShareRoute(id),
      ['library', 'works', final id, 'download'] => DownloadRoute(id),
      ['library', 'works', final id, 'mv'] => MvRoute(
        id,
        level: MusicMvLevel.fromWire(query[MvRoute.levelParam]),
        from: query[MvRoute.fromParam],
      ),
      // A progress link without its video (a v1 link) opens the hub.
      ['library', 'works', final id, 'mv', 'generate'] => MvRoute(id),
      ['library', 'works', final id, 'mv', 'generate', final videoId] =>
        MvGenerateRoute(id, videoId),
      ['library', 'works', final id, 'mv', final videoId] => MvPlayerRoute(
        id,
        videoId,
      ),
      ['settings'] => const SettingsRoute(),
      ['settings', 'about'] => const AboutRoute(),
      ['paywall'] => PaywallRoute(
        reason: PaywallReason.fromWire(query[PaywallRoute.reasonParam]),
        productId: query[PaywallRoute.productParam],
        offer: MusicQuotaOffer.fromWire(query[PaywallRoute.offerParam]),
      ),
      ['unavailable'] => const UnavailableRoute(),
      _ => null,
    };
    return route ?? const CreateRoute();
  }

  /// A deep link (`songlet://app/...` or a path) → the location to open.
  static String locationFor(Uri link) => parse(link).location;
}

/// The create home's anchored panels (docs/ui P02a–c).
enum CreatePanel {
  length('length'),
  vocals('vocals'),
  genre('genre');

  const CreatePanel(this.wire);

  final String wire;

  static CreatePanel? fromWire(String? value) {
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
final class CreateRoute extends AppRoute {
  const CreateRoute({
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

  final CreatePanel? panel;
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
final class RegionRoute extends AppRoute {
  const RegionRoute();

  static const String path = 'region';

  @override
  String get location => '${CreateRoute.path}/region';
}

/// P04 photos.
final class PhotosRoute extends AppRoute {
  const PhotosRoute();

  static const String path = 'photos';

  @override
  String get location => '${CreateRoute.path}/photos';
}

/// P05 / P06 generating & queued — follows the app's one running generation.
final class GenerateRoute extends AppRoute {
  const GenerateRoute();

  static const String path = 'generate';

  @override
  String get location => '${CreateRoute.path}/generate';
}

/// P16 festival landing.
final class FestivalRoute extends AppRoute {
  const FestivalRoute(this.festivalId);

  static const String path = 'festival/:festivalId';
  static const String idParam = 'festivalId';

  final String festivalId;

  MusicFestival? get festival => MusicFestival.fromWire(festivalId);

  @override
  String get location => '${CreateRoute.path}/festival/$festivalId';
}

/// P12 library, optionally one occasion's "See all".
final class LibraryRoute extends AppRoute {
  const LibraryRoute({this.occasion});

  static const String path = '/library';
  static const String occasionPath = 'occasion/:occasion';
  static const String occasionParam = 'occasion';

  final MusicOccasion? occasion;

  @override
  String get location =>
      occasion == null ? path : '$path/occasion/${occasion!.wire}';
}

/// Base of the per-work routes.
sealed class WorkScopedRoute extends AppRoute {
  const WorkScopedRoute(this.workId);

  static const String idParam = 'workId';
  static const String basePath = 'works/:workId';

  final String workId;

  String get _base => '${LibraryRoute.path}/works/$workId';
}

/// P13 work detail.
final class WorkRoute extends WorkScopedRoute {
  const WorkRoute(super.workId);

  @override
  String get location => _base;
}

/// P07 preview (30 s clip) player.
final class PreviewRoute extends WorkScopedRoute {
  const PreviewRoute(super.workId);

  static const String path = 'preview';

  @override
  String get location => '$_base/preview';
}

/// P09 full-song player.
final class SongRoute extends WorkScopedRoute {
  const SongRoute(super.workId);

  static const String path = 'play';

  @override
  String get location => '$_base/play';
}

/// P10 share card.
final class ShareRoute extends WorkScopedRoute {
  const ShareRoute(super.workId);

  static const String path = 'share';

  @override
  String get location => '$_base/share';
}

/// P11 download & license.
final class DownloadRoute extends WorkScopedRoute {
  const DownloadRoute(super.workId);

  static const String path = 'download';

  @override
  String get location => '$_base/download';
}

/// The player for [work]: the clip player or the full-song player.
AppRoute playerRouteFor(MusicWork work) =>
    work.isClip ? PreviewRoute(work.id) : SongRoute(work.id);

/// P20/P21 music-video hub of a work (PRD ch.15, ADR-0027): pick a level,
/// see the price, make the video. [level] preselects a level; [from] is an
/// earlier video whose format, quality and chorus window prefill the hub —
/// "Make another" on a video, the retry of a failed one, and the upgrade of
/// a lyric video to a chorus video (recorded as source `upgrade`).
final class MvRoute extends WorkScopedRoute {
  const MvRoute(super.workId, {this.level, this.from});

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
      path: '${WorkRoute(workId).location}/mv',
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }
}

/// P24/P25 one video being made (progress, cancel, failure), followed by id
/// whichever path started it (ADR-0021) — also the target of its ETA
/// notification (ADR-0025).
final class MvGenerateRoute extends WorkScopedRoute {
  const MvGenerateRoute(super.workId, this.videoId);

  static const String path = 'generate/:$videoParam';
  static const String videoParam = 'videoId';

  /// Local [MusicVideo] id (= the request's `client_ref`).
  final String videoId;

  @override
  String get location => '${WorkRoute(workId).location}/mv/generate/$videoId';
}

/// P26/P27 the finished video.
final class MvPlayerRoute extends WorkScopedRoute {
  const MvPlayerRoute(super.workId, this.videoId);

  static const String path = ':$videoParam';
  static const String videoParam = 'videoId';

  /// Local [MusicVideo] id.
  final String videoId;

  @override
  String get location => '${WorkRoute(workId).location}/mv/$videoId';
}

/// P14 settings.
final class SettingsRoute extends AppRoute {
  const SettingsRoute();

  static const String path = '/settings';

  @override
  String get location => path;
}

/// P15 about generation.
final class AboutRoute extends AppRoute {
  const AboutRoute();

  static const String path = 'about';

  @override
  String get location => '${SettingsRoute.path}/about';
}

/// Why the paywall opened (copy + analytics-free context, PRD §8.2).
enum PaywallReason {
  fullSong('full_song'),
  quota('quota'),
  download('download'),
  wav('wav'),
  upgrade('upgrade'),

  /// Not enough credits for a music video: the paywall preselects the
  /// recommended pack (PRD ch.15, ADR-0020).
  mv('mv');

  const PaywallReason(this.wire);

  final String wire;

  static PaywallReason fromWire(String? value) =>
      values.firstWhere((r) => r.wire == value, orElse: () => upgrade);
}

/// P08 paywall (full-screen dialog over everything). [productId] preselects
/// a product — the pack a `QUOTA_EXHAUSTED` recommended; [offer] picks which
/// side leads (contract 02 v2.1): plans (the default) or credit packs.
final class PaywallRoute extends AppRoute {
  const PaywallRoute({
    this.reason = PaywallReason.upgrade,
    this.productId,
    this.offer,
  });

  static const String path = '/paywall';
  static const String reasonParam = 'reason';
  static const String productParam = 'product';
  static const String offerParam = 'offer';

  final PaywallReason reason;
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
final class UnavailableRoute extends AppRoute {
  const UnavailableRoute();

  static const String path = '/unavailable';

  @override
  String get location => path;
}
