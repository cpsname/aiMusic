import 'package:flutter/material.dart';

import 'tokens/songlet_metrics.dart';
import 'tokens/songlet_type.dart';

/// A set tag (genres, keywords, filters) — a rubber stamp, not a pill:
/// squared corners, one hairline, and the accent plate when selected.
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onRemove,
    this.removeTooltip,
    this.trailingIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Shows a trailing ✕ when set.
  final VoidCallback? onRemove;
  final String? removeTooltip;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline = theme.colorScheme.outline;
    final ink = theme.colorScheme.onSurface;
    final fg = selected ? theme.colorScheme.surface : ink;
    final radius = BorderRadius.circular(SongletRadius.control);
    return Material(
      color: selected ? ink : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: selected ? ink : outline,
          width: SongletSize.rule,
        ),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: SongletSize.chipHeight),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: SongletType.subhead.copyWith(
                      color: fg,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: SongletSpace.x1),
                  Icon(trailingIcon, size: SongletSize.iconSm, color: fg),
                ],
                if (onRemove != null) ...[
                  const SizedBox(width: SongletSpace.x2),
                  InkResponse(
                    onTap: onRemove,
                    radius: 16,
                    child: Tooltip(
                      message: removeTooltip ?? '',
                      child: Icon(
                        Icons.close_rounded,
                        size: SongletSize.iconSm,
                        color: fg,
                      ),
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
