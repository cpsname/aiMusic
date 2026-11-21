import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';

/// Icon-over-label action key (docs/ui P09: Download · Share · License ·
/// Regenerate), laid out in equal columns by the caller. A ruled key: one
/// hairline box, the glyph, and a tracked caption.
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
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: SongletRadius.controlAll,
          side: BorderSide(color: c.hairline),
        ),
        child: InkWell(
          borderRadius: SongletRadius.controlAll,
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: SongletSpace.x3,
              horizontal: SongletSpace.x1,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: ink, size: SongletSize.iconMd),
                    if (locked)
                      PositionedDirectional(
                        end: -SongletSpace.x2,
                        bottom: -SongletSpace.x1,
                        child: Icon(
                          Icons.lock_rounded,
                          size: SongletSize.iconXs,
                          color: c.accent,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: SongletType.caption.copyWith(
                    color: ink,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
