import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_elevation.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';

/// A parameter selector that opens an anchored panel: Length / Vocals /
/// Genre (docs/ui P01 composer row; P03 "Song options" with [value]).
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

  /// Current choice. When set the chip shows "label / value" stacked (P03).
  final String? value;
  final VoidCallback onTap;

  /// The chip's panel is showing (raised, P02a–c).
  final bool open;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final e = SongletElevation.of(context);
    final stacked = value != null;
    return Semantics(
      container: true,
      button: true,
      expanded: open,
      label: stacked ? '$label: $value' : label,
      excludeSemantics: true,
      child: Material(
        color: open ? c.surfaceRaised : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: SongletRadius.controlAll,
          side: BorderSide(color: open ? c.surfaceRaised : c.hairline),
        ),
        shadowColor: open ? e.level2.first.color : null,
        elevation: open ? SongletSpace.x2 : 0,
        child: InkWell(
          borderRadius: SongletRadius.controlAll,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: SongletSize.minTap),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: SongletSpace.x2,
                vertical: SongletSpace.x2,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: SongletSize.iconSm + SongletSpace.x1,
                    color: stacked ? c.accent : c.ink,
                  ),
                  const SizedBox(width: SongletSpace.x1),
                  Expanded(
                    child: stacked
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: SongletType.caption.copyWith(
                                  color: c.inkSecondary,
                                ),
                              ),
                              Text(
                                value!,
                                style: SongletType.subhead.copyWith(
                                  color: c.ink,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            label,
                            style: SongletType.subhead.copyWith(color: c.ink),
                          ),
                  ),
                  Icon(
                    stacked
                        ? Icons.chevron_right_rounded
                        : Icons.expand_more_rounded,
                    size: SongletSize.iconSm,
                    color: c.inkSecondary,
                    textDirection: Directionality.of(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
