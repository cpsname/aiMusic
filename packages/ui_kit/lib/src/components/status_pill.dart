import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';

/// Tone of a [StatusPill].
enum PillTone { accent, success, neutral, danger }

/// A small stamped label: "Preview" / "Full song" (P12), "Full song ready"
/// (P11), "7-day free trial" (P08), allowance counters (P01).
///
/// Printed as a rubber stamp — a mono label between two rules, not a rounded
/// tinted capsule. The tone shows in the rule and the lettering.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.tone = PillTone.accent,
    this.icon,
    this.large = false,
    this.onTap,
  });

  final String label;
  final PillTone tone;
  final IconData? icon;
  final bool large;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final (rule, ink) = switch (tone) {
      // The signal is bright, so its lettering is the pressed tone.
      PillTone.accent => (c.accent, c.accentPressed),
      PillTone.success => (c.success, c.success),
      PillTone.neutral => (c.hairline, c.inkSecondary),
      PillTone.danger => (c.danger, c.danger),
    };
    final style = (large ? SongletType.eyebrow : SongletType.stamp).copyWith(
      color: ink,
      fontWeight: FontWeight.w700,
      fontSize: large ? 10.5 : 9.5,
    );
    final pill = Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: large ? SongletSpace.x2 : 6,
        vertical: large ? 5 : 3,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: rule, width: SongletSize.rule),
        borderRadius: BorderRadius.circular(1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: large ? SongletSize.iconSm : SongletSize.iconXs,
              color: ink,
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return pill;
    return Semantics(
      container: true,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: pill,
      ),
    );
  }
}
