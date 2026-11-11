import 'package:flutter/material.dart';

import '../motion.dart';
import '../tokens.dart';
import 'message_controller.dart';
import 'message_view.dart';

/// Roots the message stack above the whole app. Mount once via
/// `MaterialApp(builder: (ctx, child) => MessageHost(controller: ..., child: child))`
/// so messages float over any screen (gates, sheets, dialogs) and survive route
/// changes — unlike a Scaffold-bound SnackBar.
///
/// Pure presentation: it only listens to [controller]. RTL-safe + reduce-motion
/// aware (entrance fade/rise is skipped when motion is reduced).
class MessageHost extends StatelessWidget {
  const MessageHost({
    super.key,
    required this.controller,
    required this.child,
    this.alignment = AlignmentDirectional.bottomCenter,
    this.maxWidth = 560,
  });

  final MessageController controller;
  final Widget child;
  final AlignmentDirectional alignment;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: SafeArea(
            minimum: const EdgeInsets.all(StudioTokens.spaceMd),
            child: Align(
              alignment: alignment,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    final entries = controller.entries;
                    final reduce = MotionPolicy.reduceMotion(context);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final e in entries)
                          Padding(
                            key: ValueKey<int>(e.id),
                            padding: const EdgeInsetsDirectional.only(
                              top: StudioTokens.spaceSm,
                            ),
                            child: TweenAnimationBuilder<double>(
                              key: ValueKey<int>(e.id),
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: reduce
                                  ? Duration.zero
                                  : StudioTokens.durationFast,
                              curve: Curves.easeOut,
                              builder: (context, t, view) => Opacity(
                                opacity: t,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - t) * 8),
                                  child: view,
                                ),
                              ),
                              child: MessageView(
                                spec: e.spec,
                                onDismiss: () => controller.dismissEntry(e),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
