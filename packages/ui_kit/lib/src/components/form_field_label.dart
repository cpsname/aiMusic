import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';

/// A form section: label, optional trailing counter, the field, and helper
/// or error text below (docs/ui P03, P18).
class FormFieldSection extends StatelessWidget {
  const FormFieldSection({
    super.key,
    required this.label,
    required this.child,
    this.trailing,
    this.helper,
    this.error,
  });

  final String label;
  final Widget child;
  final String? trailing;
  final String? helper;

  /// Replaces [helper] in the danger colour (P18 "Artist names can't be used.").
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final note = error ?? helper;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: SongletType.callout.copyWith(color: c.ink),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: SongletType.footnote.copyWith(color: c.inkSecondary),
              ),
          ],
        ),
        const SizedBox(height: SongletSpace.x2),
        child,
        if (note != null) ...[
          const SizedBox(height: SongletSpace.x1),
          Semantics(
            liveRegion: error != null,
            child: Text(
              note,
              style: SongletType.footnote.copyWith(
                color: error != null ? c.danger : c.inkSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
