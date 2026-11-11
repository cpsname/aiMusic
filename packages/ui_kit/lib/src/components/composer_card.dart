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
/// Given a bounded height, the head and the primary action stay put and the
/// part between them scrolls; unbounded (inside an outer scroll view), it is
/// laid out in full. Switching [body] (give each state its own key), showing
/// or hiding [head] and [options] animate over [SongletMotion.state].
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
        summary,
        resize(
          options == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsetsDirectional.only(
                    top: SongletSpace.x2,
                  ),
                  child: options,
                ),
        ),
      ],
    );
    const radius = BorderRadius.all(Radius.circular(SongletRadius.sheet));
    // A Material surface, so the list tiles and ink inside paint on it. The
    // composer is the page's hero surface: a raised glass panel with an
    // aurora halo, distinct from the ordinary content cards.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: e.level2,
        border: Border.all(color: c.hairline),
      ),
      child: Material(
        color: c.surfaceRaised,
        borderRadius: radius,
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
                const SizedBox(height: SongletSpace.x3),
                primaryAction,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The composer's summary row ("Preview · Vocals on · Indie Pop ›",
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
                horizontal: SongletSpace.x2,
                vertical: SongletSpace.x1,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      MetaLine.join(parts),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SongletType.subhead.copyWith(
                        color: c.inkSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: SongletSpace.x1),
                  AnimatedSwitcher(
                    duration: duration,
                    child: Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.chevron_right_rounded,
                      key: ValueKey(expanded),
                      size: SongletSize.iconMd,
                      color: c.inkSecondary,
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

/// The prompt text field of the composer.
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
      style: SongletType.callout.copyWith(color: c.ink),
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        counterText: '',
        constraints: const BoxConstraints(
          minHeight: SongletSize.promptMinHeight,
        ),
        prefixIcon: leading == null
            ? null
            : Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: SongletSpace.x1,
                ),
                child: leading,
              ),
        suffixIcon: trailing == null
            ? null
            : Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: SongletSpace.x1,
                ),
                child: trailing,
              ),
      ),
    );
  }
}

/// Round tonal control of the composer ("+", mic / stop).
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
    final (fill, ink) = switch (emphasis) {
      ComposerButtonEmphasis.neutral => (c.surfaceMuted, c.ink),
      ComposerButtonEmphasis.tinted => (c.accentSoft, c.accent),
      ComposerButtonEmphasis.solid => (c.accent, c.onAccent),
    };
    return Tooltip(
      message: tooltip,
      child: Semantics(
        container: true,
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          color: fill,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: SongletSize.minTap,
              child: Icon(icon, color: ink, size: SongletSize.iconLg),
            ),
          ),
        ),
      ),
    );
  }
}

enum ComposerButtonEmphasis { neutral, tinted, solid }
