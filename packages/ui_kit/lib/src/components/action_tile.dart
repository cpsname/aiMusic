import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';

/// Icon-over-label action card (docs/ui P09: Download · Share · License ·
/// Regenerate), laid out in equal columns by the caller.
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.locked = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// Shows a small padlock (download locked, PRD §8.4).
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final ink = onPressed == null ? c.inkTertiary : c.ink;
    return Semantics(
      container: true,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: SongletRadius.controlAll,
          side: BorderSide(color: c.hairline),
        ),
        child: InkWell(
          borderRadius: SongletRadius.controlAll,
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: SongletSpace.x4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: ink, size: SongletSize.iconXl),
                    if (locked)
                      PositionedDirectional(
                        end: -SongletSpace.x2,
                        bottom: -SongletSpace.x1,
                        child: Icon(
                          Icons.lock_rounded,
                          size: SongletSize.iconSm,
                          color: c.accent,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: SongletSpace.x2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: SongletType.subhead.copyWith(color: ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
