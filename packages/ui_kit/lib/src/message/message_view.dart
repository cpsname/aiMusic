import 'package:flutter/material.dart';

import '../motion.dart';
import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';
import 'message_spec.dart';

/// One message: a notice slip struck in from the margin — paper fill, a rule
/// on the leading edge tinted by the variant, the text, an optional action and
/// a dismiss key (except while loading).
/// RTL-safe (EdgeInsetsDirectional) and reduce-motion-safe (static loading glyph).
class MessageView extends StatelessWidget {
  const MessageView({super.key, required this.spec, required this.onDismiss});

  final MessageSpec spec;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final color = _color(c, spec.variant);
    final dismissible = spec.variant != MessageVariant.loading;

    return ClipRRect(
      borderRadius: SongletRadius.cardAll,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: SongletRadius.cardAll,
          border: Border.all(color: c.hairline),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // The variant's rule on the leading edge, printed inside the slip.
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: 3,
                child: ColoredBox(color: color),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  SongletSpace.x3,
                  SongletSpace.x2,
                  SongletSpace.x1,
                  SongletSpace.x2,
                ),
                child: Row(
                  children: [
                    _Leading(variant: spec.variant, color: color),
                    const SizedBox(width: SongletSpace.x2),
                    Expanded(
                      child: Text(
                        spec.text,
                        style: SongletType.subhead.copyWith(
                          color: c.ink,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (spec.hasAction) ...[
                      const SizedBox(width: SongletSpace.x2),
                      Flexible(
                        child: InkWell(
                          onTap: spec.onAction,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: SongletSpace.x1,
                              vertical: SongletSpace.x1,
                            ),
                            child: Text(
                              spec.actionLabel!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SongletType.subhead.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (dismissible)
                      IconButton(
                        onPressed: onDismiss,
                        iconSize: SongletSize.iconSm,
                        visualDensity: VisualDensity.compact,
                        color: c.inkTertiary,
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _color(SongletColors c, MessageVariant v) => switch (v) {
    MessageVariant.loading => c.inkSecondary,
    MessageVariant.success => c.success,
    MessageVariant.error => c.danger,
    MessageVariant.warning => c.warning,
    MessageVariant.info => c.accent,
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
        return Icon(
          Icons.hourglass_top_rounded,
          color: color,
          size: SongletSize.iconSm,
        );
      }
      return SizedBox(
        width: SongletSize.iconSm,
        height: SongletSize.iconSm,
        child: CircularProgressIndicator(
          strokeWidth: SongletSize.focusRing,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }
    return Icon(_icon(variant), color: color, size: SongletSize.iconSm);
  }

  static IconData _icon(MessageVariant v) => switch (v) {
    MessageVariant.success => Icons.check_rounded,
    MessageVariant.error => Icons.error_outline_rounded,
    MessageVariant.warning => Icons.warning_amber_rounded,
    MessageVariant.info => Icons.info_outline_rounded,
    MessageVariant.loading => Icons.hourglass_top_rounded,
  };
}
