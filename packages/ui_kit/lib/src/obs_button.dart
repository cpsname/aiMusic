import 'package:flutter/material.dart';

import 'tokens/songlet_colors.dart';
import 'tokens/songlet_metrics.dart';
import 'tokens/songlet_type.dart';

/// The page's one primary action, printed as a solid ink plate: near-black
/// stock, bone lettering, a hard two-point shadow and squared corners. On a
/// poster the call to action is the darkest thing on the page — the signal
/// coral is kept for marks, not for fields.
///
/// Disabled, the plate goes back to unprinted stock — muted paper with a
/// hairline and quiet lettering.
class ObsButton extends StatelessWidget {
  const ObsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.gradient,
    this.expand = true,
    this.height = SongletSize.primaryAction,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  /// Kept for the template's callers; the press prints a flat ink plate.
  final Gradient? gradient;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final c = SongletColors.of(context);
    final onInk = c.canvas;
    final labelColor = enabled ? onInk : c.inkTertiary;
    final radius = BorderRadius.circular(SongletRadius.control);
    final labelStyle =
        (Theme.of(context).textTheme.labelLarge ?? const TextStyle()).copyWith(
          color: labelColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        );

    final content = loading
        ? SizedBox(
            width: SongletSize.actionSpinner,
            height: SongletSize.actionSpinner,
            child: CircularProgressIndicator(
              strokeWidth: SongletSize.focusRing,
              valueColor: AlwaysStoppedAnimation<Color>(labelColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: labelColor, size: SongletSize.iconMd),
                const SizedBox(width: SongletSpace.x2),
              ],
              Flexible(
                child: Text(
                  label,
                  style: labelStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: enabled ? c.ink : c.surfaceMuted,
        borderRadius: radius,
        border: Border.all(
          color: enabled ? c.ink : c.hairline,
          width: SongletSize.rule,
        ),
        boxShadow: enabled
            ? const [
                BoxShadow(
                  color: Color(0x38000000),
                  offset: Offset(0, 3),
                  blurRadius: 0,
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: radius,
          splashColor: onInk.withValues(alpha: 0.16),
          highlightColor: onInk.withValues(alpha: 0.08),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: SizedBox(
              width: expand ? double.infinity : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: SongletSpace.x2,
                  horizontal: SongletSpace.x4,
                ),
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
