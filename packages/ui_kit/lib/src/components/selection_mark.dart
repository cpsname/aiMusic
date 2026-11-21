import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';

/// Selection indicator: a struck square, filled with the coral plate and a
/// cream check when chosen, an empty ruled square otherwise (docs/ui P02,
/// P02a–c). A form filled in with a pen, not a radio button.
class SelectionMark extends StatelessWidget {
  const SelectionMark({
    super.key,
    required this.selected,
    this.size = SongletSize.iconMd,
  });

  final bool selected;
  final double size;

  /// Check glyph size (× mark size).
  static const double _checkScale = 0.78;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? c.accent : Colors.transparent,
        border: Border.all(
          color: selected ? c.accent : c.inkTertiary,
          width: SongletSize.rule,
        ),
        borderRadius: BorderRadius.circular(2),
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
