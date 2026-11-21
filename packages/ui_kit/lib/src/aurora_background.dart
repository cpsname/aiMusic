import 'package:flutter/widgets.dart';

import 'paper_background.dart';

/// Retired backdrop: kept only so the template's older imports still build.
/// The product no longer projects an aurora — it is printed on [PaperBackground].
@Deprecated('Use PaperBackground: the press has no aurora.')
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) => PaperBackground(child: child);
}
