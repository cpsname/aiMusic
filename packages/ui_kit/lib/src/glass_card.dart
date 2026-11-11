import 'dart:ui';

import 'package:flutter/material.dart';

import 'aura_style.dart';
import 'tokens.dart';

/// A frosted-glass surface: blurred backdrop, translucent fill and hairline
/// stroke. Optionally tappable.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(StudioTokens.spaceLg),
    this.onTap,
    this.borderRadius,
    this.blur = 14,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(StudioTokens.radiusLg);
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
    if (!style.cardBlur) {
      // Opaque surfaces: a soft shadow instead of the backdrop blur.
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: style.cardShadow,
        ),
        child: ClipRRect(borderRadius: radius, child: interactive),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: interactive,
      ),
    );
  }
}
