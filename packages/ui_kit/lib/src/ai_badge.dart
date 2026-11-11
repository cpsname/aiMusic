import 'package:flutter/material.dart';

import 'tokens/songlet_colors.dart';
import 'tokens/songlet_metrics.dart';
import 'tokens/songlet_type.dart';

/// The "AI generated" disclosure badge (PRD §9.4 / D8). Deliberately has no
/// hide / dismiss option — every surface that shows a generated song shows it.
/// [locked] adds the padlock the share card uses to say it cannot be removed
/// (docs/ui P10).
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
          borderRadius: SongletRadius.pillAll,
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: compact ? SongletSpace.x2 : SongletSpace.x3,
            vertical: compact ? SongletSpace.x1 : SongletSpace.x2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: icon, color: c.onBadge),
              SizedBox(width: compact ? SongletSpace.x1 : SongletSpace.x2),
              Text(
                label,
                style: (compact ? SongletType.caption2 : SongletType.footnote)
                    .copyWith(color: c.onBadge, fontWeight: FontWeight.w600),
              ),
              if (locked) ...[
                SizedBox(width: compact ? SongletSpace.x1 : SongletSpace.x2),
                Icon(Icons.lock_rounded, size: icon, color: c.onBadge),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
