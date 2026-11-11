import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';

/// In-place error with one fixing action (docs/ui P18: "We can't make this
/// one — try different words, and skip artist names." + Rewrite).
class InlineErrorBanner extends StatelessWidget {
  const InlineErrorBanner({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.error_rounded,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(
          SongletSpace.x4,
          SongletSpace.x3,
          SongletSpace.x3,
          SongletSpace.x3,
        ),
        decoration: BoxDecoration(
          color: c.dangerSoft,
          borderRadius: SongletRadius.controlAll,
        ),
        child: Row(
          children: [
            Icon(icon, color: c.danger, size: SongletSize.iconLg),
            const SizedBox(width: SongletSpace.x3),
            Expanded(
              child: Text(
                message,
                style: SongletType.subhead.copyWith(
                  color: c.danger,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: SongletSpace.x3),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: c.onAccent,
                  minimumSize: const Size(
                    SongletSize.minTap * 2,
                    SongletSize.minTap,
                  ),
                  shape: const StadiumBorder(),
                  textStyle: themedTextStyle(
                    context,
                    SongletType.subhead.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
