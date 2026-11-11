import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/songlet_colors.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_type.dart';

/// Up to [maxCount] short keywords as removable chips plus an inline field to
/// add one (docs/ui P03 "Three words about them"). Enter or a comma commits;
/// the last one closes the keyboard.
class KeywordChipInput extends StatefulWidget {
  const KeywordChipInput({
    super.key,
    required this.values,
    required this.onChanged,
    required this.addHint,
    required this.removeLabel,
    required this.maxCount,
    required this.maxLength,
    this.error = false,
  });

  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final String addHint;

  /// Accessibility label of a chip's ✕, given the keyword.
  final String Function(String keyword) removeLabel;
  final int maxCount;
  final int maxLength;
  final bool error;

  @override
  State<KeywordChipInput> createState() => _KeywordChipInputState();
}

class _KeywordChipInputState extends State<KeywordChipInput> {
  /// Width range of the inline keyword field.
  static const double _fieldMinWidth = SongletSize.minTap * 3;
  static const double _fieldMaxWidth = SongletSize.minTap * 4;

  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit(String raw) {
    final word = raw.replaceAll(',', ' ').trim();
    _controller.clear();
    if (word.isEmpty || widget.values.length >= widget.maxCount) return;
    if (widget.values.any((v) => v.toLowerCase() == word.toLowerCase())) return;
    final filled = widget.values.length + 1 >= widget.maxCount;
    // The last word closes the keyboard (the field goes away with it); any
    // other keeps typing in place.
    if (filled) {
      _focus.unfocus();
    } else {
      _focus.requestFocus();
    }
    widget.onChanged([...widget.values, word]);
  }

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final full = widget.values.length >= widget.maxCount;
    return Wrap(
      spacing: SongletSpace.x2,
      runSpacing: SongletSpace.x2,
      children: [
        for (final word in widget.values)
          _KeywordChip(
            label: word,
            removeLabel: widget.removeLabel(word),
            onRemove: () => widget.onChanged([...widget.values]..remove(word)),
          ),
        if (!full)
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: _fieldMinWidth,
              maxWidth: _fieldMaxWidth,
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              maxLength: widget.maxLength,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp('[\n\r]')),
              ],
              onChanged: (v) {
                if (v.contains(',')) _commit(v);
              },
              onSubmitted: _commit,
              onTapOutside: (_) {
                if (_controller.text.trim().isNotEmpty) {
                  _commit(_controller.text);
                }
              },
              style: SongletType.callout.copyWith(color: c.ink),
              decoration: InputDecoration(
                hintText: widget.addHint,
                counterText: '',
                isDense: true,
                prefixIcon: Icon(
                  Icons.add_rounded,
                  size: SongletSize.iconMd,
                  color: c.accent,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: SongletSize.iconXl,
                ),
                contentPadding: const EdgeInsetsDirectional.symmetric(
                  horizontal: SongletSpace.x3,
                  vertical: SongletSpace.x3,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: SongletRadius.pillAll,
                  borderSide: BorderSide(
                    color: widget.error ? c.danger : c.hairline,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: SongletRadius.pillAll,
                  borderSide: BorderSide(
                    color: c.accent,
                    width: SongletSize.focusRing,
                  ),
                ),
                filled: false,
              ),
            ),
          ),
      ],
    );
  }
}

class _KeywordChip extends StatelessWidget {
  const _KeywordChip({
    required this.label,
    required this.removeLabel,
    required this.onRemove,
  });

  final String label;
  final String removeLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: SongletSize.minTap),
      padding: const EdgeInsetsDirectional.only(
        start: SongletSpace.x4,
        end: SongletSpace.x1,
      ),
      decoration: BoxDecoration(
        color: c.accentSoft,
        borderRadius: SongletRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: SongletType.callout.copyWith(color: c.ink)),
          IconButton(
            tooltip: removeLabel,
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.close_rounded,
              size: SongletSize.iconMd,
              color: c.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
