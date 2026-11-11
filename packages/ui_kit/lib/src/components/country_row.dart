import 'package:flutter/material.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';
import 'selection_mark.dart';

/// A country in the region sheet (docs/ui P02): flag, name, and a check when
/// selected, else a chevron.
class CountryRow extends StatelessWidget {
  const CountryRow({
    super.key,
    required this.flag,
    required this.name,
    required this.selected,
    required this.onTap,
    this.showDivider = true,
  });

  final String flag;
  final String name;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: SongletSpace.x4),
          child: Row(
            children: [
              SizedBox(
                width: SongletSize.iconXl,
                child: Text(
                  flag,
                  style: SongletType.title2.copyWith(
                    fontFamilyFallback: const [SongletType.emojiFamily],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: SongletSpace.x4),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: SongletSize.controlHeight,
                  ),
                  padding: const EdgeInsetsDirectional.only(
                    end: SongletSpace.x4,
                  ),
                  decoration: BoxDecoration(
                    border: showDivider
                        ? Border(bottom: BorderSide(color: c.hairline))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: SongletType.body.copyWith(color: c.ink),
                        ),
                      ),
                      if (selected)
                        const SelectionMark(selected: true)
                      else
                        Icon(Icons.chevron_right_rounded, color: c.inkTertiary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
