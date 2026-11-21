import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';

/// Icon · label · value row (docs/ui P13 "Prompt used"), ruled rather than
/// boxed.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Label column width (aligns values across rows).
  static const double labelWidth = SongletSize.minTap * 2.2;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          vertical: SongletSpace.x2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 2),
              child: Icon(icon, color: c.inkTertiary, size: SongletSize.iconSm),
            ),
            const SizedBox(width: SongletSpace.x3),
            SizedBox(
              width: labelWidth,
              child: Text(
                label,
                style: SongletType.eyebrow.copyWith(
                  color: c.inkSecondary,
                  fontSize: 10.5,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: SongletType.subhead.copyWith(
                  color: c.ink,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Label, dotted leader, value — the way a menu or a receipt sets a price.
///
///     Full song .......................... 1
class LeaderRow extends StatelessWidget {
  const LeaderRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasised = false,
  });

  final String label;
  final String value;

  /// Sets both sides in ink at weight (the total line).
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final labelStyle = (emphasised ? SongletType.headline : SongletType.subhead)
        .copyWith(color: c.ink);
    final valueStyle =
        (emphasised ? SongletType.headline : SongletType.folio).copyWith(
          color: c.ink,
        );
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(child: Text(label, style: labelStyle)),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: SongletSpace.x2,
                  vertical: 5,
                ),
                child: CustomPaint(
                  painter: DottedLeaderPainter(color: c.inkTertiary),
                  child: const SizedBox(height: 1, width: double.infinity),
                ),
              ),
            ),
            Text(value, style: valueStyle),
          ],
        ),
      ),
    );
  }
}

/// The dotted leader of a [LeaderRow].
class DottedLeaderPainter extends CustomPainter {
  const DottedLeaderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (var x = 0.0; x < size.width; x += 4) {
      canvas.drawLine(Offset(x, 0), Offset(x + 1, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant DottedLeaderPainter old) =>
      old.color != color;
}

/// A monospaced value with a copy button (P13 "Generation ID").
class CopyField extends StatelessWidget {
  const CopyField({
    super.key,
    required this.label,
    required this.value,
    required this.copyLabel,
    required this.onCopy,
  });

  final String label;
  final String value;
  final String copyLabel;
  final VoidCallback onCopy;

  /// Letter spacing of the id value, so it reads character by character.
  static const double _valueTracking = 1.2;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: SongletType.eyebrow.copyWith(
            color: c.inkSecondary,
            fontSize: 10.5,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: SongletSpace.x3,
                  vertical: SongletSpace.x2,
                ),
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: SongletRadius.controlAll,
                  border: Border.all(color: c.hairline),
                ),
                child: SelectableText(
                  value,
                  maxLines: 1,
                  style: SongletType.subhead.copyWith(
                    color: c.inkSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: _valueTracking,
                  ),
                ),
              ),
            ),
            const SizedBox(width: SongletSpace.x2),
            IconButton(
              tooltip: copyLabel,
              onPressed: onCopy,
              style: IconButton.styleFrom(
                foregroundColor: c.ink,
                side: BorderSide(color: c.hairline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SongletRadius.control),
                ),
              ),
              icon: const Icon(Icons.copy_rounded, size: SongletSize.iconMd),
            ),
          ],
        ),
      ],
    );
  }
}

/// A section of the settings page (P14): a tracked heading over a ruled block.
/// No card: the rules do the grouping.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.children,
    this.title,
    this.index,
  });

  final String? title;
  final List<Widget> children;

  /// Printed folio of the section ("01").
  final String? index;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              bottom: SongletSpace.x1,
            ),
            child: Semantics(
              header: true,
              child: Row(
                children: [
                  if (index != null) ...[
                    Text(
                      index!,
                      style: SongletType.folio.copyWith(
                        color: c.accent,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: SongletSpace.x2),
                  ],
                  Expanded(
                    child: Text(
                      title!,
                      style: SongletType.eyebrow.copyWith(
                        color: c.inkTertiary,
                        fontSize: 10.5,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: c.hairline),
              bottom: BorderSide(color: c.hairline),
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: SongletSize.rule,
                    thickness: SongletSize.rule,
                    color: c.hairline,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One settings row: a quiet glyph, the title, an optional subtitle, and a
/// trailing value, switch or chevron.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.toggle,
    this.onToggle,
    this.destructive = false,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;

  /// Shows a switch when non-null.
  final bool? toggle;
  final ValueChanged<bool>? onToggle;
  final bool destructive;

  /// An action at the end of the row (e.g. a copy button), in place of the
  /// chevron; ignored when the row has a [toggle].
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final ink = destructive ? c.danger : c.ink;
    final hasToggle = toggle != null;
    final stackValue =
        SongletType.isAccessibilitySize(context) || subtitle != null;
    return MergeSemantics(
      child: InkWell(
        onTap: hasToggle
            ? (onToggle == null ? null : () => onToggle!(!toggle!))
            : onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: SongletSize.controlHeight + SongletSpace.x2,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: SongletSpace.x2,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: destructive ? c.danger : c.inkSecondary,
                  size: SongletSize.iconMd,
                ),
                const SizedBox(width: SongletSpace.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: SongletType.body.copyWith(color: ink)),
                      if (value != null && stackValue)
                        Text(
                          value!,
                          style: SongletType.subhead.copyWith(
                            color: c.inkSecondary,
                          ),
                        ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(top: 1),
                          child: Text(
                            subtitle!,
                            style: SongletType.footnote.copyWith(
                              color: c.inkSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (value != null && !stackValue)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: SongletSpace.x2,
                      ),
                      child: Text(
                        value!,
                        textAlign: TextAlign.end,
                        style: SongletType.folio.copyWith(
                          color: c.inkSecondary,
                        ),
                      ),
                    ),
                  ),
                if (hasToggle)
                  Switch(value: toggle!, onChanged: onToggle)
                else if (trailing != null)
                  trailing!
                else if (onTap != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 4),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: SongletSize.iconSm,
                      color: c.inkTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
