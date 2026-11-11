import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';

/// Rounded-square action with a caption (docs/ui P10 share row; ADR-0010).
class ShareTargetButton extends StatelessWidget {
  const ShareTargetButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final fill = primary ? c.accent : c.surfaceMuted;
    final ink = primary ? c.onAccent : c.ink;
    return Semantics(
      container: true,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: busy ? null : onPressed,
        borderRadius: SongletRadius.controlAll,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(SongletSpace.x1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: SongletSize.playButton,
                height: SongletSize.playButton,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: SongletRadius.controlAll,
                ),
                child: busy
                    ? Padding(
                        padding: const EdgeInsetsDirectional.all(
                          SongletSpace.x5,
                        ),
                        child: CircularProgressIndicator(
                          color: ink,
                          strokeWidth: SongletSize.focusRing,
                        ),
                      )
                    : Icon(icon, color: ink, size: SongletSize.iconXl),
              ),
              const SizedBox(height: SongletSpace.x2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: SongletType.subhead.copyWith(color: c.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A layout choice thumbnail (P10 "Layout").
class LayoutOptionTile extends StatelessWidget {
  const LayoutOptionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Opacity of the accent fill behind the selected layout's icon.
  static const double _selectedFillAlpha = 0.8;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: SongletRadius.controlAll,
        child: Container(
          width: SongletSize.playButton + SongletSpace.x2,
          height: SongletSize.playButton + SongletSpace.x8,
          padding: const EdgeInsetsDirectional.all(SongletSpace.x2),
          decoration: BoxDecoration(
            borderRadius: SongletRadius.controlAll,
            border: Border.all(
              color: selected ? c.accent : c.hairline,
              width: selected ? SongletSize.focusRing : SongletSize.hairline,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: selected
                  ? c.accent.withValues(alpha: _selectedFillAlpha)
                  : c.surfaceMuted,
              borderRadius: SongletRadius.thumbAll,
            ),
            child: Icon(icon, color: selected ? c.onAccent : c.inkSecondary),
          ),
        ),
      ),
    );
  }
}
