import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';
import 'selection_mark.dart';

/// One music-video level on the hub (docs/ui P20, ADR-0027), set as a menu
/// entry: the level's name and its price on one line, what it makes under it,
/// and a struck square to choose it.
///
/// [statusLabel] replaces the price while a video of this level is being made,
/// and the entry is then not selectable ([onTap] null). A [badge]
/// ("Recommended", "Included") is printed above the name as a coral stamp.
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

  /// "Making…" while this level is in flight (the entry is disabled).
  final String? statusLabel;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final enabled = onTap != null;
    final status = statusLabel;

    final titleText = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 4),
          child: Icon(icon, size: SongletSize.iconSm, color: c.inkTertiary),
        ),
        const SizedBox(width: SongletSpace.x2),
        Expanded(
          child: Text(
            title,
            style: SongletType.title2.copyWith(
              color: enabled ? (selected ? c.accent : c.ink) : c.inkTertiary,
              fontSize: 19,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
    final priceText = status != null
        ? Text(
            status,
            style: SongletType.subhead.copyWith(
              color: c.accent,
              fontWeight: FontWeight.w600,
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                price,
                style: SongletType.folio.copyWith(
                  color: enabled ? c.ink : c.inkTertiary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (priceNote != null)
                Text(
                  priceNote!,
                  style: SongletType.caption2.copyWith(color: c.inkTertiary),
                ),
            ],
          );
    // Accessibility sizes: the price moves under the name instead of being
    // squeezed off the row.
    final head = SongletType.isAccessibilitySize(context)
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: titleText),
                  const SizedBox(width: SongletSpace.x3),
                  SelectionMark(selected: selected),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: priceText,
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: titleText),
              const SizedBox(width: SongletSpace.x2),
              priceText,
              const SizedBox(width: SongletSpace.x3),
              SelectionMark(selected: selected),
            ],
          );

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
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
                  width: selected
                      ? SongletSize.ruleStrong * 2
                      : SongletSize.rule,
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
                if (badge != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: SongletSpace.x1,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        badge!,
                        style: SongletType.stamp.copyWith(color: c.accent),
                      ),
                    ),
                  ),
                head,
                const SizedBox(height: 6),
                Text(
                  description,
                  style: SongletType.subhead.copyWith(
                    color: enabled ? c.inkSecondary : c.inkTertiary,
                    height: 1.4,
                  ),
                ),
                if (meta != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    meta!,
                    style: SongletType.caption2.copyWith(
                      color: c.inkTertiary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
