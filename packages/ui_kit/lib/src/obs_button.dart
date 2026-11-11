import 'package:flutter/material.dart';

import 'aura_style.dart';
import 'tokens.dart';
import 'tokens/songlet_metrics.dart';

/// The primary gradient action button. Shows a spinner and disables itself when
/// [loading]; disabled when [onPressed] is null.
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

  /// Defaults to the theme's [AuraStyle.actionGradient].
  final Gradient? gradient;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final style = AuraStyle.of(context);
    final onAction = style.onAction;
    final radius = BorderRadius.circular(StudioTokens.radiusPill);
    final labelStyle =
        (Theme.of(context).textTheme.labelLarge ?? const TextStyle()).copyWith(
          color: onAction,
          fontWeight: FontWeight.w700,
        );

    final content = loading
        ? SizedBox(
            width: SongletSize.actionSpinner,
            height: SongletSize.actionSpinner,
            child: CircularProgressIndicator(
              strokeWidth: SongletSize.focusRing,
              valueColor: AlwaysStoppedAnimation<Color>(onAction),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: onAction, size: 20),
                const SizedBox(width: StudioTokens.spaceSm),
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

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient ?? style.actionGradient,
          borderRadius: radius,
          boxShadow: enabled ? style.cardShadow : const <BoxShadow>[],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height),
              child: SizedBox(
                width: expand ? double.infinity : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                  child: Center(child: content),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
