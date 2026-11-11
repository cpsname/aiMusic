import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../motion.dart';
import '../tokens/songlet_colors.dart';
import '../tokens/songlet_elevation.dart';
import '../tokens/songlet_metrics.dart';
import '../tokens/songlet_motion.dart';
import '../tokens/songlet_type.dart';

/// Opens a popover panel pointing at the widget of [anchorContext] (docs/ui
/// P02a–c): above the anchor when it fits, else below; clamped to the safe
/// area with the page gutter; a scrim covers the rest. Resolves with the
/// value passed to `Navigator.pop`.
Future<T?> showAnchoredPanel<T>({
  required BuildContext context,
  required BuildContext anchorContext,
  required WidgetBuilder builder,
  required String barrierLabel,
  double maxWidth = SongletSize.anchoredPanelWidth,
  double? maxHeight,
}) {
  final box = anchorContext.findRenderObject()! as RenderBox;
  final overlay =
      Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
  final anchor = Rect.fromPoints(
    box.localToGlobal(Offset.zero, ancestor: overlay),
    box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
  );
  return Navigator.of(context).push<T>(
    _AnchoredPanelRoute<T>(
      anchor: anchor,
      builder: builder,
      label: barrierLabel,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      scrim: SongletColors.of(context).scrim,
      reduceMotion: MotionPolicy.reduceMotion(context),
    ),
  );
}

class _AnchoredPanelRoute<T> extends PopupRoute<T> {
  _AnchoredPanelRoute({
    required this.anchor,
    required this.builder,
    required this.label,
    required this.maxWidth,
    required this.maxHeight,
    required this.scrim,
    required this.reduceMotion,
  });

  /// Scale the panel grows from as it fades in.
  static const double _enterScale = 0.96;

  final Rect anchor;
  final WidgetBuilder builder;
  final String label;
  final double maxWidth;
  final double? maxHeight;
  final Color scrim;
  final bool reduceMotion;

  @override
  Color? get barrierColor => scrim;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => label;

  @override
  Duration get transitionDuration =>
      reduceMotion ? SongletMotion.none : SongletMotion.standard;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondary,
  ) {
    final safe = MediaQuery.paddingOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final geometry = PanelGeometry.resolve(
          screen: constraints.biggest,
          anchor: anchor,
          safe: safe,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        );
        return CustomSingleChildLayout(
          delegate: _PanelPlacement(geometry: geometry, anchor: anchor),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: geometry.maxHeight),
            child: _PanelFrame(
              arrowX: geometry.arrowX,
              above: geometry.above,
              child: Builder(builder: builder),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: SongletMotion.enter,
      reverseCurve: SongletMotion.exit,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: _enterScale, end: 1).animate(curved),
        child: child,
      ),
    );
  }
}

/// Resolved placement of an anchored panel (pure; unit-tested).
@immutable
class PanelGeometry {
  const PanelGeometry({
    required this.left,
    required this.width,
    required this.above,
    required this.maxHeight,
    required this.arrowX,
  });

  /// Gap between the anchor and the arrow tip.
  static const double gap = SongletSpace.x1;

  /// Arrow height (and half its base).
  static const double arrow = SongletSpace.x2;

  final double left;
  final double width;

  /// Panel sits above the anchor (arrow down) — else below (arrow up).
  final bool above;

  final double maxHeight;

  /// Arrow tip x in panel coordinates.
  final double arrowX;

  static PanelGeometry resolve({
    required Size screen,
    required Rect anchor,
    required EdgeInsets safe,
    required double maxWidth,
    double? maxHeight,
  }) {
    final width = math.min(maxWidth, screen.width - 2 * SongletSpace.gutter);
    final left = (anchor.center.dx - width / 2)
        .clamp(
          SongletSpace.gutter,
          math.max(
            SongletSpace.gutter,
            screen.width - width - SongletSpace.gutter,
          ),
        )
        .toDouble();
    final roomAbove = anchor.top - safe.top - gap - arrow;
    final roomBelow = screen.height - anchor.bottom - safe.bottom - gap - arrow;
    final above = roomAbove >= roomBelow;
    final room = math.max(0.0, above ? roomAbove : roomBelow);
    return PanelGeometry(
      left: left,
      width: width,
      above: above,
      maxHeight: math.min(maxHeight ?? room, room),
      arrowX: (anchor.center.dx - left)
          .clamp(
            SongletRadius.card,
            math.max(SongletRadius.card, width - SongletRadius.card),
          )
          .toDouble(),
    );
  }
}

/// Places the panel at the resolved geometry once its height is known.
class _PanelPlacement extends SingleChildLayoutDelegate {
  _PanelPlacement({required this.geometry, required this.anchor});

  final PanelGeometry geometry;
  final Rect anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        minWidth: geometry.width,
        maxWidth: geometry.width,
        maxHeight: geometry.maxHeight,
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) => Offset(
    geometry.left,
    geometry.above
        ? anchor.top -
              PanelGeometry.gap -
              PanelGeometry.arrow -
              childSize.height
        : anchor.bottom + PanelGeometry.gap + PanelGeometry.arrow,
  );

  @override
  bool shouldRelayout(_PanelPlacement old) =>
      old.geometry != geometry || old.anchor != anchor;
}

/// Panel surface with an arrow towards the anchor.
class _PanelFrame extends StatelessWidget {
  const _PanelFrame({
    required this.arrowX,
    required this.above,
    required this.child,
  });

  final double arrowX;
  final bool above;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    final e = SongletElevation.of(context);
    return CustomPaint(
      painter: _ArrowPainter(x: arrowX, above: above, color: c.surfaceRaised),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: SongletRadius.cardAll,
          boxShadow: e.level3,
        ),
        child: Material(
          color: c.surfaceRaised,
          shape: const RoundedRectangleBorder(
            borderRadius: SongletRadius.cardAll,
          ),
          clipBehavior: Clip.antiAlias,
          child: DefaultTextStyle.merge(
            style: SongletType.callout.copyWith(color: c.ink),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.x, required this.above, required this.color});

  final double x;
  final bool above;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const a = PanelGeometry.arrow;
    final base = above ? size.height : 0.0;
    final tip = above ? size.height + a : -a;
    final path = Path()
      ..moveTo(x - a, base)
      ..lineTo(x, tip)
      ..lineTo(x + a, base)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.x != x || old.above != above || old.color != color;
}

/// Standard panel content: a caption title, then [children] and the
/// [footer], scrollable when taller than the room the layout gives.
class AnchoredPanelBody extends StatelessWidget {
  const AnchoredPanelBody({
    super.key,
    required this.title,
    required this.children,
    this.footer,
    this.onClose,
    this.closeLabel,
  });

  final String title;
  final List<Widget> children;
  final Widget? footer;

  /// Shows a close button in the header (the P02c genre sheet).
  final VoidCallback? onClose;
  final String? closeLabel;

  @override
  Widget build(BuildContext context) {
    final c = SongletColors.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        SongletSpace.x4,
        SongletSpace.x3,
        SongletSpace.x4,
        SongletSpace.x3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: onClose == null
                        ? SongletType.subhead.copyWith(color: c.inkSecondary)
                        : SongletType.title3.copyWith(color: c.ink),
                  ),
                ),
              ),
              if (onClose != null)
                IconButton(
                  tooltip: closeLabel,
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(backgroundColor: c.surfaceMuted),
                ),
            ],
          ),
          // The footer scrolls with the rows: at the largest text sizes the
          // room beside the anchor may hold little more than the title.
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...children,
                  if (footer != null) ...[Divider(color: c.hairline), footer!],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
