import '../../library/domain/work.dart';
import 'creation_draft.dart';
import 'region_preset.dart';

/// Rebuilds the creation inputs stored with a [work] — for "make the full song"
/// (PRD F06) and "another version" (PRD F14). Photos are not kept on device
/// (PRD F04); their upload bids are reused (valid server-side for 24 h).
///
/// A work stores what was sent, so a description saved with a pick was the
/// card's "Your words" and is sent again ([CreationDraft.pickInputRequired]).
/// Photos only ever go with free input (ADR-0033): a work made from a pick
/// before that rule replays without them.
CreationDraft? draftFromWork(Work work) {
  final region = RegionPresets.byCode(work.region);
  if (region == null) return null;
  return CreationDraft(
    occasion: work.occasion,
    region: region,
    genre: work.hasCustomGenre ? null : work.genre,
    template: work.template,
    inspirationSlug: work.inspiration,
    pickInputRequired: (work.inspiration != null || work.template != null) &&
        work.prompt.trim().isNotEmpty,
    model: work.model,
    vocals: work.vocals,
    prompt: work.prompt,
    lyricLanguage:
        LyricLanguage.fromCode(work.lyricLanguage) ?? region.primaryLanguage,
    festival: work.festival,
    recipient: work.recipient,
    keywords: work.keywords,
    userLyrics: work.userLyrics,
    lyricsOwnershipConfirmed: work.userLyrics != null,
    imageBids: work.imageBids,
  );
}
