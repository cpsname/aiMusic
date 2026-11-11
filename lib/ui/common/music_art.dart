import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:songlet_kit/songlet_kit.dart';

/// Bundled art (ADR-0014; files listed in assets/art_manifest.json). Pages ask
/// for art by domain value, never by path.
abstract final class MusicSongletArt {
  static const String _templates = 'assets/templates';
  static const String _occasions = 'assets/occasions';
  static const String _festivals = 'assets/festivals';
  static const String _inspirations = 'assets/inspirations';

  static ImageProvider template(MusicSongTemplate template) =>
      AssetImage('$_templates/${template.artKey}.jpg');

  /// MusicOccasion card art (docs/ui P16); the free-form occasion borrows the
  /// festival art.
  static ImageProvider occasion(MusicOccasion occasion) => AssetImage(
    '$_occasions/${occasion == MusicOccasion.custom ? MusicOccasion.festival.wire : occasion.wire}.jpg',
  );

  /// MusicFestival hero art; festivals without their own art use the festival
  /// occasion art.
  static ImageProvider festival(MusicFestival festival) =>
      festival == MusicFestival.carnival
      ? const AssetImage('$_festivals/carnival.jpg')
      : occasion(MusicOccasion.festival);

  static Future<Set<String>>? _bundledInspirations;

  /// The inspiration photos the app bundles (`assets/inspirations/<slug>.jpg`),
  /// read once from the asset manifest; empty when none or unreadable.
  static Future<Set<String>> bundledInspirationArt(AssetBundle bundle) =>
      _bundledInspirations ??= AssetManifest.loadFromAssetBundle(bundle).then(
        (manifest) => {
          for (final key in manifest.listAssets())
            if (key.startsWith('$_inspirations/')) key,
        },
        onError: (Object _) => <String>{},
      );

  /// A create-home tile's photo, best source first (ADR-0032: every tile is a
  /// photo): the server's `cover_image_url`, a template's bundled art, an
  /// entry's bundled photo (in [bundled]), else the occasion's photo.
  static ImageProvider idea(MusicIdea idea, Set<String> bundled) {
    final template = idea.template;
    if (template != null) return MusicSongletArt.template(template);
    final inspiration = idea.inspiration!;
    final url = inspiration.coverImageUrl;
    if (url != null) return NetworkImage(url);
    final linked = inspiration.linkedTemplate;
    if (linked != null) return MusicSongletArt.template(linked);
    final path = '$_inspirations/${inspiration.slug}.jpg';
    if (bundled.contains(path)) return AssetImage(path);
    return occasion(inspiration.occasion ?? MusicOccasion.custom);
  }

  /// What a `cover_image_url` that fails to load falls back to: the
  /// template's own photo, else the occasion's. Null when the tile has no
  /// server cover (nothing to fall back from).
  static ImageProvider? ideaFallback(MusicIdea idea) {
    final inspiration = idea.inspiration;
    if (inspiration?.coverImageUrl == null) return null;
    final template = inspiration!.linkedTemplate;
    if (template != null) return MusicSongletArt.template(template);
    return occasion(inspiration.occasion ?? MusicOccasion.custom);
  }

  /// Cover image of a work: its template's art; null → a generated cover.
  static ImageProvider? cover(MusicWork work) {
    final template = work.template;
    return template == null ? null : MusicSongletArt.template(template);
  }
}
