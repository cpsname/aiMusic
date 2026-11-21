import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_elevation.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';
import 'staff_divider.dart';

/// The standard content plate: paper fill, one hairline, nothing floating.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsetsDirectional.all(SongletSpace.x4),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: SongletRadius.cardAll,
        boxShadow: SongletElevation.of(context).level1,
      ),
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: SongletRadius.cardAll,
          side: BorderSide(color: c.hairline),
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

/// A printed section head: a mono folio, the title set black and tight, and a
/// staff running to the margin, with an optional mono link.
///
///    01  Inspirations ≣≣≣≣≣≣≣≣≣≣≣≣≣≣≣≣≣≣≣≣≣≣  SEE ALL
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTrailing,
    this.index,
    this.rule = true,
    this.bottom = SongletSpace.x3,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTrailing;

  /// Printed folio ("01", "02") ahead of the title.
  final String? index;

  /// Draws the staff that runs from the title to the margin.
  final bool rule;

  /// Space under the head.
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: bottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (index != null) ...[
            Text(
              index!,
              style: SongletType.folio.copyWith(
                color: c.accent,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: SongletSpace.x2),
          ],
          Flexible(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SongletType.title3.copyWith(
                  color: c.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          if (rule) ...[
            const SizedBox(width: SongletSpace.x3),
            const Expanded(child: StaffDivider()),
          ],
          if (trailing != null) ...[
            const SizedBox(width: SongletSpace.x3),
            onTrailing == null
                ? Text(
                    trailing!,
                    style: SongletType.eyebrow.copyWith(
                      color: c.inkSecondary,
                      fontSize: 10,
                    ),
                  )
                : TextButton(
                    onPressed: onTrailing,
                    style: TextButton.styleFrom(
                      foregroundColor: c.ink,
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: SongletSpace.x1,
                      ),
                      minimumSize: const Size(0, SongletSize.minTap * 0.7),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          trailing!,
                          style: SongletType.eyebrow.copyWith(
                            color: c.ink,
                            fontSize: 10,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: SongletSize.iconXs,
                          color: c.ink,
                        ),
                      ],
                    ),
                  ),
          ],
        ],
      ),
    );
  }
}

/// Secondary action: a ruled box, not a stadium (P07 "Share preview",
/// P13 "Delete").
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
    final color = destructive ? c.danger : c.ink;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size.fromHeight(SongletSize.controlHeight),
        side: BorderSide(color: destructive ? c.danger : c.ink, width: SongletSize.rule),
        shape: const RoundedRectangleBorder(
          borderRadius: SongletRadius.controlAll,
        ),
        textStyle: themedTextStyle(context, SongletType.headline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: SongletSize.iconMd),
            const SizedBox(width: SongletSpace.x2),
          ],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          if (trailingIcon != null) ...[
            const SizedBox(width: SongletSpace.x2),
            Icon(trailingIcon, size: SongletSize.iconMd),
          ],
        ],
      ),
    );
  }
}

/// A footnote set beside a rule — the licence note, the SynthID note. A note
/// is printed, not boxed.
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
    return DecoratedBox(
      decoration: BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(color: c.hairline, width: SongletSize.rule),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          SongletSpace.x3,
          SongletSpace.x1,
          0,
          SongletSpace.x1,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 1),
              child: Icon(icon, color: c.inkTertiary, size: SongletSize.iconSm),
            ),
            const SizedBox(width: SongletSpace.x2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: SongletType.footnote.copyWith(
                      color: c.inkSecondary,
                      height: 1.5,
                    ),
                  ),
                  if (linkLabel != null && onLink != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: 2),
                      child: InkWell(
                        onTap: onLink,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              linkLabel!,
                              style: SongletType.footnote.copyWith(
                                color: c.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: SongletSize.iconXs,
                              color: c.accent,
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
      ),
    );
  }
}

/// Empty state: a ruled frame, a serif line and one action (library, lists).
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
          Icon(icon, size: SongletSize.iconXl, color: c.accent),
          const SizedBox(height: SongletSpace.x4),
          Container(width: SongletSpace.x10, height: SongletSize.rule, color: c.hairline),
          const SizedBox(height: SongletSpace.x4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: SongletType.title2.copyWith(color: c.ink),
          ),
          const SizedBox(height: SongletSpace.x2),
          Text(
            message,
            textAlign: TextAlign.center,
            style: SongletType.subhead.copyWith(
              color: c.inkSecondary,
              height: 1.5,
            ),
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
                shape: const RoundedRectangleBorder(
                  borderRadius: SongletRadius.controlAll,
                ),
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
