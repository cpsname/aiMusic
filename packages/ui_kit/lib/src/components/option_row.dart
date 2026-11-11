import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';
import 'selection_mark.dart';

/// One choice in a panel or list (docs/ui P02a–c): leading icon, title with
/// an optional inline [hint] ("Short — 30-second preview, free"), optional
/// [subtitle] below, a [badge] and the selection mark.
class OptionRow extends StatelessWidget {
  const OptionRow({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.icon,
    this.leading,
    this.hint,
    this.subtitle,
    this.badge,
    this.dense = false,
    this.emphasizeIcon = false,
  });

  final String title;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  /// Replaces [icon] (a flag, an equalizer glyph).
  final Widget? leading;
  final String? hint;
  final String? subtitle;
  final Widget? badge;
  final bool dense;

  /// Accent-coloured icon (the "Popular in" primary genre, P02c).
  final bool emphasizeIcon;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final titleStyle = SongletType.callout.copyWith(color: c.ink);
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: SongletRadius.controlAll,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: dense ? SongletSize.minTap : SongletSize.controlHeight,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: SongletSpace.x2,
            ),
            child: Row(
              children: [
                if (leading != null || icon != null) ...[
                  SizedBox(
                    width: SongletSize.iconXl,
                    child:
                        leading ??
                        Icon(
                          icon,
                          size: SongletSize.iconLg,
                          color: emphasizeIcon ? c.accent : c.inkSecondary,
                        ),
                  ),
                  const SizedBox(width: SongletSpace.x3),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: title,
                              style: titleStyle.copyWith(
                                fontWeight: hint == null && subtitle == null
                                    ? FontWeight.w400
                                    : FontWeight.w600,
                              ),
                            ),
                            if (hint != null)
                              TextSpan(
                                text: ' — $hint',
                                style: titleStyle.copyWith(
                                  color: c.inkSecondary,
                                ),
                              ),
                          ],
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
                if (badge != null) ...[
                  badge!,
                  const SizedBox(width: SongletSpace.x2),
                ],
                const SizedBox(width: SongletSpace.x2),
                SelectionMark(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small caption heading a group of rows ("Popular in United States").
class PanelSectionHeader extends StatelessWidget {
  const PanelSectionHeader({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final text = Padding(
      padding: const EdgeInsetsDirectional.only(
        top: SongletSpace.x3,
        bottom: SongletSpace.x1,
      ),
      child: Text(
        label,
        style: SongletType.subhead.copyWith(color: c.inkSecondary),
      ),
    );
    return Semantics(
      header: true,
      button: onTap != null,
      child: onTap == null ? text : InkWell(onTap: onTap, child: text),
    );
  }
}
