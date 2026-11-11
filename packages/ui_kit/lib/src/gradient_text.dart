import 'package:flutter/material.dart';

import 'tokens.dart';

/// Text painted with a gradient shader.
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    this.gradient = StudioTokens.auroraGradient,
    this.style,
    this.textAlign,
  });

  final String text;
  final Gradient gradient;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final baseStyle =
        (style ??
                Theme.of(context).textTheme.headlineMedium ??
                const TextStyle())
            .copyWith(color: Colors.white);
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        // Required for directional gradients (AlignmentDirectional begin/end);
        // also makes the text gradient mirror under RTL.
        textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      ),
      child: Text(text, style: baseStyle, textAlign: textAlign),
    );
  }
}
