import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';
import 'cover_fallback.dart';

/// The picked card at the head of the composer (contract 02 v2.1, ADR-0033):
/// its photo, its name and a close button that drops it. Pure presentation —
/// the app owns the state and the copy.
class ComposerTag extends StatelessWidget {
  const ComposerTag({
    super.key,
    required this.label,
    required this.removeLabel,
    required this.onRemove,
    this.image,
    this.fallbackImage,
  });

  final String label;

  /// The card's photo as a thumbnail; null shows a sparkle.
  final ImageProvider? image;

  /// Drawn when [image] fails to load (the template's or occasion's photo).
  final ImageProvider? fallbackImage;

  /// Accessibility label of the close button ("Remove Soundscape").
  final String removeLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(
        container: true,
        label: label,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.accentSoft,
            borderRadius: SongletRadius.pillAll,
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: image == null ? SongletSpace.x3 : SongletSpace.x1,
              top: SongletSpace.x1,
              bottom: SongletSpace.x1,
              end: SongletSpace.x1,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: image == null
                      ? Icon(
                          Icons.auto_awesome_rounded,
                          size: SongletSize.iconSm,
                          color: c.accent,
                        )
                      : CoverFallback(
                          primary: image,
                          fallback: fallbackImage,
                          builder: (context, shown, onError) => Container(
                            width: SongletSize.iconXl,
                            height: SongletSize.iconXl,
                            decoration: BoxDecoration(
                              color: c.surfaceMuted,
                              borderRadius: SongletRadius.thumbAll,
                              image: shown == null
                                  ? null
                                  : DecorationImage(
                                      image: shown,
                                      fit: BoxFit.cover,
                                      onError: onError,
                                    ),
                            ),
                          ),
                        ),
                ),
                SizedBox(
                  width: image == null ? SongletSpace.x1 : SongletSpace.x2,
                ),
                Flexible(
                  child: ExcludeSemantics(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SongletType.subhead.copyWith(
                        color: c.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Semantics(
                  container: true,
                  button: true,
                  label: removeLabel,
                  excludeSemantics: true,
                  child: InkResponse(
                    onTap: onRemove,
                    radius: SongletSize.minTap / 2,
                    child: SizedBox.square(
                      dimension: SongletSize.iconXl,
                      child: Icon(
                        Icons.close_rounded,
                        size: SongletSize.iconSm,
                        color: c.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
