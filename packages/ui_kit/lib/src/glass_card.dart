import 'package:flutter/material.dart';

import 'aura_style.dart';
import 'tokens.dart';
import 'tokens/songlet_metrics.dart';

/// A paper plate. The template's frosted glass is gone: a card is a sheet of
/// the same stock, lifted by a hairline and (at most) a one-point keyline —
/// never a blurred backdrop.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(StudioTokens.spaceLg),
    this.onTap,
    this.borderRadius,
    this.blur = 0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  /// Ignored; kept so older callers still compile.
  final double blur;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? SongletRadius.cardAll;
    final style = AuraStyle.of(context);
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: style.cardFill,
        borderRadius: radius,
        border: Border.all(color: style.cardStroke),
      ),
      // A transparent Material so ink-drawing children (ListTile, InkWell)
      // paint on the card instead of an ancestor hidden behind its fill.
      child: Material(
        type: MaterialType.transparency,
        child: Padding(padding: padding, child: child),
      ),
    );
    final interactive = onTap == null
        ? surface
        : Material(
            color: Colors.transparent,
            child: InkWell(onTap: onTap, borderRadius: radius, child: surface),
          );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: style.cardShadow,
      ),
      child: ClipRRect(borderRadius: radius, child: interactive),
    );
  }
}
