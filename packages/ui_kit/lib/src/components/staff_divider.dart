import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';

/// A printed staff: five hairlines, the way a lead sheet opens a movement.
///
/// The app's own divider. A generic hairline separates; a staff *means* music —
/// it closes a section head, sits above the transport and opens the lyric
/// sheet. One graphic idea, used everywhere the page changes subject.
class StaffDivider extends StatelessWidget {
  const StaffDivider({
    super.key,
    this.lines = 5,
    this.gap = 2,
    this.color,
    this.accentFirst = false,
  });

  /// Rules in the staff (5 for a stave).
  final int lines;

  /// Space between two rules.
  final double gap;

  /// Rule colour; defaults to a quiet ink.
  final Color? color;

  /// Prints the first rule in the signal colour, like a rehearsal mark.
  final bool accentFirst;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final ink = color ?? c.ink.withValues(alpha: 0.24);
    return ExcludeSemantics(
      child: SizedBox(
        height: lines + (lines - 1) * gap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < lines; i++)
              Container(
                height: 1,
                color: accentFirst && i == 0 ? c.accent : ink,
              ),
          ],
        ),
      ),
    );
  }
}
