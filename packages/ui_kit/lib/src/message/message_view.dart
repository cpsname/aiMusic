import 'package:flutter/material.dart';

import '../glass_card.dart';
import '../motion.dart';
import '../tokens.dart';
import 'message_spec.dart';

/// One message card: a glass surface with a variant leading (icon or spinner),
/// the text, an optional action, and a dismiss affordance (except while loading).
/// RTL-safe (EdgeInsetsDirectional) and reduce-motion-safe (static loading glyph).
class MessageView extends StatelessWidget {
  const MessageView({super.key, required this.spec, required this.onDismiss});

  final MessageSpec spec;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color(spec.variant);
    final dismissible = spec.variant != MessageVariant.loading;

    return GlassCard(
      padding: const EdgeInsetsDirectional.fromSTEB(
        StudioTokens.spaceMd,
        StudioTokens.spaceMd,
        StudioTokens.spaceSm,
        StudioTokens.spaceMd,
      ),
      child: Row(
        children: [
          _Leading(variant: spec.variant, color: color),
          const SizedBox(width: StudioTokens.spaceMd),
          Expanded(
            child: Text(
              spec.text,
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (spec.hasAction) ...[
            const SizedBox(width: StudioTokens.spaceXs),
            TextButton(
              onPressed: spec.onAction,
              style: TextButton.styleFrom(foregroundColor: color),
              child: Text(spec.actionLabel!),
            ),
          ],
          if (dismissible)
            IconButton(
              onPressed: onDismiss,
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              color: theme.hintColor,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }

  static Color _color(MessageVariant v) => switch (v) {
    MessageVariant.loading => StudioTokens.infoColor,
    MessageVariant.success => StudioTokens.successColor,
    MessageVariant.error => StudioTokens.errorColor,
    MessageVariant.warning => StudioTokens.warningColor,
    MessageVariant.info => StudioTokens.infoColor,
  };
}

class _Leading extends StatelessWidget {
  const _Leading({required this.variant, required this.color});

  final MessageVariant variant;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (variant == MessageVariant.loading) {
      // Reduce-motion (DF⑥): no perpetual spinner — show a static glyph instead.
      if (MotionPolicy.reduceMotion(context)) {
        return Icon(Icons.hourglass_top_rounded, color: color, size: 22);
      }
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }
    return Icon(_icon(variant), color: color, size: 22);
  }

  static IconData _icon(MessageVariant v) => switch (v) {
    MessageVariant.success => Icons.check_circle_rounded,
    MessageVariant.error => Icons.error_rounded,
    MessageVariant.warning => Icons.warning_amber_rounded,
    MessageVariant.info => Icons.info_rounded,
    MessageVariant.loading => Icons.hourglass_top_rounded,
  };
}
