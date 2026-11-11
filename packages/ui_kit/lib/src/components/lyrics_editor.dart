import 'package:flutter/material.dart';

import '../motion.dart';
import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_motion.dart';
import '../tokens/songlet_type.dart';

/// Collapsible own-lyrics editor (docs/ui P03 "Write your own lyrics
/// (optional) 0 / 1,200"): a header row with counter and chevron; expanded,
/// a multi-line field, section-tag buttons and an [ownership] slot.
class LyricsEditor extends StatelessWidget {
  const LyricsEditor({
    super.key,
    required this.controller,
    required this.expanded,
    required this.onExpandedChanged,
    required this.title,
    required this.counter,
    required this.sectionTags,
    required this.onInsertTag,
    this.sectionTagLabels,
    this.onChanged,
    this.hint,
    this.overLimit = false,
    this.ownership,
    this.errorText,
  });

  final TextEditingController controller;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final String title;

  /// "0 / 1,200" — formatted by the caller for the locale.
  final String counter;

  /// Tag labels offered as quick inserts ("[Verse]", "[Chorus]").
  final List<String> sectionTags;

  /// Localized display labels corresponding to the unchanged insertion tokens.
  final List<String>? sectionTagLabels;
  final ValueChanged<String> onInsertTag;

  /// Every edit of the lyrics.
  final ValueChanged<String>? onChanged;
  final String? hint;
  final bool overLimit;

  /// The originality confirmation (PRD §9.1), shown when expanded.
  final Widget? ownership;
  final String? errorText;

  /// Visible line range of the lyrics field while expanded.
  static const int _minLines = 5;
  static const int _maxLines = 12;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final reduce = MotionPolicy.reduceMotion(context);
    // A Material (not a coloured box) so the ownership tile's ink shows.
    return Material(
      color: c.surfaceMuted,
      shape: RoundedRectangleBorder(
        borderRadius: SongletRadius.controlAll,
        side: errorText != null ? BorderSide(color: c.danger) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            button: true,
            expanded: expanded,
            child: InkWell(
              borderRadius: SongletRadius.controlAll,
              onTap: () => onExpandedChanged(!expanded),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: SongletSize.controlHeight,
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: SongletSpace.x4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        color: c.inkSecondary,
                        size: SongletSize.iconLg,
                      ),
                      const SizedBox(width: SongletSpace.x3),
                      Expanded(
                        child: Text(
                          title,
                          style: SongletType.callout.copyWith(
                            color: c.inkSecondary,
                          ),
                        ),
                      ),
                      Text(
                        counter,
                        style: SongletType.subhead.copyWith(
                          color: overLimit ? c.danger : c.inkSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: SongletSpace.x2),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: reduce
                            ? SongletMotion.none
                            : SongletMotion.standard,
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: c.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _Reveal(
            reduce: reduce,
            child: expanded
                ? Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      SongletSpace.x4,
                      0,
                      SongletSpace.x4,
                      SongletSpace.x4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: controller,
                          onChanged: onChanged,
                          minLines: _minLines,
                          maxLines: _maxLines,
                          keyboardType: TextInputType.multiline,
                          style: SongletType.callout.copyWith(color: c.ink),
                          decoration: InputDecoration(
                            hintText: hint,
                            fillColor: c.surface,
                            errorText: errorText,
                          ),
                        ),
                        const SizedBox(height: SongletSpace.x2),
                        Wrap(
                          spacing: SongletSpace.x2,
                          children: [
                            for (final (index, tag) in sectionTags.indexed)
                              ActionChip(
                                label: Text(sectionTagLabels?[index] ?? tag),
                                onPressed: () => onInsertTag(tag),
                                labelStyle: SongletType.footnote.copyWith(
                                  color: c.accent,
                                ),
                                backgroundColor: c.surface,
                                side: BorderSide(color: c.hairline),
                                shape: const StadiumBorder(),
                              ),
                          ],
                        ),
                        ?ownership,
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Animates the body's height; a zero-duration AnimatedSize re-dirties its
/// own layout, so reduce-motion swaps it for the bare child.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.reduce, required this.child});

  final bool reduce;
  final Widget child;

  @override
  Widget build(BuildContext context) => reduce
      ? child
      : AnimatedSize(
          duration: SongletMotion.standard,
          curve: SongletMotion.standardCurve,
          alignment: AlignmentDirectional.topStart,
          child: child,
        );
}
