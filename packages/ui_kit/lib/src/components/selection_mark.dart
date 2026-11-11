import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';

/// Radio-style selection indicator: a filled accent check or an empty ring
/// (docs/ui P02, P02a–c).
class SelectionMark extends StatelessWidget {
  const SelectionMark({
    super.key,
    required this.selected,
    this.size = SongletSize.iconLg,
  });

  final bool selected;
  final double size;

  /// Check glyph size (× mark size).
  static const double _checkScale = 0.7;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? c.accent : null,
        border: selected
            ? null
            : Border.all(color: c.inkTertiary, width: SongletSize.ring),
      ),
      child: selected
          ? Icon(
              Icons.check_rounded,
              size: size * _checkScale,
              color: c.onAccent,
            )
          : null,
    );
  }
}
