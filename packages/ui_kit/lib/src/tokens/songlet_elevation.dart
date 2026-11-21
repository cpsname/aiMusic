import 'package:flutter/material.dart';

/// Shadow levels. The press does not float: plates sit on the paper with a
/// keyline and, at most, the faintest ambient lift. Depth is carried by rules
/// and surface tone, not by glow — so the three levels differ mainly in how
/// far a floating thing (composer, popover, sheet) is allowed to lift.
@immutable
class SongletElevation extends ThemeExtension<SongletElevation> {
  const SongletElevation({
    required this.level1,
    required this.level2,
    required this.level3,
  });

  /// Daylight press: warm keyline, almost no blur.
  static const SongletElevation light = SongletElevation(
    level1: [
      BoxShadow(color: Color(0x0F3A2418), blurRadius: 1, offset: Offset(0, 1)),
    ],
    level2: [
      BoxShadow(color: Color(0x143A2418), blurRadius: 8, offset: Offset(0, 4)),
    ],
    level3: [
      BoxShadow(color: Color(0x1F3A2418), blurRadius: 18, offset: Offset(0, 10)),
    ],
  );

  /// Night press: the same keyline, read as a drop into the dark.
  static const SongletElevation dark = SongletElevation(
    level1: [
      BoxShadow(color: Color(0x1F000000), blurRadius: 1, offset: Offset(0, 1)),
    ],
    level2: [
      BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 4)),
    ],
    level3: [
      BoxShadow(color: Color(0x4D000000), blurRadius: 18, offset: Offset(0, 10)),
    ],
  );

  /// Plates resting on the paper.
  final List<BoxShadow> level1;

  /// The pinned composer, sticky bars.
  final List<BoxShadow> level2;

  /// Popovers, anchored panels, sheets.
  final List<BoxShadow> level3;

  static SongletElevation of(BuildContext context) =>
      Theme.of(context).extension<SongletElevation>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  SongletElevation copyWith({
    List<BoxShadow>? level1,
    List<BoxShadow>? level2,
    List<BoxShadow>? level3,
  }) => SongletElevation(
    level1: level1 ?? this.level1,
    level2: level2 ?? this.level2,
    level3: level3 ?? this.level3,
  );

  @override
  SongletElevation lerp(covariant SongletElevation? other, double t) {
    if (other == null) return this;
    return SongletElevation(
      level1: BoxShadow.lerpList(level1, other.level1, t)!,
      level2: BoxShadow.lerpList(level2, other.level2, t)!,
      level3: BoxShadow.lerpList(level3, other.level3, t)!,
    );
  }
}
