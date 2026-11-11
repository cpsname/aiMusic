import 'package:flutter/material.dart';

/// Shadow levels. Light mode uses warm, soft shadows; dark mode relies on
/// surface tone and keeps only a faint ambient shadow.
@immutable
class SongletElevation extends ThemeExtension<SongletElevation> {
  const SongletElevation({
    required this.level1,
    required this.level2,
    required this.level3,
  });

  static const SongletElevation light = SongletElevation(
    level1: [
      BoxShadow(color: Color(0x180C1740), blurRadius: 12, offset: Offset(0, 4)),
      BoxShadow(color: Color(0x147C5CFF), blurRadius: 18),
    ],
    level2: [
      BoxShadow(
        color: Color(0x260C1740),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
      BoxShadow(color: Color(0x1C2FB6FF), blurRadius: 28),
    ],
    level3: [
      BoxShadow(
        color: Color(0x330C1740),
        blurRadius: 40,
        offset: Offset(0, 18),
      ),
      BoxShadow(color: Color(0x227C5CFF), blurRadius: 36),
    ],
  );

  static const SongletElevation dark = SongletElevation(
    level1: [
      BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 5)),
      BoxShadow(color: Color(0x267C5CFF), blurRadius: 20),
    ],
    level2: [
      BoxShadow(
        color: Color(0x99000000),
        blurRadius: 28,
        offset: Offset(0, 12),
      ),
      BoxShadow(color: Color(0x332FB6FF), blurRadius: 32),
    ],
    level3: [
      BoxShadow(
        color: Color(0xCC000000),
        blurRadius: 44,
        offset: Offset(0, 20),
      ),
      BoxShadow(color: Color(0x447C5CFF), blurRadius: 48),
    ],
  );

  /// Cards and tiles resting on the canvas.
  final List<BoxShadow> level1;

  /// Floating composer, sticky bars.
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
