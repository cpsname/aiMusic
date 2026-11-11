import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_elevation.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';

/// One music-video level on the hub (docs/ui P20, ADR-0027): an icon disc,
/// the level's name and what it makes, a meta line (length · shape), and the
/// price on the end side. Selected = accent outline; [statusLabel] replaces
/// the price while a video of this level is being made, and the card is then
/// not selectable ([onTap] null). A [badge] ("Recommended", "Included")
/// sits in the top end corner.
class MvLevelCard extends StatelessWidget {
  const MvLevelCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.price,
    required this.selected,
    required this.onTap,
    this.meta,
    this.priceNote,
    this.badge,
    this.statusLabel,
  });

  final IconData icon;
  final String title;
  final String description;

  /// "Free", "2,169 credits", formatted by the caller; a dash while the
  /// price is unknown.
  final String price;

  /// Under the price: "You have 3,000", "2,103 more needed".
  final String? priceNote;
  final String? meta;
  final String? badge;

  /// "Making…" while this level is in flight (the card is disabled).
  final String? statusLabel;
  final bool selected;
  final VoidCallback? onTap;

  /// Fill tint of the selected card (accent-soft over the surface).
  static const double _selectedTintAlpha = 0.35;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final e = SongletElevation.of(context);
    final enabled = onTap != null;
    final stacked = SongletType.isAccessibilitySize(context);
    final ink = enabled ? c.ink : c.inkTertiary;

    final disc = Container(
      width: SongletSize.thumbnail,
      height: SongletSize.thumbnail,
      decoration: BoxDecoration(
        color: enabled ? c.accentSoft : c.hairline,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: enabled ? c.accent : c.inkTertiary, size: SongletSize.iconLg),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: SongletType.headline.copyWith(color: ink)),
        const SizedBox(height: SongletSpace.x1),
        Text(description, style: SongletType.subhead.copyWith(color: enabled ? c.inkSecondary : c.inkTertiary)),
        if (meta != null) ...[
          const SizedBox(height: SongletSpace.x1),
          Text(meta!, style: SongletType.footnote.copyWith(color: c.inkTertiary)),
        ],
      ],
    );
    final status = statusLabel;
    final priceColumn = Column(
      crossAxisAlignment: stacked ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status != null)
          Text(status, style: SongletType.subhead.copyWith(color: c.accent, fontWeight: FontWeight.w600))
        else ...[
          Text(
            price,
            style: SongletType.title3.copyWith(
              color: enabled ? c.accent : c.inkTertiary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (priceNote != null)
            Text(
              priceNote!,
              textAlign: stacked ? TextAlign.start : TextAlign.end,
              style: SongletType.caption.copyWith(color: c.inkSecondary),
            ),
        ],
      ],
    );

    final body = Padding(
      padding: const EdgeInsetsDirectional.all(SongletSpace.x4),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                disc,
                const SizedBox(height: SongletSpace.x3),
                text,
                const SizedBox(height: SongletSpace.x3),
                priceColumn,
              ],
            )
          : Row(
              children: [
                disc,
                const SizedBox(width: SongletSpace.x4),
                Expanded(child: text),
                const SizedBox(width: SongletSpace.x3),
                priceColumn,
              ],
            ),
    );

    final card = Material(
      color: selected ? Color.alphaBlend(c.accentSoft.withValues(alpha: _selectedTintAlpha), c.surface) : c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: SongletRadius.cardAll,
        side: BorderSide(
          color: selected ? c.accent : c.hairline,
          width: selected ? SongletSize.focusRing : SongletSize.hairline,
        ),
      ),
      child: InkWell(borderRadius: SongletRadius.cardAll, onTap: onTap, child: body),
    );

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(borderRadius: SongletRadius.cardAll, boxShadow: selected ? e.level2 : e.level1),
            child: card,
          ),
          if (badge != null)
            PositionedDirectional(
              top: -SongletSpace.x3,
              end: SongletSpace.x4,
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: SongletSpace.x3, vertical: SongletSpace.x1),
                decoration: BoxDecoration(color: c.accent, borderRadius: SongletRadius.pillAll),
                child: Text(
                  badge!,
                  style: SongletType.footnote.copyWith(color: c.onAccent, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
