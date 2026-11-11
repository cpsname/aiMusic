import 'package:flutter/material.dart';

import 'glass_card.dart';
import 'obs_button.dart';
import 'tokens.dart';

/// A centered, glass status panel for a terminal state that occupies a content
/// region — load failures, empty results, blocking notices. It replaces the
/// per-screen bespoke "card + retry button" error views with one reusable
/// primitive.
///
/// Pure presentation: every string is injected already-localized (ui_kit has no
/// l10n dependency). Supply [actionLabel] + [onAction] to offer a primary action
/// (e.g. retry); set [loading] while that action is in flight — the button shows
/// a spinner and disables. [expand] true stretches the card/button to the full
/// available width (full-screen use); false sizes them to their content
/// (page-level / inline use). The panel always centers itself within the space
/// it is given.
///
/// RTL-safe and reduce-motion-safe by construction (no directional offsets, no
/// perpetual animation of its own).
class StatusView extends StatelessWidget {
  const StatusView({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.accentColor,
    this.loading = false,
    this.expand = true,
    this.padding = const EdgeInsets.all(StudioTokens.spaceXl),
  });

  /// Primary headline. Required — a status always names what happened.
  final String title;

  /// Optional supporting line below the title.
  final String? message;

  /// Optional leading glyph, tinted with [accentColor].
  final IconData? icon;

  /// Action button label. When null/empty, no button is rendered.
  final String? actionLabel;

  /// Invoked when the action is tapped. Null (with a label) renders a disabled
  /// button — use together with [loading].
  final VoidCallback? onAction;

  /// Icon tint. Defaults to [StudioTokens.errorColor].
  final Color? accentColor;

  /// Shows a spinner in the action button and disables it.
  final bool loading;

  /// Stretch the card + button to full width (true) or size to content (false).
  final bool expand;

  /// Outer margin around the card.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? StudioTokens.errorColor;
    final hasAction = actionLabel != null && actionLabel!.isNotEmpty;

    final card = GlassCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // Default crossAxisAlignment.center: a full-width action button (expand)
        // forces the column wide; the other children stay centered either way.
        children: [
          if (icon != null) ...[
            Icon(icon, color: accent, size: 40),
            const SizedBox(height: StudioTokens.spaceMd),
          ],
          Text(
            title,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: StudioTokens.spaceSm),
            Text(
              message!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          if (hasAction) ...[
            const SizedBox(height: StudioTokens.spaceLg),
            ObsButton(
              label: actionLabel!,
              onPressed: onAction,
              loading: loading,
              expand: expand,
            ),
          ],
        ],
      ),
    );

    return Center(
      child: Padding(padding: padding, child: card),
    );
  }
}
