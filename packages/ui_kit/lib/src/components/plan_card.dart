import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';
import 'detail_rows.dart';

/// A subscription plan (docs/ui P08), set as a menu entry: the name and the
/// price on one line, the trial as a stamp, the benefits struck in beneath.
///
/// A selected entry takes a coral margin rule and the coral price; there is no
/// card, no glow and no checkmark discs — the printed page does not decorate
/// its prices.
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

  /// Width below which the price moves under the name.
  static const double _stackBelowWidth = SongletSize.minTap * 6;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final ink = selected ? c.accent : c.ink;
    final head = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: SongletType.title2.copyWith(
              color: ink,
              fontSize: 21,
              letterSpacing: -0.3,
            ),
          ),
        ),
        // The leader: the name and the price are set like a menu line.
        Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              SongletSpace.x2,
              0,
              SongletSpace.x2,
              5,
            ),
            child: SizedBox(
              height: 1,
              child: CustomPaint(
                painter: DottedLeaderPainter(color: c.inkTertiary),
              ),
            ),
          ),
        ),
        Text(
          price,
          style: SongletType.folio.copyWith(
            color: ink,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (trial != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 6),
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: SongletSpace.x2,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: c.accentSoft,
                borderRadius: BorderRadius.circular(SongletRadius.thumb),
              ),
              child: Text(
                trial!,
                style: SongletType.stamp.copyWith(color: c.accentPressed),
              ),
            ),
          ),
        const SizedBox(height: SongletSpace.x2),
        for (final b in benefits)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '—',
                  style: SongletType.footnote.copyWith(
                    color: selected ? c.accent : c.inkTertiary,
                  ),
                ),
                const SizedBox(width: SongletSpace.x2),
                Expanded(
                  child: Text(
                    b,
                    style: SongletType.subhead.copyWith(
                      color: c.inkSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsetsDirectional.only(bottom: SongletSpace.x2),
            decoration: BoxDecoration(
              border: BorderDirectional(
                start: BorderSide(
                  color: selected ? c.accent : c.hairline,
                  width: selected ? SongletSize.ruleStrong * 2 : SongletSize.rule,
                ),
                bottom: BorderSide(color: c.hairline),
              ),
            ),
            padding: const EdgeInsetsDirectional.fromSTEB(
              SongletSpace.x3,
              SongletSpace.x3,
              SongletSpace.x2,
              SongletSpace.x3,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (ribbon != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: SongletSpace.x1,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        ribbon!,
                        style: SongletType.stamp.copyWith(color: c.highlight),
                      ),
                    ),
                  ),
                LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth <
                          _stackBelowWidth
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            head,
                            const SizedBox(height: SongletSpace.x2),
                            body,
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [head, body],
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

/// The one-off pack row (docs/ui P08 "Just need a few? 10-song pack"): a
/// ruled entry with the price at the margin and a struck square when picked.
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
    final mark = Container(
      width: SongletSize.iconMd,
      height: SongletSize.iconMd,
      decoration: BoxDecoration(
        color: selected ? c.accent : Colors.transparent,
        border: Border.all(
          color: selected ? c.accent : c.inkTertiary,
          width: SongletSize.rule,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: selected
          ? Icon(
              Icons.check_rounded,
              size: SongletSize.iconSm,
              color: c.onAccent,
            )
          : null,
    );
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: SongletType.title3.copyWith(color: c.ink, fontSize: 16),
        ),
        Text(
          subtitle,
          style: SongletType.footnote.copyWith(color: c.inkSecondary),
        ),
      ],
    );
    final priceBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          price,
          style: SongletType.folio.copyWith(
            color: selected ? c.accent : c.ink,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          note,
          style: SongletType.caption2.copyWith(color: c.inkTertiary),
        ),
      ],
    );
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: c.hairline),
              ),
            ),
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: SongletSpace.x3,
            ),
            // Accessibility sizes: the price moves under the entry rather than
            // being squeezed off the row.
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stack = SongletType.isAccessibilitySize(context) ||
                    constraints.maxWidth < 260;
                if (stack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          mark,
                          const SizedBox(width: SongletSpace.x3),
                          Expanded(child: texts),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: SongletSize.iconMd + SongletSpace.x3,
                        ),
                        child: priceBlock,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    mark,
                    const SizedBox(width: SongletSpace.x3),
                    Expanded(child: texts),
                    const SizedBox(width: SongletSpace.x2),
                    priceBlock,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon over a caption (P08 hero benefits, value strip). The icon is set bare:
/// the press does not use tinted discs.
class IconCaption extends StatelessWidget {
  const IconCaption({
    super.key,
    required this.icon,
    required this.label,
    this.tinted = true,
  });

  final IconData icon;
  final String label;

  /// Kept for the template's callers; the press sets the glyph bare.
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: c.accent, size: SongletSize.iconLg),
        const SizedBox(height: SongletSpace.x2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: SongletType.subhead.copyWith(color: c.ink, height: 1.35),
        ),
      ],
    );
  }
}

/// Inline legal / account links separated by dots (P08 footer).
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
                '  ·  ',
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
                      decorationColor: c.inkTertiary,
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
