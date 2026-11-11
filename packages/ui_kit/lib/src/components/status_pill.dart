import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';

/// Tone of a [StatusPill].
enum PillTone { accent, success, neutral, danger }

/// Small rounded label: "Preview" / "Full song" (P12), "Full song ready"
/// (P11), "7-day free trial" (P08), allowance counters (P01).
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

  /// Opacity of the success tint over the surface.
  static const double _successTintAlpha = 0.14;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final (fill, ink) = switch (tone) {
      PillTone.accent => (c.accentSoft, c.accent),
      PillTone.success => (
        Color.alphaBlend(
          c.success.withValues(alpha: _successTintAlpha),
          c.surface,
        ),
        c.success,
      ),
      PillTone.neutral => (c.surfaceMuted, c.inkSecondary),
      PillTone.danger => (c.dangerSoft, c.danger),
    };
    final style = (large ? SongletType.subhead : SongletType.caption).copyWith(
      color: ink,
      fontWeight: FontWeight.w600,
    );
    final pill = Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: large ? SongletSpace.x4 : SongletSpace.x3,
        vertical: large ? SongletSpace.x2 : SongletSpace.x1,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: SongletRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: large ? SongletSize.iconMd : SongletSize.iconSm,
              color: ink,
            ),
            const SizedBox(width: SongletSpace.x1),
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
