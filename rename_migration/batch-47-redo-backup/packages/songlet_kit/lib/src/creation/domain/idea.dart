import 'package:meta/meta.dart';

import 'creation_draft.dart';
import 'inspiration.dart';
import 'song_template.dart';

/// One tile of the create home's single grid (ADR-0032): an entry of the
/// server's list (`GET /v1/templates`), or — only while that list is not
/// loaded — one of the 16 built-in templates (the offline grid).
@immutable
class Idea {
  const Idea.template(SongTemplate this.template) : inspiration = null;

  const Idea.inspiration(Inspiration this.inspiration) : template = null;

  /// Set on the offline grid: art and name come from it; its id is sent as
  /// the scene slug.
  final SongTemplate? template;

  /// The server's entry: name, style, preview, cover, defaults; its slug is
  /// sent as `inspiration`.
  final Inspiration? inspiration;

  /// The id deep links name a tile by: the template id, or the entry's slug
  /// (the server names the 16 templates' entries by their template id).
  String get slug => template?.id ?? inspiration!.slug;

  /// Identity and player state: the template id, else the entry's play key.
  String get key => template?.id ?? inspiration!.playKey;

  /// Whether [draft]'s pick is this tile.
  bool isPickedIn(CreationDraft? draft) {
    if (draft == null) return false;
    final inspiration = this.inspiration;
    if (inspiration != null) return draft.inspirationSlug == inspiration.slug;
    return draft.inspirationSlug == null && draft.template == template;
  }
}

/// The grid's tiles: the server's entries in `sort` order (the 24
/// inspirations and the 16 templates are one list there); with none (not
/// loaded yet, offline, an older server) the 16 built-in templates.
List<Idea> buildIdeas(Iterable<Inspiration> inspirations) {
  final sorted = [...inspirations]..sort((a, b) {
      final bySort = a.sort.compareTo(b.sort);
      return bySort != 0 ? bySort : a.slug.compareTo(b.slug);
    });
  if (sorted.isEmpty) return [for (final template in SongTemplate.values) Idea.template(template)];
  return [for (final inspiration in sorted) Idea.inspiration(inspiration)];
}
