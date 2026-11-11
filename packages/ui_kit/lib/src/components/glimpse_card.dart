import 'dart:async';

import 'package:flutter/material.dart';

import '../motion.dart';
import '../skeleton.dart';
import '../tokens/songlet_colors.dart';
import '../tokens/songlet_elevation.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_motion.dart';
import '../tokens/songlet_type.dart';

/// "A glimpse of your song" (docs/ui P05): lyric lines in pages of four with
/// page dots, auto-advancing; shimmer lines until the first lines arrive.
class GlimpseCard extends StatefulWidget {
  const GlimpseCard({
    super.key,
    required this.title,
    required this.lines,
    this.linesPerPage = defaultLinesPerPage,
  });

  final String title;
  final List<String> lines;
  final int linesPerPage;

  /// Lyric lines per page (docs/ui P05: pages of four).
  static const int defaultLinesPerPage = 4;

  @override
  State<GlimpseCard> createState() => _GlimpseCardState();
}

class _GlimpseCardState extends State<GlimpseCard> {
  /// Shimmer line widths (× cover size), alternating long / short.
  static const double _skeletonLong = 0.8;
  static const double _skeletonShort = 0.6;

  final _pages = PageController();
  Timer? _timer;
  int _page = 0;

  List<List<String>> get _chunks => [
    for (var i = 0; i < widget.lines.length; i += widget.linesPerPage)
      widget.lines.sublist(
        i,
        (i + widget.linesPerPage).clamp(0, widget.lines.length),
      ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  @override
  void didUpdateWidget(GlimpseCard old) {
    super.didUpdateWidget(old);
    if (old.lines.length != widget.lines.length) _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (MotionPolicy.reduceMotion(context) || _chunks.length < 2) return;
    _timer = Timer.periodic(SongletMotion.carousel, (_) {
      if (!mounted || !_pages.hasClients) return;
      final next = (_page + 1) % _chunks.length;
      _pages.animateToPage(
        next,
        duration: SongletMotion.emphasized,
        curve: SongletMotion.standardCurve,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final e = SongletElevation.of(context);
    final chunks = _chunks;
    // One page holds [linesPerPage] lines at the current Dynamic Type size,
    // measured as laid out (line metrics round, so they are not computed).
    final probe = TextPainter(
      text: TextSpan(
        text: widget.title,
        style: DefaultTextStyle.of(context).style.merge(SongletType.body),
      ),
      maxLines: 1,
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
    )..layout();
    final lineHeight = probe.height + SongletSpace.x2;
    probe.dispose();
    final bodyHeight = lineHeight * widget.linesPerPage;
    return Container(
      padding: const EdgeInsetsDirectional.all(SongletSpace.x5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: SongletRadius.cardAll,
        boxShadow: e.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.music_note_outlined,
                color: c.inkSecondary,
                size: SongletSize.iconMd,
              ),
              const SizedBox(width: SongletSpace.x2),
              Flexible(
                child: Text(
                  widget.title,
                  style: SongletType.subhead.copyWith(color: c.inkSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: SongletSpace.x3),
          SizedBox(
            height: bodyHeight,
            child: chunks.isEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < widget.linesPerPage; i++)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            bottom: SongletSpace.x3,
                          ),
                          child: AuraSkeleton(
                            width:
                                SongletSize.coverLarge *
                                (i.isEven ? _skeletonLong : _skeletonShort),
                            height: SongletType.body.fontSize!,
                          ),
                        ),
                    ],
                  )
                : Semantics(
                    liveRegion: true,
                    child: PageView(
                      controller: _pages,
                      onPageChanged: (p) => setState(() => _page = p),
                      children: [
                        for (final chunk in chunks)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < chunk.length; i++)
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    bottom: SongletSpace.x2,
                                  ),
                                  child: Text(
                                    chunk[i],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: SongletType.body.copyWith(
                                      color: i == 0 ? c.ink : c.inkSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
          if (chunks.length > 1) ...[
            const SizedBox(height: SongletSpace.x3),
            Center(
              child: PageDots(count: chunks.length, index: _page),
            ),
          ],
        ],
      ),
    );
  }
}

/// Carousel position dots.
class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            Container(
              margin: const EdgeInsetsDirectional.symmetric(
                horizontal: SongletSpace.x1,
              ),
              width: SongletSpace.x2,
              height: SongletSpace.x2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == index ? c.accent : c.hairline,
              ),
            ),
        ],
      ),
    );
  }
}
