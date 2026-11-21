import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';

/// A parameter selector that opens an anchored panel: Length / Vocals /
/// Genre (docs/ui composer row; "Song options" when [value] is set).
///
/// Set like a specification cell rather than a button: the parameter name in
/// small tracked caps, the current choice in the serif under it, and a rule
/// that turns coral while the panel is open.
class ParamChip extends StatelessWidget {
  const ParamChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.open = false,
  });

  final IconData icon;
  final String label;

  /// Current choice. When set the cell shows the name above the value.
  final String? value;
  final VoidCallback onTap;

  /// The cell's panel is showing (raised, coral rule).
  final bool open;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final stacked = value != null;
    final rule = open ? c.accent : c.hairline;
    return Semantics(
      container: true,
      button: true,
      expanded: open,
      label: stacked ? '$label: $value' : label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: open ? c.surface : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: rule,
              width: open ? SongletSize.ruleStrong : SongletSize.rule,
            ),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(SongletRadius.thumb),
            ),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: SongletSize.minTap),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  SongletSpace.x2,
                  SongletSpace.x2,
                  SongletSpace.x1,
                  SongletSpace.x2,
                ),
                child: Row(
                  children: [
                    if (!stacked) ...[
                      Icon(icon, size: SongletSize.iconSm, color: c.inkSecondary),
                      const SizedBox(width: SongletSpace.x2),
                    ],
                    Expanded(
                      child: stacked
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: SongletType.eyebrow.copyWith(
                                    color: open ? c.accent : c.inkTertiary,
                                    fontSize: SongletType.eyebrow.fontSize! - 1.5,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  value!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: SongletType.title3.copyWith(
                                    color: c.ink,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SongletType.subhead.copyWith(
                                color: c.ink,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                    Icon(
                      Icons.expand_more_rounded,
                      size: SongletSize.iconSm,
                      color: open ? c.accent : c.inkTertiary,
                      textDirection: Directionality.of(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
