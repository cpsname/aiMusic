import 'package:flutter/material.dart';

import '../motion.dart';
import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_motion.dart';
import '../tokens/songlet_type.dart';
import 'cover_fallback.dart';

/// A create-home tile (docs/ui P01, ADR-0032): a photo, the title and a play
/// button. The photo is [image] (the server's `cover_image_url` or a bundled
/// photo); when it fails to load, [fallbackImage] (the template's or the
/// occasion's photo) takes its place; while it loads the tile is a muted
/// surface. A [selected] tile — the composer's pick — takes the accent outline
/// and settles slightly inward; the play button never changes the pick.
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

  /// The composer's pick: accent outline and the inward settle.
  final bool selected;

  /// Scale of a [selected] tile.
  static const double selectedScale = 0.95;

  /// Where the bottom scrim starts fading in (× height).
  static const double _scrimStart = 0.45;

  /// Tight line height of the two-line title on the art.
  static const double _titleLineHeight = 1.15;

  @override
  Widget build(BuildContext context) =>
      CoverFallback(primary: image, fallback: fallbackImage, builder: _tile);

  Widget _tile(
    BuildContext context,
    ImageProvider? image,
    ImageErrorListener onImageError,
  ) {
    final c = SongletColors.of(context);
    final onArt = c.onArt;
    final motion = MotionPolicy.reduceMotion(context)
        ? SongletMotion.none
        : SongletMotion.fast;
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
              borderRadius: SongletRadius.controlAll,
              // The pick glows: an aurora ring backed by a soft halo, so the
              // composer's card is findable at a glance in the grid.
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: c.accent.withValues(alpha: 0.55),
                        blurRadius: SongletSpace.x6,
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Material(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: SongletRadius.controlAll,
                side: selected
                    ? BorderSide(color: c.accent, width: SongletSize.focusRing)
                    : BorderSide.none,
              ),
              child: Ink(
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
                child: InkWell(
                  onTap: onTap,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [_scrimStart, 1],
                        colors: [c.artScrim.withValues(alpha: 0), c.artScrim],
                      ),
                    ),
                    // Title across the full width at the bottom; the sample
                    // button sits in the top corner so a long (or translated)
                    // name never has to break mid-word next to it.
                    child: Stack(
                      children: [
                        PositionedDirectional(
                          start: SongletSpace.x2,
                          end: SongletSpace.x2,
                          bottom: SongletSpace.x2,
                          child: ExcludeSemantics(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: SongletType.footnote.copyWith(
                                color: onArt,
                                fontWeight: FontWeight.w600,
                                height: _titleLineHeight,
                                shadows: [
                                  Shadow(
                                    color: c.artScrim,
                                    blurRadius: SongletSpace.x2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (onPlay != null)
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
    const dot = SongletSize.iconLg;
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
          width: dot,
          height: dot,
          decoration: BoxDecoration(color: c.onArt, shape: BoxShape.circle),
          child: Icon(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: SongletSize.iconSm,
            color: SongletColors.light.ink,
          ),
        ),
      ),
    );
  }
}
