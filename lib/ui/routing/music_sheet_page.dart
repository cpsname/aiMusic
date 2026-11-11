import 'package:flutter/material.dart';

/// A go_router page presented as a modal bottom sheet (the P02 region sheet),
/// so sheets are routes and deep links like any page (ADR-0003).
class MusicSheetPage<T> extends Page<T> {
  const MusicSheetPage({
    required this.child,
    this.heightFactor = defaultHeightFactor,
    super.key,
    super.name,
  });

  /// Default [heightFactor]: nearly full height, the page peeking above.
  static const double defaultHeightFactor = 0.92;

  final Widget child;

  /// Share of the screen height the sheet takes.
  final double heightFactor;

  @override
  Route<T> createRoute(BuildContext context) => ModalBottomSheetRoute<T>(
    settings: this,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) =>
        FractionallySizedBox(heightFactor: heightFactor, child: child),
  );
}
