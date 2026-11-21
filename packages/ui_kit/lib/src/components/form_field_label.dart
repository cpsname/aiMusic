import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';

/// A form section: a tracked label, optional trailing counter, the field, and
/// helper or error text below (docs/ui P03, P18).
///
/// The label is set like a printed form's field name — small, wide-tracked,
/// quiet — so the writing space, not the label, carries the weight.
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                label,
                style: SongletType.eyebrow.copyWith(
                  color: error != null ? c.danger : c.inkSecondary,
                  fontSize: 10.5,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: SongletType.folio.copyWith(
                  color: c.inkTertiary,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        child,
        if (note != null) ...[
          const SizedBox(height: 6),
          Semantics(
            liveRegion: error != null,
            child: Text(
              note,
              style: SongletType.footnote.copyWith(
                color: error != null ? c.danger : c.inkSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
