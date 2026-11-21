import 'package:flutter/material.dart';

import 'tokens/songlet_colors.dart';
import 'tokens/songlet_metrics.dart';
import 'tokens/songlet_type.dart';

/// The "AI generated" disclosure badge (PRD §9.4 / D8). Deliberately has no
/// hide / dismiss option — every surface that shows a generated song shows it.
/// [locked] adds the padlock the share card uses to say it cannot be removed
/// (docs/ui P10).
///
/// Printed as a stamp: an "AI" mark followed by the word, no sparkles — the
/// disclosure is a legal note, not a decoration.
class AiGeneratedBadge extends StatelessWidget {
  const AiGeneratedBadge({
    super.key,
    required this.label,
    this.compact = false,
    this.locked = false,
  });

  final String label;
  final bool compact;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final icon = compact ? SongletSize.iconXs : SongletSize.iconSm;
    return Semantics(
      label: label,
      // One announcement: the visible text below is the same label.
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.badgeFill,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: compact ? 6 : SongletSpace.x2,
            vertical: compact ? 2 : 3,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // A printed bullet, not a sparkle: the disclosure is a legal
              // note, so it is marked with a rule rather than a decoration.
              Container(
                width: compact ? 2 : 3,
                height: compact ? 8 : 10,
                color: c.onBadge.withValues(alpha: 0.85),
              ),
              SizedBox(width: compact ? 4 : 6),
              Text(
                label,
                style: (compact ? SongletType.caption2 : SongletType.footnote)
                    .copyWith(
                      color: c.onBadge,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
              ),
              if (locked) ...[
                SizedBox(width: compact ? 4 : 6),
                Icon(Icons.lock_rounded, size: icon, color: c.onBadge),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
