import 'dart:async';

import 'package:flutter/material.dart';

import '../motion.dart';
import '../skeleton.dart';
import '../tokens/songlet_colors.dart';
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
    final chunks = _chunks;
    // One page holds [linesPerPage] lines at the current Dynamic Type size,
    // measured as laid out (line metrics round, so they are not computed).
    final probe = TextPainter(
      text: TextSpan(
        text: widget.title,
        style: DefaultTextStyle.of(context).style.merge(SongletType.lede),
      ),
      maxLines: 1,
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
    )..layout();
    final lineHeight = probe.height + SongletSpace.x2;
    probe.dispose();
    final bodyHeight = lineHeight * widget.linesPerPage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: SongletType.eyebrow.copyWith(
                  color: c.inkTertiary,
                  fontSize: 10.5,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            if (chunks.length > 1)
              Text(
                '${_page + 1}/${chunks.length}',
                style: SongletType.folio.copyWith(color: c.inkTertiary),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(height: SongletSize.rule, color: c.hairline),
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
                          height: SongletType.lede.fontSize!,
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
                                  style: SongletType.lede.copyWith(
                                    color: i == 0 ? c.ink : c.inkSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// Carousel position marks: struck squares, the current one coral.
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
                horizontal: 3,
              ),
              width: SongletSpace.x1 + 2,
              height: SongletSpace.x1 / 2,
              color: i == index ? c.accent : c.hairline,
            ),
        ],
      ),
    );
  }
}
