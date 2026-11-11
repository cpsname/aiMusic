import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_type.dart';

/// Dot-separated metadata ("Indie Pop · English · Birthday", docs/ui P05).
class MetaLine extends StatelessWidget {
  const MetaLine({
    super.key,
    required this.parts,
    this.style,
    this.textAlign = TextAlign.center,
  });

  final List<String> parts;
  final TextStyle? style;
  final TextAlign textAlign;

  static String join(Iterable<String> parts) =>
      parts.where((p) => p.trim().isNotEmpty).join('  ·  ');

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Text(
      join(parts),
      textAlign: textAlign,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: style ?? SongletType.callout.copyWith(color: c.inkSecondary),
    );
  }
}
