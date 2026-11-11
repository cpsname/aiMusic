import 'package:flutter/widgets.dart';

/// Tags [child] with a stable id for automation: a [ValueKey] for widget tests
/// and a semantics `identifier` (iOS `accessibilityIdentifier`) for the
/// XCUITest acceptance run on the simulator.
class MusicTestId extends StatelessWidget {
  const MusicTestId(this.id, {super.key, required this.child});

  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    identifier: id,
    container: true,
    child: KeyedSubtree(key: ValueKey(id), child: child),
  );
}
