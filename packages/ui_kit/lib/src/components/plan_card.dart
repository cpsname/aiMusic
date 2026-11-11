import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_elevation.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';

/// A subscription plan (docs/ui P08): name, price, optional trial pill and
/// "Best value" ribbon on the start side; benefits with checks on the end
/// side. Selected = accent outline and accent checks.
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.benefits,
    required this.selected,
    required this.onTap,
    this.ribbon,
    this.trial,
  });

  final String title;
  final String price;
  final List<String> benefits;
  final bool selected;
  final VoidCallback onTap;
  final String? ribbon;
  final String? trial;

  /// Fill tint of the selected card (accent-soft over the surface).
  static const double _selectedTintAlpha = 0.35;

  /// Width below which the price and the benefits stack instead of sitting
  /// side by side.
  static const double _stackBelowWidth = SongletSize.minTap * 7;

  /// Flex weights of the price column and the benefit list side by side.
  static const int _headFlex = 5;
  static const int _listFlex = 6;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final e = SongletElevation.of(context);
    final card = Material(
      color: selected
          ? Color.alphaBlend(
              c.accentSoft.withValues(alpha: _selectedTintAlpha),
              c.surface,
            )
          : c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: SongletRadius.cardAll,
        side: BorderSide(
          color: selected ? c.accent : c.hairline,
          width: selected ? SongletSize.focusRing : SongletSize.hairline,
        ),
      ),
      child: InkWell(
        borderRadius: SongletRadius.cardAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(SongletSpace.x5),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < _stackBelowWidth;
              final head = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SongletType.title3.copyWith(
                      color: c.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // One line: "$4.99/week" shrinks to the column rather than
                  // breaking at the slash.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      price,
                      maxLines: 1,
                      style: SongletType.title1.copyWith(color: c.accent),
                    ),
                  ),
                  if (trial != null) ...[
                    const SizedBox(height: SongletSpace.x2),
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: SongletSpace.x3,
                        vertical: SongletSpace.x1,
                      ),
                      decoration: BoxDecoration(
                        color: c.accentSoft,
                        borderRadius: SongletRadius.pillAll,
                      ),
                      child: Text(
                        trial!,
                        style: SongletType.subhead.copyWith(color: c.accent),
                      ),
                    ),
                  ],
                ],
              );
              final list = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final b in benefits)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: SongletSpace.x1,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: SongletSize.iconMd,
                            color: selected ? c.accent : c.inkTertiary,
                          ),
                          const SizedBox(width: SongletSpace.x2),
                          Expanded(
                            child: Text(
                              b,
                              style: SongletType.subhead.copyWith(color: c.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
              return narrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        head,
                        const SizedBox(height: SongletSpace.x3),
                        list,
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: _headFlex, child: head),
                        const SizedBox(width: SongletSpace.x3),
                        Expanded(flex: _listFlex, child: list),
                      ],
                    );
            },
          ),
        ),
      ),
    );
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: SongletRadius.cardAll,
              boxShadow: selected ? e.level2 : e.level1,
            ),
            child: card,
          ),
          if (ribbon != null)
            PositionedDirectional(
              top: -SongletSpace.x3,
              end: SongletSpace.x4,
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: SongletSpace.x3,
                  vertical: SongletSpace.x1,
                ),
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: SongletRadius.pillAll,
                ),
                child: Text(
                  ribbon!,
                  style: SongletType.footnote.copyWith(
                    color: c.onAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The one-off pack row (docs/ui P08 "Just need a few? 10-song pack").
class PackRow extends StatelessWidget {
  const PackRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.note,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String price;
  final String note;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final disc = Container(
      width: SongletSize.thumbnail,
      height: SongletSize.thumbnail,
      decoration: BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
      child: Icon(
        Icons.toll_rounded,
        color: c.accent,
        size: SongletSize.iconXl,
      ),
    );
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: SongletType.callout.copyWith(
            color: c.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(subtitle, style: SongletType.callout.copyWith(color: c.ink)),
      ],
    );
    final price = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(this.price, style: SongletType.title3.copyWith(color: c.accent)),
        Text(note, style: SongletType.footnote.copyWith(color: c.inkSecondary)),
      ],
    );
    final chevron = Icon(Icons.chevron_right_rounded, color: c.inkSecondary);
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: SongletRadius.cardAll,
          side: BorderSide(
            color: selected ? c.accent : c.hairline,
            width: selected ? SongletSize.focusRing : SongletSize.hairline,
          ),
        ),
        child: InkWell(
          borderRadius: SongletRadius.cardAll,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(SongletSpace.x4),
            // Accessibility sizes: the price moves under the title.
            child: SongletType.isAccessibilitySize(context)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          disc,
                          const SizedBox(width: SongletSpace.x4),
                          Expanded(child: texts),
                        ],
                      ),
                      const SizedBox(height: SongletSpace.x3),
                      Row(
                        children: [
                          Expanded(child: price),
                          chevron,
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      disc,
                      const SizedBox(width: SongletSpace.x4),
                      Expanded(child: texts),
                      Flexible(child: price),
                      chevron,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Round icon over a caption (P08 hero benefits, value strip).
class IconCaption extends StatelessWidget {
  const IconCaption({
    super.key,
    required this.icon,
    required this.label,
    this.tinted = true,
  });

  final IconData icon;
  final String label;

  /// Soft accent disc behind the icon.
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (tinted)
          Container(
            width: SongletSize.thumbnail,
            height: SongletSize.thumbnail,
            decoration: BoxDecoration(
              color: c.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: c.accent, size: SongletSize.iconLg),
          )
        else
          Icon(icon, color: c.ink, size: SongletSize.iconLg),
        const SizedBox(height: SongletSpace.x2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: (tinted ? SongletType.subhead : SongletType.footnote).copyWith(
            color: tinted ? c.ink : c.inkSecondary,
          ),
        ),
      ],
    );
  }
}

/// Inline legal / account links separated by bars (P08 footer).
class LinkRow extends StatelessWidget {
  const LinkRow({super.key, required this.links});

  final List<(String, VoidCallback)> links;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < links.length; i++) ...[
          if (i > 0)
            ExcludeSemantics(
              child: Text(
                '  |  ',
                style: SongletType.footnote.copyWith(color: c.inkTertiary),
              ),
            ),
          Semantics(
            link: true,
            child: InkWell(
              onTap: links[i].$2,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: SongletSize.minTap,
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    links[i].$1,
                    style: SongletType.footnote.copyWith(
                      color: c.inkSecondary,
                      decoration: TextDecoration.underline,
                      decorationColor: c.inkSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
