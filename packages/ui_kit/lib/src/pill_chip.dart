import 'package:flutter/material.dart';

import 'aura_style.dart';
import 'tokens.dart';

/// A rounded selectable pill (genres, keywords, filters). Selected = filled
/// with the theme accent; otherwise a white pill with a hairline.
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
    final style = AuraStyle.of(context);
    final theme = Theme.of(context);
    final fg = selected ? Colors.white : theme.textTheme.bodyLarge?.color;
    final radius = BorderRadius.circular(StudioTokens.radiusPill);
    return Material(
      color: selected ? style.accent : style.cardFill,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: selected ? style.accent : style.cardStroke),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 10, 14, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: StudioTokens.spaceXs),
                Icon(trailingIcon, size: 18, color: fg),
              ],
              if (onRemove != null) ...[
                const SizedBox(width: StudioTokens.spaceSm),
                InkResponse(
                  onTap: onRemove,
                  radius: 16,
                  child: Tooltip(
                    message: removeTooltip ?? '',
                    child: Icon(Icons.close_rounded, size: 18, color: fg),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
