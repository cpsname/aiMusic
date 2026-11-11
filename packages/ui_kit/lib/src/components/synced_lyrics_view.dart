import 'package:flutter/material.dart';

import '../motion.dart';
import '../tokens/songlet_colors.dart';
import '../tokens/songlet_elevation.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_motion.dart';
import '../tokens/songlet_type.dart';

/// One lyric line; [time] is shown when set ("0:12", docs/ui P07).
typedef LyricLineView = ({String text, String? time, bool breakBefore});

/// Lyrics that follow playback (docs/ui P07/P09): the active line in the
/// accent colour, kept in view inside its own scroll; tap a line to seek.
class SyncedLyricsView extends StatefulWidget {
  const SyncedLyricsView({
    super.key,
    required this.lines,
    required this.active,
    this.onTapLine,
    this.maxHeight = SongletSize.coverLarge,
  });

  final List<LyricLineView> lines;

  /// Index of the line being sung; -1 = none yet.
  final int active;
  final ValueChanged<int>? onTapLine;
  final double maxHeight;

  @override
  State<SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends State<SyncedLyricsView> {
  final _scroll = ScrollController();
  final _keys = <int, GlobalKey>{};

  /// Where the active line settles in the viewport (0 top … 1 bottom).
  static const double _activeAlignment = 0.3;

  @override
  void didUpdateWidget(SyncedLyricsView old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active && widget.active >= 0) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _reveal(widget.active),
      );
    }
  }

  /// Scrolls only this view's own list (never the page around it).
  void _reveal(int index) {
    final target = _keys[index]?.currentContext?.findRenderObject();
    if (target == null || !mounted || !_scroll.hasClients) return;
    _scroll.position.ensureVisible(
      target,
      alignment: _activeAlignment,
      duration: MotionPolicy.reduceMotion(context)
          ? SongletMotion.none
          : SongletMotion.emphasized,
      curve: SongletMotion.standardCurve,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final e = SongletElevation.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: SongletRadius.cardAll,
        boxShadow: e.level1,
      ),
      child: ClipRRect(
        borderRadius: SongletRadius.cardAll,
        child: Scrollbar(
          controller: _scroll,
          child: ListView.builder(
            controller: _scroll,
            shrinkWrap: true,
            padding: const EdgeInsetsDirectional.all(SongletSpace.x5),
            itemCount: widget.lines.length,
            itemBuilder: (context, i) {
              final line = widget.lines[i];
              final active = i == widget.active;
              final style = SongletType.body.copyWith(
                color: active
                    ? c.accent
                    : (i < widget.active ? c.ink : c.inkSecondary),
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              );
              return Padding(
                key: _keys.putIfAbsent(i, GlobalKey.new),
                padding: EdgeInsetsDirectional.only(
                  top: line.breakBefore && i > 0 ? SongletSpace.x4 : 0,
                  bottom: SongletSpace.x2,
                ),
                child: Semantics(
                  selected: active,
                  button: widget.onTapLine != null,
                  child: InkWell(
                    onTap: widget.onTapLine == null
                        ? null
                        : () => widget.onTapLine!(i),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(child: Text(line.text, style: style)),
                        if (line.time != null)
                          Text(
                            line.time!,
                            style: SongletType.footnote.copyWith(
                              color: active ? c.accent : c.inkSecondary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
