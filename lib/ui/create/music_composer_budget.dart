import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// How much of the stacked (phone) create home the composer may take, and
/// what gives way (ADR-0034):
/// * folded (A / B) at most [foldedShare] of the screen, unfolded (C, or
///   dictating) at most [openShare] — and never so much that less than one
///   row of the grid shows;
/// * with the keyboard up the brand header steps aside ([showsHeader]); free
///   input still keeps a row of the grid, a picked card or the options let
///   the grid fold away (the picked card stays named in the composer's head),
///   and the composer then has the room.
///
/// Pure arithmetic over logical pixels, so the rule is unit-tested on every
/// device of the matrix without building a widget.
@immutable
class MusicComposerBudget {
  const MusicComposerBudget({required this.maxHeight, required this.gridCollapsed});

  /// [screenHeight] is the device's logical height (the shares' base);
  /// [roomHeight] the room under the brand header for the grid and the
  /// composer (the shell's body, above the tab bar or the keyboard, less the
  /// composer's own padding); [gridMinExtent] the grid's heading plus one row.
  factory MusicComposerBudget.resolve({
    required double screenHeight,
    required double roomHeight,
    required double gridMinExtent,
    required bool picked,
    required bool unfolded,
    required bool keyboard,
  }) {
    final room = math.max(0.0, roomHeight);
    if (keyboard && (picked || unfolded)) {
      return MusicComposerBudget(maxHeight: room, gridCollapsed: true);
    }
    final share = unfolded ? openShare : foldedShare;
    return MusicComposerBudget(
      maxHeight: math.max(
        0,
        math.min(screenHeight * share, room - gridMinExtent),
      ),
      gridCollapsed: false,
    );
  }

  /// The brand header shows unless the keyboard is up (it steps aside first).
  static bool showsHeader({required bool keyboard}) => !keyboard;

  /// The folded composer's share of the screen height.
  static const double foldedShare = 0.35;

  /// The unfolded composer's share (the options, or dictation) of the screen
  /// height.
  static const double openShare = 0.55;

  /// Tallest the composer card, primary action included, may be; past it its
  /// fields scroll.
  final double maxHeight;

  /// Whether the grid folds away (keyboard up with a pick or unfolded).
  final bool gridCollapsed;

  @override
  bool operator ==(Object other) =>
      other is MusicComposerBudget &&
      other.maxHeight == maxHeight &&
      other.gridCollapsed == gridCollapsed;

  @override
  int get hashCode => Object.hash(maxHeight, gridCollapsed);

  @override
  String toString() =>
      'MusicComposerBudget(max: $maxHeight, gridCollapsed: $gridCollapsed)';
}
