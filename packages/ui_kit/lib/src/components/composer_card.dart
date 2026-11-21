import 'package:flutter/material.dart';

import '../motion.dart';
import '../tokens/songlet_colors.dart';
import '../tokens/songlet_elevation.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_motion.dart';
import '../tokens/songlet_type.dart';
import 'meta_line.dart';

/// The create home's composer (docs/ui P01, ADR-0033): an optional [head]
/// (the picked card), the [body] (the prompt field, the voice panel or the
/// card's fields), the [summary] row, the unfolded [options], and the one
/// [primaryAction] under them. Pure layout: every control is passed in, so
/// the app owns state and copy.
///
/// Printed as a ruled index card: the head sits above a rule, the writing
/// space under it, the specification line between two more rules, and the one
/// action at the foot. Given a bounded height, the head and the primary action
/// stay put and the part between them scrolls; unbounded (inside an outer
/// scroll view), it is laid out in full. Switching [body] (give each state its
/// own key), showing or hiding [head] and [options] animate over
/// [SongletMotion.state].
class ComposerCard extends StatelessWidget {
  const ComposerCard({
    super.key,
    required this.body,
    required this.summary,
    required this.primaryAction,
    this.head,
    this.options,
  });

  /// The picked card (see `ComposerTag`); null for free input.
  final Widget? head;

  /// The prompt field, the voice panel (P03a) or the picked card's fields.
  final Widget body;

  /// The current length · vocals · genre (see [ComposerSummary]).
  final Widget summary;

  /// The selectors, own lyrics and the video switch; null = folded.
  final Widget? options;

  /// The composer's only way to start a song.
  final Widget primaryAction;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final e = SongletElevation.of(context);
    final reduce = MotionPolicy.reduceMotion(context);
    final duration = reduce ? SongletMotion.none : SongletMotion.state;
    // Reduce motion: no size animation (a zero-length one re-dirties its own
    // layout).
    Widget resize(Widget child) => reduce
        ? child
        : AnimatedSize(
            duration: duration,
            curve: SongletMotion.emphasizedCurve,
            alignment: AlignmentDirectional.topCenter,
            child: child,
          );
    Widget swap(Widget child) => AnimatedSwitcher(
      duration: duration,
      switchInCurve: SongletMotion.enter,
      switchOutCurve: SongletMotion.exit,
      layoutBuilder: (current, previous) =>
          Stack(children: [...previous, ?current]),
      child: child,
    );
    final options = this.options;
    final head = this.head;
    final fields = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        resize(swap(body)),
        const SizedBox(height: SongletSpace.x2),
        _RuleLine(color: c.hairline),
        summary,
        resize(
          options == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsetsDirectional.only(
                    top: SongletSpace.x1,
                  ),
                  child: options,
                ),
        ),
      ],
    );
    const radius = BorderRadius.all(Radius.circular(SongletRadius.card));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: e.level2,
      ),
      child: Material(
        color: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: radius,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: c.ink, width: SongletSize.rule),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(SongletSpace.x3),
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  resize(
                    head == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsetsDirectional.only(
                              bottom: SongletSpace.x2,
                            ),
                            child: head,
                          ),
                  ),
                  if (constraints.hasBoundedHeight)
                    Flexible(child: SingleChildScrollView(child: fields))
                  else
                    fields,
                  // The ticket's perforation: the one action tears off here.
                  const Padding(
                    padding: EdgeInsetsDirectional.symmetric(
                      vertical: SongletSpace.x2,
                    ),
                    child: Perforation(),
                  ),
                  primaryAction,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A dashed rule between the composer's body and its one action — the
/// perforation of a ticket stub.
class Perforation extends StatelessWidget {
  const Perforation({super.key, this.dash = 4, this.gap = 4});

  final double dash;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = (constraints.maxWidth / (dash + gap)).floor();
          if (count <= 0) return const SizedBox.shrink();
          final width =
              (constraints.maxWidth - (count - 1) * gap) / count;
          return Row(
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) SizedBox(width: gap),
                Container(width: width, height: 1, color: c.hairline),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: SongletSize.rule,
    color: color,
  );
}

/// The composer's specification line ("Preview · Vocals on · Indie Pop ›",
/// ADR-0033): what will be made, and the way to the options. Tapping it
/// unfolds or folds them.
class ComposerSummary extends StatelessWidget {
  const ComposerSummary({
    super.key,
    required this.parts,
    required this.expanded,
    required this.onTap,
    required this.semanticLabel,
    this.semanticHint,
  });

  /// The values, joined with the metadata dot ([MetaLine.join]).
  final List<String> parts;

  /// The options show.
  final bool expanded;
  final VoidCallback onTap;

  /// "Song options: Preview, Vocals on, Indie Pop".
  final String semanticLabel;

  /// What a tap does ("Show song options").
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final duration = MotionPolicy.reduceMotion(context)
        ? SongletMotion.none
        : SongletMotion.state;
    return Semantics(
      container: true,
      button: true,
      expanded: expanded,
      label: semanticLabel,
      hint: semanticHint,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: SongletRadius.controlAll,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: SongletSize.minTap),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: SongletSpace.x1,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      MetaLine.join(parts),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SongletType.eyebrow.copyWith(
                        color: c.inkSecondary,
                        fontSize: 10,
                        letterSpacing: 0.9,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(width: SongletSpace.x1),
                  AnimatedSwitcher(
                    duration: duration,
                    child: Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      key: ValueKey(expanded),
                      size: SongletSize.iconMd,
                      color: c.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The writing space of the composer: borderless, set in the reading serif, so
/// the page reads as a note being written rather than a form being filled.
class ComposerPromptField extends StatelessWidget {
  const ComposerPromptField({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.errorText,
    this.leading,
    this.trailing,
  });

  final TextEditingController controller;

  /// Inline control at the start of the field ("+" photos).
  final Widget? leading;

  /// Inline control at the end of the field (the mic).
  final Widget? trailing;
  final String hint;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final String? errorText;

  /// Most lines the prompt grows to before it scrolls.
  static const int promptMaxLines = 4;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      minLines: 1,
      maxLines: promptMaxLines,
      maxLength: maxLength,
      textInputAction: TextInputAction.done,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: SongletType.lede.copyWith(color: c.ink, height: 1.35),
      decoration: InputDecoration(
        filled: false,
        isDense: true,
        hintText: hint,
        errorText: errorText,
        counterText: '',
        contentPadding: const EdgeInsetsDirectional.symmetric(
          vertical: SongletSpace.x2,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        hintStyle: SongletType.lede.copyWith(
          color: c.inkTertiary,
          height: 1.35,
        ),
        errorStyle: SongletType.footnote.copyWith(color: c.danger),
        constraints: const BoxConstraints(
          minHeight: SongletSize.promptMinHeight,
        ),
        prefixIcon: leading == null
            ? null
            : Padding(
                padding: const EdgeInsetsDirectional.only(
                  end: SongletSpace.x2,
                ),
                child: leading,
              ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: SongletSize.minTap,
          minHeight: SongletSize.minTap,
        ),
        suffixIcon: trailing == null
            ? null
            : Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: SongletSpace.x2,
                ),
                child: trailing,
              ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: SongletSize.minTap,
          minHeight: SongletSize.minTap,
        ),
      ),
    );
  }
}

/// Ruled key of the composer ("+", mic / stop) — the control is a small
/// square, consistent with the page's other keys.
class ComposerRoundButton extends StatelessWidget {
  const ComposerRoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.emphasis = ComposerButtonEmphasis.neutral,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final ComposerButtonEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final (fill, ink, stroke) = switch (emphasis) {
      ComposerButtonEmphasis.neutral => (Colors.transparent, c.ink, c.hairline),
      ComposerButtonEmphasis.tinted => (c.accentSoft, c.accent, c.accentSoft),
      ComposerButtonEmphasis.solid => (c.accent, c.onAccent, c.accent),
    };
    final radius = BorderRadius.circular(SongletRadius.control);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        container: true,
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          color: fill,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: stroke),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: SizedBox.square(
              dimension: SongletSize.minTap,
              child: Icon(icon, color: ink, size: SongletSize.iconMd),
            ),
          ),
        ),
      ),
    );
  }
}

enum ComposerButtonEmphasis { neutral, tinted, solid }
