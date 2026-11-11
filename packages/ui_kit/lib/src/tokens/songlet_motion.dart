import 'package:flutter/animation.dart';

/// Motion tokens: durations and curves. Components honour
/// `MotionPolicy.reduceMotion` by collapsing durations to [none].
abstract final class SongletMotion {
  static const Duration none = Duration.zero;
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);

  /// A component switching between its states (the composer's free input,
  /// picked card and options — ADR-0033).
  static const Duration state = Duration(milliseconds: 200);
  static const Duration emphasized = Duration(milliseconds: 350);
  static const Duration page = Duration(milliseconds: 300);
  static const Duration pulse = Duration(milliseconds: 1600);
  static const Duration carousel = Duration(seconds: 4);

  static const Curve standardCurve = Curves.easeInOutCubic;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasizedCurve = Cubic(0.2, 0, 0, 1);
}
