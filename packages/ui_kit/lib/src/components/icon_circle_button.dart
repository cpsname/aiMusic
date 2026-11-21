import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';

/// Square icon button (back, more, close, copy) — a ruled key, not a disc —
/// docs/ui P08, P09, P13.
class IconCircleButton extends StatelessWidget {
  const IconCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.size = SongletSize.minTap,
    this.filled = true,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;

  /// Ruled fill; false = bare icon with the same hit target.
  final bool filled;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final radius = BorderRadius.circular(SongletRadius.control);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        container: true,
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          color: filled ? c.surface : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: filled ? c.hairline : Colors.transparent,
            ),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: SizedBox.square(
              dimension: size,
              child: Icon(
                icon,
                size: SongletSize.iconMd,
                color: onPressed == null ? c.inkTertiary : (color ?? c.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
