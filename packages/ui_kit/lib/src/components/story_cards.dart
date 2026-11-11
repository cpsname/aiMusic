import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';
import 'songlet_mark.dart';
import 'surface_card.dart';

/// Icon + title + body card (docs/ui P15).
class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return SurfaceCard(
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: SongletSize.thumbnail,
              child: Icon(
                icon,
                color: c.accent,
                size: SongletSize.iconXl + SongletSpace.x3,
              ),
            ),
            const SizedBox(width: SongletSpace.x4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SongletType.headline.copyWith(color: c.ink),
                  ),
                  const SizedBox(height: SongletSpace.x1),
                  Text(
                    body,
                    style: SongletType.subhead.copyWith(color: c.inkSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Accent statement banner with the mark (P15 "Every song you share is
/// labeled AI generated.").
class HighlightBanner extends StatelessWidget {
  const HighlightBanner({super.key, required this.message});

  final String message;

  /// Opacity of the divider between the mark and the message.
  static const double _dividerAlpha = 0.4;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Semantics(
      container: true,
      label: message,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsetsDirectional.all(SongletSpace.x5),
        decoration: BoxDecoration(
          gradient: c.actionGradient,
          borderRadius: SongletRadius.cardAll,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              SongletMark(
                size: SongletSize.thumbnail + SongletSpace.x6,
                tile: false,
                color: c.onAccent,
              ),
              VerticalDivider(
                color: c.onAccent.withValues(alpha: _dividerAlpha),
                width: SongletSpace.x8,
              ),
              Expanded(
                child: Text(
                  message,
                  style: SongletType.title3.copyWith(
                    color: c.onAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Seasonal hero (docs/ui P16): kicker, script-like title, body, CTA pill, art
/// on the end side.
class FestivalHero extends StatelessWidget {
  const FestivalHero({
    super.key,
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.ctaLabel,
    required this.onCta,
    required this.art,
  });

  final String kicker;
  final String title;
  final String subtitle;
  final String body;
  final String ctaLabel;
  final VoidCallback onCta;
  final ImageProvider art;

  /// The festival name is set larger than any page title (docs/ui P16).
  static const double heroTitleScale = 1.4;

  /// Width of the art strip on the end side.
  static const double _artWidth = SongletSize.coverLarge * 0.75;

  /// Where the art's fade-in from the card fill ends (× art width).
  static const double _artFadeEnd = 0.35;

  /// Share of the card width the copy column takes.
  static const double _copyWidthFactor = 0.72;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return ClipRRect(
      borderRadius: SongletRadius.cardAll,
      child: Container(
        decoration: BoxDecoration(color: c.accentSoft),
        child: Stack(
          children: [
            PositionedDirectional(
              top: 0,
              bottom: 0,
              end: 0,
              width: _artWidth,
              child: ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  colors: [c.accentSoft.withValues(alpha: 0), c.accentSoft],
                  stops: const [0, _artFadeEnd],
                ).createShader(rect, textDirection: Directionality.of(context)),
                blendMode: BlendMode.dstIn,
                child: Image(
                  image: art,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.all(SongletSpace.x6),
              child: FractionallySizedBox(
                widthFactor: _copyWidthFactor,
                alignment: AlignmentDirectional.centerStart,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kicker.toUpperCase(),
                      style: SongletType.caption.copyWith(
                        color: c.accent,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: SongletSpace.x2),
                    Text(
                      title,
                      style: SongletType.largeTitle.copyWith(
                        color: c.accent,
                        fontFamily: SongletType.serifFamily,
                        fontStyle: FontStyle.italic,
                        fontSize:
                            SongletType.largeTitle.fontSize! * heroTitleScale,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: SongletType.title3.copyWith(
                        color: c.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: SongletSpace.x3),
                    Text(
                      body,
                      style: SongletType.subhead.copyWith(
                        color: c.inkSecondary,
                      ),
                    ),
                    const SizedBox(height: SongletSpace.x4),
                    FilledButton.icon(
                      onPressed: onCta,
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.chevron_right_rounded),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(ctaLabel, maxLines: 1),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: c.onAccent,
                        minimumSize: const Size(0, SongletSize.minTap),
                        shape: const StadiumBorder(),
                        textStyle: themedTextStyle(
                          context,
                          SongletType.subhead.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Occasion card with art (docs/ui P16 grid).
class OccasionCard extends StatelessWidget {
  /// Art width ÷ height (docs/ui P16).
  static const double artAspect = 0.75;

  /// Most lines of the occasion hint.
  static const int hintMaxLines = 3;

  const OccasionCard({
    super.key,
    required this.image,
    required this.title,
    required this.hint,
    required this.onTap,
  });

  final ImageProvider image;
  final String title;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return SurfaceCard(
      padding: const EdgeInsetsDirectional.all(SongletSpace.x2),
      onTap: onTap,
      child: Semantics(
        container: true,
        button: true,
        label: title,
        excludeSemantics: true,
        child: Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: artAspect,
                child: ClipRRect(
                  borderRadius: SongletRadius.controlAll,
                  child: Image(image: image, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(width: SongletSpace.x3),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Container(
                      width: SongletSize.iconXl,
                      height: SongletSize.iconXl,
                      decoration: BoxDecoration(
                        color: c.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: SongletSize.iconMd,
                        color: c.ink,
                      ),
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 2,
                    style: SongletType.subhead.copyWith(
                      color: c.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    hint,
                    maxLines: hintMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: SongletType.footnote.copyWith(color: c.inkSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wide link card with a leading round glyph (P16 "Songs in your language").
class LinkCard extends StatelessWidget {
  const LinkCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsetsDirectional.all(SongletSpace.x4),
      child: MergeSemantics(
        child: Row(
          children: [
            Container(
              width: SongletSize.controlHeight,
              height: SongletSize.controlHeight,
              decoration: BoxDecoration(
                color: c.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: c.accent),
            ),
            const SizedBox(width: SongletSpace.x4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SongletType.headline.copyWith(color: c.ink),
                  ),
                  Text(
                    subtitle,
                    style: SongletType.footnote.copyWith(color: c.inkSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.inkSecondary),
          ],
        ),
      ),
    );
  }
}
