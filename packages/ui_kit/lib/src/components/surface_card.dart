import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_elevation.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';

/// The standard content card: surface fill, card radius, level-1 shadow.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsetsDirectional.all(SongletSpace.x5),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final e = SongletElevation.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: SongletRadius.cardAll,
        boxShadow: e.level1,
        border: Border.all(color: c.hairline),
      ),
      child: Material(
        color: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: SongletRadius.cardAll,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Section title with an optional trailing caption or link ("See all ›",
/// "Included with your plan") — docs/ui P11, P12.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTrailing,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: SongletType.title2.copyWith(color: c.ink),
            ),
          ),
        ),
        if (trailing != null)
          onTrailing == null
              ? Text(
                  trailing!,
                  style: SongletType.footnote.copyWith(color: c.inkSecondary),
                )
              : TextButton(
                  onPressed: onTrailing,
                  style: TextButton.styleFrom(foregroundColor: c.inkSecondary),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        trailing!,
                        style: SongletType.subhead.copyWith(
                          color: c.inkSecondary,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: SongletSize.iconMd,
                      ),
                    ],
                  ),
                ),
      ],
    );
  }
}

/// Accent-outlined secondary action (P07 "Share preview", P13 "Delete").
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final color = destructive ? c.danger : c.accent;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size.fromHeight(SongletSize.controlHeight),
        side: BorderSide(color: color, width: SongletSize.ring),
        shape: const StadiumBorder(),
        textStyle: themedTextStyle(context, SongletType.headline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: SongletSize.iconLg),
            const SizedBox(width: SongletSpace.x2),
          ],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          if (trailingIcon != null) ...[
            const SizedBox(width: SongletSpace.x2),
            Icon(trailingIcon, size: SongletSize.iconLg),
          ],
        ],
      ),
    );
  }
}

/// Informational note with an optional trailing link (P11 license note,
/// SynthID note).
class NoteBanner extends StatelessWidget {
  const NoteBanner({
    super.key,
    required this.icon,
    required this.message,
    this.linkLabel,
    this.onLink,
  });

  final IconData icon;
  final String message;
  final String? linkLabel;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.all(SongletSpace.x4),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: SongletRadius.controlAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c.inkSecondary, size: SongletSize.iconLg),
          const SizedBox(width: SongletSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: SongletType.footnote.copyWith(color: c.inkSecondary),
                ),
                if (linkLabel != null && onLink != null)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: onLink,
                      style: TextButton.styleFrom(foregroundColor: c.accent),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            linkLabel!,
                            style: SongletType.footnote.copyWith(
                              color: c.accent,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: SongletSize.iconSm,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state: glyph, title, message and one action (library, lists).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Minimum width of the action button.
  static const double _actionMinWidth = SongletSize.minTap * 4;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.all(SongletSpace.x8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: SongletSize.playButton + SongletSpace.x4,
            height: SongletSize.playButton + SongletSpace.x4,
            decoration: BoxDecoration(
              color: c.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: SongletSize.iconXl, color: c.accent),
          ),
          const SizedBox(height: SongletSpace.x4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: SongletType.title3.copyWith(color: c.ink),
          ),
          const SizedBox(height: SongletSpace.x2),
          Text(
            message,
            textAlign: TextAlign.center,
            style: SongletType.subhead.copyWith(color: c.inkSecondary),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: SongletSpace.x5),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.onAccent,
                minimumSize: const Size(
                  _actionMinWidth,
                  SongletSize.controlHeight,
                ),
                shape: const StadiumBorder(),
                textStyle: themedTextStyle(context, SongletType.headline),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
