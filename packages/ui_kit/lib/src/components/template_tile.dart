import 'package:flutter/material.dart';

import '../motion.dart';
import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_motion.dart';
import '../tokens/songlet_type.dart';
import 'cover_fallback.dart';

/// A plate on the create home's contact sheet (docs/ui P01, ADR-0032).
///
/// Printed like an index print: the photograph in a ruled frame, its name
/// lettered on the paper margin underneath — never a caption laid over the
/// picture. The sample button is a small cream disc in the picture's corner.
/// A [selected] plate takes the coral frame and its margin turns to coral:
/// the pick is legible from across the room, and it is the same plate the
/// composer unfolds, not a second card.
class TemplateTile extends StatelessWidget {
  const TemplateTile({
    super.key,
    required this.title,
    required this.onTap,
    this.image,
    this.fallbackImage,
    this.description,
    this.onPlay,
    this.playing = false,
    this.playLabel = '',
    this.selected = false,
  });

  final String title;
  final ImageProvider? image;

  /// Shown instead of [image] once it has failed to load.
  final ImageProvider? fallbackImage;

  /// One more line for assistive technology ("Ambient textures, no vocals").
  final String? description;
  final VoidCallback onTap;

  /// Plays the template's sample; null hides the button.
  final VoidCallback? onPlay;
  final bool playing;

  /// Accessibility label of the play button.
  final String playLabel;

  /// The composer's pick: coral frame and coral margin.
  final bool selected;

  /// Scale of a [selected] plate — a hair inward, the way a print sits when
  /// it is lifted off the sheet.
  static const double selectedScale = 0.97;

  /// Height of the printed margin under the picture.
  static const double captionHeight = 28;

  @override
  Widget build(BuildContext context) =>
      CoverFallback(primary: image, fallback: fallbackImage, builder: _tile);

  Widget _tile(
    BuildContext context,
    ImageProvider? image,
    ImageErrorListener onImageError,
  ) {
    final c = SongletColors.of(context);
    final motion = MotionPolicy.reduceMotion(context)
        ? SongletMotion.none
        : SongletMotion.fast;
    final frame = selected ? c.accent : c.hairline;
    return AspectRatio(
      aspectRatio: SongletSize.tileAspect,
      child: AnimatedScale(
        scale: selected ? selectedScale : 1,
        duration: motion,
        curve: SongletMotion.emphasizedCurve,
        child: Semantics(
          container: true,
          button: true,
          selected: selected,
          label: description == null ? title : '$title, $description',
          child: AnimatedContainer(
            duration: motion,
            curve: SongletMotion.standardCurve,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: SongletRadius.thumbAll,
              border: Border.all(
                color: frame,
                width: selected ? SongletSize.ruleStrong : SongletSize.rule,
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: ClipRRect(
                borderRadius: BorderRadius.all(
                  Radius.circular(SongletRadius.thumb - SongletSize.rule),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        child: InkWell(
                          onTap: onTap,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Ink(
                                decoration: BoxDecoration(
                                  color: c.surfaceMuted,
                                  image: image == null
                                      ? null
                                      : DecorationImage(
                                          image: image,
                                          fit: BoxFit.cover,
                                          onError: onImageError,
                                        ),
                                ),
                              ),                              if (onPlay != null)
                                PositionedDirectional(
                                  top: SongletSpace.x1,
                                  end: SongletSpace.x1,
                                  child: _PlayDot(
                                    playing: playing,
                                    label: playLabel,
                                    onTap: onPlay!,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // The printed margin: the name, set in the serif, on the
                    // stock rather than on the photograph.
                    GestureDetector(
                      onTap: onTap,
                      behavior: HitTestBehavior.opaque,
                      child: ExcludeSemantics(
                        child: Container(
                          height: captionHeight,
                          width: double.infinity,
                          alignment: AlignmentDirectional.center,
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: SongletSpace.x1,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? c.accent : c.surface,
                            border: Border(
                              top: BorderSide(color: frame),
                            ),
                          ),
                          child: Text(
                            title,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: SongletType.eyebrow.copyWith(
                              color: selected ? c.onAccent : c.ink,
                              fontSize: 8.5,
                              height: 1.2,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayDot extends StatelessWidget {
  const _PlayDot({
    required this.playing,
    required this.label,
    required this.onTap,
  });

  final bool playing;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Semantics(
      container: true,
      button: true,
      label: label,
      toggled: playing,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: SongletSize.minTap / 2,
        child: Container(
          width: SongletSize.iconMd,
          height: SongletSize.iconMd,
          decoration: BoxDecoration(
            color: c.surface,
            shape: BoxShape.circle,
            border: Border.all(color: c.ink.withValues(alpha: 0.18)),
          ),
          child: Icon(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: SongletSize.iconSm,
            color: c.ink,
          ),
        ),
      ),
    );
  }
}
