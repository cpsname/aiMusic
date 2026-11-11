import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';

/// Icon · label · value row (docs/ui P13 "Prompt used").
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
  static const double labelWidth = SongletSize.minTap * 3;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          vertical: SongletSpace.x1,
        ),
        child: Row(
          children: [
            Container(
              width: SongletSize.iconXl + SongletSpace.x2,
              height: SongletSize.iconXl + SongletSpace.x2,
              decoration: BoxDecoration(
                color: c.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: c.accent, size: SongletSize.iconMd),
            ),
            const SizedBox(width: SongletSpace.x4),
            SizedBox(
              width: labelWidth,
              child: Text(
                label,
                style: SongletType.subhead.copyWith(color: c.inkSecondary),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: SongletType.callout.copyWith(color: c.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    return Row(
      children: [
        Text(label, style: SongletType.headline.copyWith(color: c.ink)),
        const SizedBox(width: SongletSpace.x4),
        Expanded(
          child: Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: SongletSpace.x3,
              vertical: SongletSpace.x2,
            ),
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              borderRadius: SongletRadius.thumbAll,
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
          style: IconButton.styleFrom(backgroundColor: c.surfaceMuted),
          icon: Icon(
            Icons.copy_rounded,
            color: c.ink,
            size: SongletSize.iconMd,
          ),
        ),
      ],
    );
  }
}

/// A grouped list (P14 settings): rounded surface with hairline dividers.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children, this.title});

  final String? title;
  final List<Widget> children;

  /// Divider inset, aligning dividers with the rows' text past the icon.
  static const double _dividerIndent = SongletSpace.x4 * 3;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: SongletSpace.x4,
              bottom: SongletSpace.x2,
            ),
            child: Semantics(
              header: true,
              child: Text(
                title!,
                style: SongletType.footnote.copyWith(color: c.inkSecondary),
              ),
            ),
          ),
        Material(
          color: c.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: SongletRadius.cardAll,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: SongletSize.hairline,
                    indent: _dividerIndent,
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

/// One settings row: leading glyph, title, optional subtitle, and a trailing
/// value, switch or chevron.
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
    final stackValue = SongletType.isAccessibilitySize(context) || subtitle != null;
    return MergeSemantics(
      child: InkWell(
        onTap: hasToggle
            ? (onToggle == null ? null : () => onToggle!(!toggle!))
            : onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: SongletSize.controlHeight,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: SongletSpace.x4,
              vertical: SongletSpace.x2,
            ),
            child: Row(
              children: [
                Container(
                  width: SongletSize.iconXl,
                  height: SongletSize.iconXl,
                  decoration: BoxDecoration(
                    color: destructive ? c.dangerSoft : c.accentSoft,
                    borderRadius: SongletRadius.thumbAll,
                  ),
                  child: Icon(
                    icon,
                    color: destructive ? c.danger : c.accent,
                    size: SongletSize.iconMd,
                  ),
                ),
                const SizedBox(width: SongletSpace.x4),
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
                        Text(
                          subtitle!,
                          style: SongletType.footnote.copyWith(
                            color: c.inkSecondary,
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
                        style: SongletType.subhead.copyWith(
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
                  Icon(Icons.chevron_right_rounded, color: c.inkTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
